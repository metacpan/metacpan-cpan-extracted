
package HTML::Transmorgify::Metatags;

use strict;
use warnings;
use HTML::Transmorgify qw(dangling eat_cr %variables $rbuf compile continue_compile capture_compile run $debug $modules queue_intercept rbuf boolean bomb $input_file $input_line $original_file allocate_result_type);
use Scalar::Util qw(reftype blessed);
use HTML::Entities;
use URI::Escape;
use List::Util;
use File::Slurp;
use Object::Dependency;
use Carp qw(confess);
require Exporter;

our @ISA = qw(HTML::Transmorgify Exporter);
our @metatags_result_array;
our @include_dirs = ('.');
our @EXPORT = ();
our @EXPORT_OK = qw(%transformations @include_dirs %allowed_functions);

my %tags;
my %shared_tags;
my $tag_package = { tag_package => __PACKAGE__ };

sub return_false { 0 };

sub add_tags
{
	my ($module, $tobj) = @_;
	$tobj->intercept_exclusive($tobj, __PACKAGE__, 100, %tags);
	$tobj->intercept_shared($tobj, __PACKAGE__, 100, %shared_tags);
	$tobj->intercept_pre_compile(\&setup_diversions);
}

$tags{"/define"} = \&dangling;
$tags{define} = \&define_tag;

sub define_tag
{
	my ($attr, $closed) = @_;
	my $static_name = $attr->static('name', 0);
	my $static_value = $attr->static('value', 1);
	my $raw_value = $attr->raw('value', 1);

	my $raw_late = $attr->boolean('eval', undef, 0, raw => 1);
	my $early_binding = ! defined($raw_late);  # XXX think about this -- other cases?

	print STDERR "### DEFINE $static_name\n" if $debug;

	if (defined $static_name) {
		bomb("illegal variable name for define") if $static_name =~ /^[\s_]/;
		if (defined $static_value) {
			# a common case, I expect
			push(@$HTML::Transmorgify::rbuf, sub { get_varset_func($static_name)->($static_value) });
			eat_cr;
			print STDERR "### DEFINE $static_name = '$static_value' DONE\n" if $debug;
			return undef;
		}
	}


	#
	# Definitions can be in-line like <define name value />
	# or they can be bracketed: <define name>value</define>.
	# If they're in-line, then there will be a $raw_value.
	#
	my $buf;
	if (defined $raw_value) {
		$buf = compile($modules, \$raw_value);
	} else {
		my $levels = 1;
		$buf = capture_compile("define", $attr, $tag_package,
			"/define"	=> \&return_false,
		);
	}
	do_trim($attr, $buf);

	eat_cr;

	rbuf (sub {
		print STDERR "# define macro $attr\n" if $debug;
		my $name = $static_name || $attr->get('name', 0);
		bomb("illegal variable name for define") if $name =~ /^ /;
		my $set = get_varset_func($name);

		if ((@$buf == 1 && ! ref($buf->[0])) || ! $attr->boolean('eval', undef, 0)) {
			#
			# early binding -- let's set the variable to a string since the 
			# the value is a simple string or we've been explicitly told
			# not to evaluate the string.
			#
			my $vals = $attr->vals;
			print STDERR "# attr $attr\n" if $debug;
			$attr->hide_position(0) if $attr->last_position(0);
			my $r;
			{
				printf STDERR "# local'izing variables{%s}\n", join(', ', keys %$vals) if $debug;
				local(@HTML::Transmorgify::variables{keys %$vals}) = values %$vals;
				local(@metatags_result_array) = ( '' );
				run($buf, \@metatags_result_array);
				$r = \@metatags_result_array;
			}
			if (@$r > 1) {
				#
				# Results can come in different "buckets".  Bucket 0, is the 
				# main text results.  Other buckets are used for things like,
				# HTTP headers, collecting javascript, etc.  Without knowing
				# what they're used for it's hard to know what to do with 
				# the extra results.  In any case, we're going to $set->() the
				# new value to a callback.  XXX figure out semantics for 
				# a macro expansion that adds to the HTTP header, etc.
				#
				$set->(sub {
					$HTML::Transmorgify::result->[$_] .= $r->[$_] for grep { defined $r->[$_] } 0..$#$r;
				});
				print STDERR "# now setting variable $name = '$r->[0] and other buckets'\n" if $debug;
			} else {
				$set->($r->[0]);
				print STDERR "# now setting variable $name = '$r->[0]'\n" if $debug;
			}
		} else {
			# late binding -- don't evaluate until the variable is expanded.
			# we prefer early binding because more can happen at compile time and
			# that will help performance if we can cache the results.
			$set->(sub {
				print STDERR "# evaluating variable '$name'...\n" if $debug;
				my $vals = $attr->vals;
				$attr->hide_position(0) if $attr->last_position(0);
				printf STDERR "# local'izing variables{%s}\n", join(', ', keys %$vals) if $debug;
				local(@HTML::Transmorgify::variables{keys %$vals}) = values %$vals;
				run($buf);
			});
		}
	});
	print STDERR "### DONE DEFINE $static_name\n" if $debug;
	return undef;
};

