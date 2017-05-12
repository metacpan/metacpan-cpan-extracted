#!/usr/bin/perl -w

use Data::Dumper;
use XML::Writer;

use constant GTK_HVER => 0x010208;
use constant GNOME_HVER => 0x010038;

# get parent information: find a better way for this
@Gtk::Gdk::Bitmap::ISA = qw(Gtk::Gdk::Pixmap);
@Gtk::Gdk::Window::ISA = qw(Gtk::Gdk::Pixmap);

eval {require blib; blib::import(qw(. ..)); };

foreach (qw(Gtk/Types Gtk/XmHTML/Types Gtk/HTML/Types Gnome/Types Gtk/GLArea/Types Gtk/GladeXML/Types)) {
	eval {require "$_.pm"};
	warn "No parent info for package $_\n" if ($@);
}

my ($package, $prefix, $lastl) = (undef, undef);
my (%funcs, $tag, $curfile);
my (%keywords, $mode, %current, %taboo);

@keywords{qw/ARG OUTPUT PROTO CONSTRUCTOR RETURNS DESC PARAMS SEEALSO EXAMPLE/} = ();
@taboo{qw/DESTROY constant/} = ();

%dataout = (
	'void'	=> undef,
	'SV*'	=> "scalar",
	'char*'	=> "string",
	'gstring'	=> "string",
	'gfloat'	=> "float",
	'gint'	=> 'integer',
	'guint32'	=> 'integer',
	'guint'	=> 'integer',
	'int'	=> 'integer',
	'unsigned int'	=> 'integer',
	'unsigned long'	=> 'integer',
	'long'	=> 'integer',
	'gulong'	=> 'integer',
	'bool'	=> 'boolean',
	'gboolean'	=> 'boolean',
);

$tag = 'gtk';

$use_pod = 0;

#eval {require XML::Writer};
#if ($@) {
#	$use_pod = 1;
#} else {
#	1;
#}
#$use_pod = 1;

# warn "GOT ARGS: @ARGV\n";

if (@ARGV && $ARGV[0] eq '-t') {
	shift;
	$tag = shift || 'gtk';
}

my @ifstack = ();

foreach (@ARGV) {
	$lastl = $package = $prefix = $mode = undef;
	%current = ();
	open (F, $_) || die "Cannot open $_: $!";
	$curfile = $_;
	while (<F>) {
		next if !defined($_);
		chomp;
		if (/^\s*$/) {
			$current{'PACKAGE'} = $package unless $current{'PACKAGE'};
			if ($current{'PROTO'}) {
				# print STDERR "STORING: $current{'PROTO'} in $current{'PACKAGE'}\n";
				$funcs{$current{'PACKAGE'}}->{$current{'PROTO'}} = {%current};
				if ($current{ALIASES}) {
					foreach (@{$current{ALIASES}}) {
						/([a-z:]+)::(\w+)/i && do {
							$current{'PACKAGE'} = $1;
							$current{'PROTO'} = $2;
							next if exists $funcs{$current{'PACKAGE'}}->{$current{'PROTO'}};
							$funcs{$current{'PACKAGE'}}->{$current{'PROTO'}} = {%current};
							#warn "created alias $current{'PACKAGE'} $current{'PROTO'}\n";
						};
					}
				}
			}
			%current = ();
			next;
		}
		if (/^\s*MODULE\s*=\s*(\S+)/) {
			$package = $1;
			$package = $1 if /PACKAGE\s*=\s*(\S+)/;
			$prefix = '';
			$prefix = $1 if /PREFIX\s*=\s*([_a-zA-Z][a-zA-Z0-9_]*)?\s*/;
			# warn "PACKAGE = $package\nPREFIX = $prefix\n";
			next;
		}
		next unless $package;
		# crude preprocessor handling
		if (/^#if(def)?\s+(.*)\s*(\/\*)?/) {
			my $test = $2;
			if ($test =~ /^[_a-zA-Z]\w*$/) {
				unshift (@ifstack, 1);
				#warn "$test value considered TRUE\n";
			} else {
				unshift (@ifstack, eval $test);
				warn "FAILED PP at $curfile $.: $1\n" if $@;
			}
		} elsif (/^#else/) {
			$ifstack[0] = ! $ifstack[0];
		} elsif (/^#endif/) {
			shift (@ifstack);
		}
		next if (@ifstack && !$ifstack[0]);
		if (/^\s+#\s*(\w+):\s*(.*)/) {
			handle_keyword($1, $2) if exists $keywords{$1};
			next;
		}
		if (/^\s+#\s*(.+)/) {
			handle_keyword($mode, $1) if $mode;
			next;
		}
		if (/^([a-zA-Z_][a-zA-Z0-9_]*)\s*\((.*)\)\s*$/) {
			$_ = handle_proto($1, $2);
			redo;
		}
	} continue {
		$lastl = $_;
	}
	close(F);
}

my %funcdesc;

$ext = 'pod';
$ext = 'xml' unless $use_pod;

open(DOC, ">build/perl-$tag-ref.$ext") || die "Cannot open doc: $!";
select DOC;
#print "\n=head1 NAME\n\nGtk/Perl Reference Manual\n\n";
if (!$use_pod) {
	print "<!DOCTYPE doc SYSTEM \"gpdoc.dtd\">";
	$writer = new XML::Writer(OUTPUT=>*DOC, NEWLINES=>1);
	$writer->startTag('doc');
}
foreach my $p (sort keys %funcs) {
	%funcdesc = %{$funcs{$p}};
	output_package($p);
	foreach (sort { $a cmp $b } keys %funcdesc) {
		output_func($p, $_);
		# print Dumper($funcdesc{$_});
	}
	#print "\n=back\n\n";
	close_package();
}
$writer->endTag('doc') unless $use_pod;
close(DOC);
exit(0);

sub handle_keyword {
	my ($k, $d) = @_;
	my $pack;
	
	# print STDERR "GOT KEYWORD: $k -> $d\n";
	$mode = $k;
	return unless $d;
	# ARG
	if ($k eq 'PROTO') {
		$current{'PACKAGE'} = $1 if $d =~ s/(.*)::(\w+)$/$2/;
		$current{$k} = $d;
	} elsif ($k eq 'ARG') {
		if ($d =~ /\s*(\$?[.a-zA-Z_][.a-zA-Z0-9_]*)\s+(.*?)\s+\((.*)\)\s*(\S+)?/) {
			my ($param, $type, $comment, $default) = ($1, $2, $3, $4);
			crunch_type($type);
			$default = '' unless defined $default;
			$current{'ARG'}->{$param} = [$type, $comment, $default];
			#print STDERR "GOT ARG: $type, $param, $comment, $default\n";
		} else {
			print STDERR "Wrong ARG construct at $curfile:$.: $d\n";
		}
	} else {
		$current{$k} .= "\n" if $current{$k};
		$current{$k} .= $d;
	}
}

sub handle_proto {
	my ($n, $args) = @_;
	my ($type, $param, $comment, $retval, %defaults);
	
	$n =~ s/^$prefix// if $prefix;
	return if exists $taboo{$n};
	return unless $package;

	while (($args =~ s/(\w+)\s*=([^ ,]+)/$1/)) {
		#print "default: $1 -> $2\n";
		$param = $1;
		$param = '$' . $param unless $param eq '...';
		$defaults{$param} = $2;
	}
	#$args =~ s/(\w+)\s*=([^ ,])+/push(@defaults, $1, $2),$1/ge;
	$args =~ s/([a-zA-Z_]\w*)/\$$1/g;
	# print STDERR "PROTO = ${package}::$n\n";
	$current{'PROTO'} = $n unless exists $current{'PROTO'};
	$current{CONSTRUCTOR} = 1 if $current{PROTO} =~ /^new|create/; # Guess
	$current{'OUTPUT'} = $lastl unless $current{'OUTPUT'};
	#return unless $args;
	$current{'PARAMS'} = $args unless exists $current{'PARAMS'};
	while(defined ($retval=<F>)) {
		last if $retval =~ /^\s*$/;
		last if $retval =~ /^\s*\w+:\s*$/;
		next unless $retval =~ /\s*(.*?)\s*([a-zA-Z_][a-zA-Z0-9_]*)\s*$/;
		$comment = '';
		$param = $2;
		$type = $1;
		$param = '$' . $param unless $param eq '...';
		if (exists $current{'ARG'}->{$param}) {
			# warn "ARG ALREADY $param: ", Dumper($current{'ARG'}->{$param});
			next;
		}
		$comment = 'may be undef' if $type =~ /OrNULL/;
		crunch_type($type);
		$current{'ARG'}->{$param} = [$type, $comment, exists $defaults{$param}?$defaults{$param}:''];
	}
	# handle aliases
	if (!exists($current{ALIASES}) && defined($retval) && $retval =~ /^\s*ALIAS:/) {
		while(defined ($retval=<F>)) {
			last if $retval =~ /^\s*$/;
			last if $retval =~ /^\s*\w+:\s*$/;
			if ($retval =~ /\s*([a-z:]+)::(\w+)\s*=/i) {
				$protopkg = $current{PACKAGE} || $package;
				next if ($current{PROTO} eq $2 && $protopkg eq $1);
				# warn "found ALIAS $2 in package $1 for $current{PROTO}\n";
				push @{$current{ALIASES}}, "${1}::$2";
			}
		}
	}
	return $retval;
}

sub crunch_type {
	$_[0] =~ s/\s+/ /o;
	$_[0] =~ s/\s+(?=\B)//g;
	$_[0] =~ s/(_Sink_Up|_Sink|_Up)$//o;
	$_[0] =~ s/_?OrNULL//;
	$_[0] = $dataout{$_[0]} if exists $dataout{$_[0]};
}

sub my_compare {

	return $a cmp $b;
}