$tags{include} = \&include_tag;

sub include_tag
{
	my ($attr, $closed) = @_;
	warn unless $closed;
	eat_cr;
	my $v = $attr->vals;
	my @k = grep { $_ ne 'file' } keys %$v;

	rbuf (sub {
		print STDERR "# including file $attr\n" if $debug;
		# $attr->run;
		my $file = $attr->get('file', 0);
		my $ifile = find_file($file);
		local($HTML::Transmorgify::input_file) = $ifile;
		bomb("cannot find include file $file", attr => $attr) unless $ifile;
		local($HTML::Transmorgify::input_line) = 1;
		my $contents = read_file($ifile);
		local(@HTML::Transmorgify::variables{@k}) = map { $attr->get($_) } @k;
		my $buf = compile($HTML::Transmorgify::modules, \$contents);
		run($buf);
	});
	return undef;
};

#
# We're doing a little hack to grab control of the compile
# sequence so that we can wrap the diversions code around it
#

our @process_text;

sub setup_diversions
{
	push(@process_text, $HTML::Transmorgify::process_text_ref);
	$HTML::Transmorgify::process_text_ref = \"<enableDiversionsCodeRightNow />";
}

$tags{enableDiversionsCodeRightNow} = \&enable_diversions;
$tags{capture} = \&capture_tag;
$tags{playback} = \&playback_tag;

# because diversions can be nested, we have to 
# resolve them in dependency order.  We'll use
# an Object;:Dependency graph to store their names
# so that they be resolved in dependency order.

# At runtime, a playback tag cannot pull in the 
# information it needs because it may not exist yet.
# To solve that, the action of the playback tag is
# to note the output possition within the current
# block so that we can pull in the text in post-
# processing.

our $diversion_graph;
our %diversion_text;
our %diversion_used;
our %diversion_playback;
our $diversion_current;

sub enable_diversions 
{
	my ($attr, $closed) = @_;
	die unless $closed;
	my $real_text = shift(@process_text);



	rbuf (sub {
		local(%diversion_text);
		local(%diversion_used);
		local(%diversion_playback);
		local($diversion_graph) = Object::Dependency->new();

		$diversion_graph->add('*main body*');

		my $buf = compile($HTML::Transmorgify::modules, $real_text);
		{
			local($HTML::Transmorgify::result_array[0]) = '';
			print STDERR "Start(diversion=*main body*)\n" if $debug;
			local($diversion_current) = '*main body*';
			run($buf);
			$diversion_text{'*main body*'} = $HTML::Transmorgify::result_array[0];
			print STDERR "End(diversion=*main body*)\n" if $debug;
		}


		#
		# Pull the playbacks into the strings.
		#
		while(my ($ready) = $diversion_graph->independent(count => 1)) {
			$diversion_graph->remove_dependency($ready);
			my $textref = \$diversion_text{$ready};
			$$textref = '' unless defined $$textref;
			next unless $diversion_playback{$ready};
			my @newstring;
			my $lastpos = 0;
			for my $playback (@{$diversion_playback{$ready}}) {
				my $pos = $playback->{position};
				push(@newstring, substr($$textref, $lastpos, $pos-$lastpos));
				push(@newstring, $diversion_text{$playback->{diversion}});
				$lastpos = $pos;
			}
			push(@newstring, substr($$textref, $lastpos, length($$textref)-$lastpos));
			$$textref = join('', @newstring);
		}

		die unless $diversion_graph->alldone();

		$HTML::Transmorgify::result_array[0] .= $diversion_text{'*main body*'};
	});
	return undef;
}