sub output_package_xml {
	my ($p) = shift;
	my (@c, @parent, $ref);

	$ref = uc($p);
	$ref =~ s/:/-/g;
	$writer->startTag('package', name => $p, id => $ref);
	@parent = eval "\@${p}::ISA";
	if (@parent) {
		$p = shift @parent;
		$ref = uc($p);
		$ref =~ s/:/-/g;
		$writer->startTag('parent', name => $p, idref => $ref);
		$writer->endTag('parent');
	}
	# output description

	#print STDERR Dumper(\%funcdesc);
	# constructors
	#foreach (keys %funcdesc) {
	#	push (@c, $_) if exists $funcs{$p}->{$_}->{'CONSTRUCTOR'};
	#}
	#$writer->startTag('constructors');
	#foreach (@c) {
	#	$writer->startTag('name');
	#	$writer->characters($_);
	#	$writer->endTag('name');
	#}
	#$writer->endTag('constructors');

	#print "=over 4\n";
}

sub output_func_xml {
	my ($p, $n) =@_ ;
	my ($data) = $funcs{$p}->{$n};
	my ($args) = $data->{'PARAMS'} || '';
	my ($out) = $data->{'OUTPUT'} || '';
	my (@cons, $args_copy);

	return unless $data;
	return unless keys %$data;

	crunch_type($out);

	if ($data->{CONSTRUCTOR}) {
		@cons = qw(cons cons);
	}
	$args_copy = $args;
	$args_copy =~ s/^\$\w+\s*,?\s*//;
	$writer->startTag('method', name => $n, args => $args_copy, out => $out || '', @cons);
	if ($data->{RETURNS}) {
		$writer->startTag('returns');
		$writer->characters($data->{RETURNS});
		$writer->endTag('returns');
	}

	foreach (split(/[, ]/, $args)) {
		next unless $_;
		#next if /^Class/;
		#next if /\.\.\./;
		#s/\s*=.*$//;
		#s/(\w+)/\$$1/;
		($type, $name, $desc, $def) = ($data->{'ARG'}->{$_}[0], $_, $data->{'ARG'}->{$_}[1], $data->{'ARG'}->{$_}[2]);
		$type = 'list' if (!$type && $name eq '...');
		$def = '' unless defined $def;
		$name = $p if $name eq '$Class';
		$writer->startTag('arg', type => $type || 'scalar', name => $name, 
			desc => $desc ||'', $def ne ""?(def => $def):());
		$writer->endTag('arg');
		delete $data->{'ARG'}->{$_};
	}
	foreach (keys %{$data->{'ARG'}}) {
		warn "Not handled $_ in $p $n\n";
	}
	if ($data->{DESC}) {
		$writer->startTag('desc');
		$writer->characters($data->{DESC});
		$writer->endTag('desc');
	}
	if ($data->{SEEALSO}) {
		$writer->startTag('seealso');
		$writer->characters($data->{SEEALSO});
		$writer->endTag('seealso');
	}
	# auto example?
	#print "EXAMPLE: $data->{'EXAMPLE'}\n" if $data->{'EXAMPLE'};
	$writer->endTag('method');
}

sub output_package_pod {
	my ($p) = shift;
	my (@c);

	print "\n=head1 $p\n\n";
	# output description

	#print STDERR Dumper(\%funcdesc);
	# constructors
	foreach (keys %funcdesc) {
		push (@c, $_) if exists $funcs{$p}->{$_}->{'CONSTRUCTOR'};
	}
	print "B<Constructors:> ", join(', ', @c), "\n\n" if @c;

}

sub output_func_pod {
	my ($p, $n) =@_ ;
	my ($data) = $funcs{$p}->{$n};
	my ($args) = $data->{'PARAMS'} || '';
	my ($out) = $data->{'OUTPUT'} || '';

	return unless $data;
	return unless keys %$data;

	crunch_type($out);

	print "\n=head2 \n$n ($args)\n\n";

	print "=over 4\n\n";
	foreach (split(', ', $args)) {
		next if /^Class/;
		next if /\.\.\./;
		s/\s*=.*$//;
		print "=item * ";
		print "B<$data->{'ARG'}->{$_}[0]> " if $data->{'ARG'}->{$_}[0];
		print "$_ ";
		print "($data->{'ARG'}->{$_}[1])" if $data->{'ARG'}->{$_}[1];
		print "\n\n";
	}
	print "=back\n\n";
	print "B<Return type:> $out\n\n" if $out;
	print "$data->{'DESC'}\n\n" if $data->{'DESC'};
	print "\nB<Returns:>\n", $data->{'RETURNS'}, "\n" if $data->{'RETURNS'};
	print "\nB<See also:>\n", $data->{'SEEALSO'}, "\n" if $data->{'SEEALSO'};
	# auto example?
	#print "EXAMPLE: $data->{'EXAMPLE'}\n" if $data->{'EXAMPLE'};
}

sub output_package {
	if ($use_pod) {
		goto &output_package_pod;
	} else{
		goto &output_package_xml;
	}
}

sub close_package {
	$writer->endTag('package') unless $use_pod;
}

sub output_func {
	if ($use_pod) {
		goto &output_func_pod;
	} else{
		goto &output_func_xml;
	}
}