sub capture_tag 
{
	my ($attr, $closed) = @_;
	die if $closed;
	my $static_name = $attr->static('name', 0);
	
	my $diversion = \my $str;
	my $buf = capture_compile("capture", $attr, $tag_package, '/capture' => \&return_false);
	do_trim($attr, $buf);
	eat_cr;

	rbuf (sub {
		my $name = $static_name or $attr->get('name', 0);
		die "<capture> tag requires a capture name" unless defined $name;
		allocate_result_type($name);
		local($HTML::Transmorgify::result_array[0]) = '';
		print STDERR "Start(diversion=$name)\n" if $debug;
		local($diversion_current) = $name;
		run($buf);
		$diversion_text{$name} .= $HTML::Transmorgify::result_array[0];
		print STDERR "End(diversion=$name)\n" if $debug;
	});
	return undef;
}

sub playback_tag 
{
	my ($attr, $closed) = @_;
	warn "$attr is not closed, but it should be" unless $closed;
	my $static_name = $attr->static('name', 0);

	rbuf (sub {
		my $name = $static_name or $attr->get('name', 0);
		confess unless defined $diversion_current;
		$diversion_playback{$diversion_current} ||= [];
		push(@{$diversion_playback{$diversion_current}}, {
			diversion	=> $name,
			position	=> length($HTML::Transmorgify::result_array[0]),
		});
		$diversion_graph->add($diversion_current, $name);
	});

	return undef;
}

#
# Add height & width to <img> tags if they don't 
# already have them.
#
$shared_tags{img} = \&img_tag;
sub img_tag 
{
	my ($attr) = @_;

	$attr->static_action('src', sub {
		print STDERR "# processing img $attr\n" if $debug;
		my $vals = $attr->vals;
		if (! $vals->{height} && ! $vals->{width} && $vals->{src}) {
			my $file = find_file($attr->get('src'));
			$attr->set(attr_imgsize($file)) if $file;
		}
	});

	return 1;
}

#
# Capture <script>...</script> and put it in the first result buffer
# for inclusion in a combined <script> section.  The </script> will be
# recognized even if it's inside a quoted string.
#
$tags{script} = \&script_tag;
sub script_tag 
{
	my ($attr, $closed) = @_;
	my $tag = "$attr";
	my $before = pos($$HTML::Transmorgify::textref);
	if (! $closed && $$HTML::Transmorgify::textref =~ m{
		(.*?)
		</script [\s>]
	}gcxs) {
		my $text = substr($$HTML::Transmorgify::textref, $before, pos($$HTML::Transmorgify::textref)-$before);
		rbuf (sub { $HTML::Transmorgify::result->[1] .= $tag . $text });
	} else {
		rbuf (sub { $HTML::Transmorgify::result->[1] .= $tag });
		return;
	}
};

$tags{"/script"} = \&dangling;

our %transformations = (
	html	=> \&encode_entities,
	uri	=> sub { uri_escape($_[0], "^A-Za-z0-9\-\._~/") },
	url	=> sub { uri_escape($_[0], "^A-Za-z0-9\-\._~/") },
	comment	=> sub { return '' },
	none	=> sub { $_[0] },
);

$tags{"/transform"} = \&dangling;
$tags{transform} = \&transform_tag;

#
# XXX TODO items:
#  1) cache transformation output
#  2) notice when transforming constant inputs and do it at compile time.
#

sub transform_tag
{
	my ($attr, $closed) = @_;
	die if $closed;
	eat_cr;

	my $encode = $attr->get('encode', 0);

	die unless $transformations{$encode};

	my $levels = 1;
	my $savebuf = capture_compile("transform", $attr, $tag_package,
		"/transform"	=> \&return_false,
	);

	rbuf (sub {
		print STDERR "# processing transform $attr\n" if $debug;
		my $contents;
		{
			local($HTML::Transmorgify::result->[0]) = '';
			run($savebuf);
			$contents = \$HTML::Transmorgify::result->[0];
		}
		$HTML::Transmorgify::result->[0] .= $transformations{$encode}->($$contents);
	});
};

#
# If we set a value, like: <define foo.bar.3.baz>value</define>
# then we have to to auto vivify an entire data structure.  We
# assume that small (1-9999) integers are array indexes.
#
# We return a reference to the emtpy cell so that a value can 
# be assigned.
#

sub create_container
{
	my ($ref, @refines) = @_;
	print STDERR "Adding new containers: @refines\n" if $debug;
	while (@refines > 1) {
		my $new;
		my $ele = shift @refines;
		if ($refines[0] =~ /^\d{1,4}$/) {
			$new = [];
		} else {
			$new = {};
		}
		if (blessed $ref) {
			# should be a HTML::Transmorgify::ObjectGlue
			$ref->set($ele, $new);
		} elsif (ref($ref) eq 'ARRAY') {
			$ref->[$ele] = $new;
		} elsif (ref($ref) eq 'HASH') {
			$ref->{$ele} = $new;
		} else {
			die;
		}
		$ref = $new;
	}
	return $ref;
}

#
# This returns a function that sets a variable (of the $name
# parameter) to a value.
#

sub get_varset_func
{
	my ($name) = @_;
	if ($name =~ /(.+)\.([^\.]+)/) {
		my ($cname, $ename) = ($1, $2);
		my $container = lookup($cname, $ename, $cname);
		if (blessed $container) {
			# should be a HTML::Transmorgify::ObjectGlue
			return sub { $container->set($ename, $_[0]) };
		} elsif (ref($container) eq 'HASH') {
			return sub { $container->{$ename} = $_[0] };
		} elsif (ref($container) eq 'ARRAY') {
			return sub { $container->[$ename] = $_[0] };
		} else {
			die "no container $cname to hold $ename";
		}
	} else {
		return sub { $HTML::Transmorgify::variables{$name} = $_[0] };
	}
}

#
# This looks up a variable, optionally creating the container
# object to to hold the variable.  Variables can have multiple
# components to their names: eg: "a.b.c".  
#

sub lookup
{
	my ($name, $create, $error_context) = @_;

	if ($debug) { no warnings; print STDERR "lookup($name, $create, $error_context)\n"; }

	unless (defined($name) && length($name)) {
		print STDERR "# tried to look up undef/empty!\n" if $debug;
		return '';
	}

	die if $name =~ /^ /;

	my ($primary, @refines) = split(/[.]/, $name);

	unless (exists $HTML::Transmorgify::variables{$primary}) {
		if (defined $create) {
			return create_container(\%HTML::Transmorgify::variables, $primary, @refines, $create);
		} else {
			print STDERR "# tried to look up $primary ($name) and didn't find it\n" if $debug;
			return '';
		}
	}

	my $r = $HTML::Transmorgify::variables{$primary};

	printf STDERR "# lookup %s, got '%s'\n", $name, dstring($r) if $debug;

	while (@refines) {
		my $new;
		my $key = shift @refines;
		if (blessed $r) {
			# should be a HTML::Transmorgify::ObjectGlue
			$new = $r->lookup($key, 0, $error_context);
		} elsif (ref $r) {
			if (reftype($r) eq 'ARRAY') {
				unless ($key =~ /\A\d+\z/) {
					die "attempt to index into array with non-number '$key' for $error_context starting from $HTML::Transmorgify::original_file" 
				}
				$new = $r->[$key];
			} elsif (reftype($r) eq 'HASH') {
				$new = $r->{$key};
			} else {
				die;
			}
		} else {
			return undef;
			# die "could not look up $key with $r in $input_file:$input_line for $error_context";
		}
		if (defined($create) && ! defined($new)) {
			return create_container($r, $key, @refines, $create);
		}
		$r = $new;
	}

	return $r;
}

#
# to_text() returns the text associated with the lookup of a
# variable.  
#

sub to_text
{
	my ($r, $attr) = @_;

	my $vals = $attr->vals;
	local(@HTML::Transmorgify::variables{keys %$vals}) = values %$vals;

	if (ref $r) {
		if (blessed($r)) {
			# should be a HTML::Transmorgify::ObjectGlue
			$r = $r->text;
		} elsif (reftype($r) eq 'CODE') {
			$r = $r->($attr);
		} elsif (reftype($r) eq 'ARRAY') {
			# XXX is this a good idea?
			$r = join(', ', @$r);
		} elsif (reftype($r) eq 'HASH') {
			# XXX is this a good idea?
			$r = join(', ', map { "$_ => $r->{$_}" } keys %$r);
		} else {
			die;
		}
	}

	die if ref($r);

	return '' unless defined $r;
	return $r;
}



$tags{macro} = \&macro_tag;
sub macro_tag {
	my ($attr, $closed) = @_;
	rbuf (sub {
		my $name = $attr->get('name', 0);
		my $encode = $attr->get('encode') || 'none';

		printf STDERR "# macro '%s' encode='%s'\n", dstring($name), $encode if $debug;

		my $r = to_text(lookup($name, 0, $attr), $attr);

		die "no transformation '$encode' defined" unless $transformations{$encode};

		printf STDERR "# before tranform %s: '%s'\n", $encode, $r if $debug;
		$r = $transformations{$encode}->($r);
		printf STDERR "# after  tranform %s: '%s'\n", $encode, $r if $debug;

		$HTML::Transmorgify::result->[0] .= $r if defined $r;
		printf STDERR "# macro expansion '%s' = '%s'\n", "$attr", dstring($r) if $debug;
	});
	return undef;
};


$tags{"/foreach"} = \&dangling;
$tags{foreach} = \&foreach_tag;

sub foreach_tag
{
	my ($attr, $closed) = @_;
	die if $closed;
	eat_cr;

	my $buf = capture_compile("foreach", $attr, $tag_package, '/foreach' => \&return_false);
	do_trim($attr, $buf);
	eat_cr;
	# write test for same
	# document trim= for <foreach>

	rbuf (sub {
		my $var = $attr->get('var', 0);
		printf STDERR "# running foreach: loop var %s\n", dstring($var) if $debug;

		my $container = $attr->get('container', 1);
		my $lastpos = $attr->last_position;
		my @containers;
		if ($lastpos > 0) {
			for my $p (1..$lastpos) {
				push(@containers, $attr->get(undef, $p));
			}
		} else {
			push(@containers, $attr->get('container'));
		}

		die unless @containers;
		my @a;
		for my $container (@containers) {
			my $r = lookup($container, 0, $attr);
			printf STDERR "# container value: %s.\n", dstring($r) if $debug;
			if (blessed($r)) {
				# should be a HTML::Transmorgify::ObjectGlue
				my @e = $r->expand();
				unless (@e == 1 && ref $r) {
					my $i = 0;
					push(@a, map { $i++ => $_ } @e);
					next;
				}
			}
			if (reftype($r) eq 'ARRAY') {
				my $i = 0;
				push(@a, map { exists($r->[$i++]) ? ($i-1 => $_) : () } @$r);
			} elsif (reftype($r) eq 'HASH') {
				push(@a, map { $_ => $r->{$_} } sort keys %$r);
			} elsif (ref($r)) {
				die;
			} elsif (defined $r) {
				push(@a, $r => $r);
			} else {
				# undef
			}
		}

		for (my $i = 0; $i <= $#a; ) {
			my $key = $a[$i++];
			my $val = $a[$i++];
			local($HTML::Transmorgify::variables{$var}) = $val;
			local($HTML::Transmorgify::variables{"_$var"}) = $key;
			run($buf);
		}
	});

	return undef;
};

$tags{"/if"} = \&dangling;
$tags{if} = \&if_tag;
$tags{else} = sub { die "<else> w/o <if>" };
$tags{elsif} = sub { die "<elsif> w/o <if>" };

sub if_tag 
{
	my ($attr, $closed) = @_;
	eat_cr;

	die if $closed;

	my @sets;

	my $current = {
		attr		=> $attr,
	};
	push(@sets, $current);

	{
		my $found = sub {
			my ($attr, $closed) = @_;

			eat_cr;
			die if $closed;
			$current->{rbuf} = [ @$HTML::Transmorgify::rbuf ];
			@$HTML::Transmorgify::rbuf = ();
			$current = {
				attr	=> $attr,
			};
			push(@sets, $current);
			return 0;
		};

		local($HTML::Transmorgify::rbuf) = $current->{rbuf};
		my $buf = capture_compile("if", $attr, $tag_package,
			if => \&if_tag,
			else => $found,
			elsif => $found,
			"/if" => \&return_false);
		die if $current->{rbuf};
		$current->{rbuf} = $buf;
	}
	eat_cr;

	for my $s (@sets) {
		my $a = $attr;
		$a = $s->{attr} if $s->{attr}->static('trim');
		do_trim($a, $s->{rbuf});
	}

	my %counters = (
		else	=> 0,
		if	=> 0,
		elsif	=> 0,
	);
	for my $s (@sets) {
		$counters{$s->{attr}->tag}++;
	}
	die if $counters{else} > 1;
	die if $counters{if} > 1;

	for my $s (@sets) {
		next if $s->{attr}->tag eq 'else';
		$s->{evaluate} = conditional($s->{attr});
	}

	rbuf (sub {
		print STDERR "# processing if statement $attr\n" if $debug;
		for my $s (@sets) {
			next unless $s->{attr}->tag eq 'else' || $s->{evaluate}->();
			run($s->{rbuf});
			last;
		}
	});
	return 0;
};

our %allowed_functions = (
	abs	=> sub { abs($_[0]) },
	min	=> \&List::Util::min,
	max	=> \&List::Util::max,
	defined	=> sub { defined($_[0]) },
);

use HTML::Transmorgify::Conditionals;

my $expr_grammar = HTML::Transmorgify::Conditionals->new();

sub conditional
{
	my ($attr) = @_;
	my $vals = $attr->vals;
	if (exists $vals->{is_set}) {
		return sub {
			print STDERR "# checking set? $attr\n" if $debug;
			return to_text(lookup($attr->get('is_set'), 0, $attr), $attr);
		};
	} elsif (exists $vals->{expr}) {
		my $expr = $expr_grammar->conditional($attr->raw('expr'));
		die sprintf("expression '%s' did not compile", $attr->raw('expr'))  unless $expr;
		return sub {
			# print STDERR "# checking expr? $attr: $expr\n" if $debug;
			return $expr->();
		};
	} else {
		die;
	}
}

sub find_file
{
	my ($file) = @_;
	die if $file =~ m{^/};
	for my $i (@include_dirs) {
		if (ref($i) && ref($i) eq 'CODE') {
			my $x = $i->($file);
			return $x if $x && -e $x;
		} elsif (ref($i)) {
			die;
		}
		next unless -e "$i/$file";
		return "$i/$file";
	}
	return undef;
}


#
# This is used by various control-flow tags to eliminate 
# whitespace from around them.  You want to be able to format
# the control-flow directives without adding whitespace to the
# final document.  This function removes extra whitespace.
#

sub do_trim
{
	my ($attr, $buf) = @_;

	my $trim = $attr->raw('trim');
	if (@$buf && boolean($trim, 0)) {
		if ($trim eq 'all') {
			(s/^\s+// || s/\s+$//) 
				for grep { ! ref($_) } @$buf;
		} else {
			if ($trim ne 'end') {
				$buf->[0] =~ s/^\s+//
					unless ref $buf->[0];
			}
			if ($trim ne 'start') {
				$buf->[$#$buf] =~ s/\s+$//
					unless ref $buf->[$#$buf];
			}
		}
	}
}

__END__

Should this be allowed?

$tags{import} = \&import_tag;

sub import_tag
{
	my ($attr, $closed) = @_;
	warn unless $closed;
	eat_cr;
	my $name = $attr->position(0, 'module');

	rbuf (sub { 
		my $x = "HTML::Transmorgify::$name";
		load $x;
		$x->add_tags(undef);
	});
	return undef;
};

