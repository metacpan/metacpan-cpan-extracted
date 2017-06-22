package Make;

use strict;
use warnings;

our $VERSION = '1.1.4';

use Carp;
use Config;
use Cwd;
use File::Spec;
use Make::Target ();

my %date;
my $generation = 0;    # lexical cross-package scope used!

sub phony {
	my ( $self, $name ) = @_;
	return exists $self->{PHONY}{$name};
}

sub suffixes {
	my ($self) = @_;
	return keys %{ $self->{'SUFFIXES'} };
}

#
# Construct a new 'target' (or find old one)
# - used by parser to add to data structures
#
sub Target {
	my ( $self, $target ) = @_;
	unless ( exists $self->{Depend}{$target} ) {
		my $t = Make::Target->new( $self, $target );
		$self->{Depend}{$target} = $t;
		if ( $target =~ /%/ ) {
			$self->{Pattern}{$target} = $t;
		}
		elsif ( $target =~ /^\./ ) {
			$self->{Dot}{$target} = $t;
		}
		else {
			push( @{ $self->{Targets} }, $t );
		}
	}
	return $self->{Depend}{$target};
}

#
# Utility routine for patching %.o type 'patterns'
#
sub patmatch {
	my $key = shift;
	local $_ = shift;
	my $pat = $key;
	$pat =~ s/\./\\./;
	$pat =~ s/%/(\[^\/\]*)/;
	if (/$pat$/) {
		return $1;
	}
	return;
}

#
# old vpath lookup routine
#
sub locate {
	my $self = shift;
	local $_ = shift;
	return $_ if ( -r $_ );
	foreach my $key ( keys %{ $self->{vpath} } ) {
		my $Pat;
		if ( defined( $Pat = patmatch( $key, $_ ) ) ) {
			foreach my $dir ( split( /:/, $self->{vpath}{$key} ) ) {
				return "$dir/$_" if ( -r "$dir/$_" );
			}
		}
	}
	return;
}

#
# Convert traditional .c.o rules into GNU-like into %o : %c
#
sub dotrules {
	my ($self) = @_;
	foreach my $t ( keys %{ $self->{Dot} } ) {
		my $e = $self->subsvars($t);
		$self->{Dot}{$e} = delete $self->{Dot}{$t} unless ( $t eq $e );
	}
	my (@suffix) = $self->suffixes;
	foreach my $t (@suffix) {
		my $d;
		my $r = delete $self->{Dot}{$t};
		if ( defined $r ) {
			my @rule = ( $r->colon ) ? ( $r->colon->depend ) : ();
			if (@rule) {
				delete $self->{Dot}{ $t->Name };
				print STDERR $t->Name, " has dependants\n";
				push( @{ $self->{Targets} }, $r );
			}
			else {
				# print STDERR "Build \% : \%$t\n";
				$self->Target('%')->dcolon( [ '%' . $t ], scalar $r->colon->command );
			}
		}
		foreach my $d (@suffix) {
			$r = delete $self->{Dot}{ $t . $d };
			if ( defined $r ) {

				# print STDERR "Build \%$d : \%$t\n";
				$self->Target( '%' . $d )->dcolon( [ '%' . $t ], scalar $r->colon->command );
			}
		}
	}
	foreach my $t ( keys %{ $self->{Dot} } ) {
		push( @{ $self->{Targets} }, delete $self->{Dot}{$t} );
	}
	return;
}

#
# Return 'full' pathname of name given directory info.
# - may be the place to do vpath stuff ?
#

my %pathname;

sub pathname {
	my ( $self, $name ) = @_;
	my $hash = $self->{'Pathname'};
	unless ( exists $hash->{$name} ) {
		if ( File::Spec->file_name_is_absolute($name) ) {
			$hash->{$name} = $name;
		}
		else {
			$name =~ s,^\./,,;
			$hash->{$name} = File::Spec->catfile( $self->{Dir}, $name );
		}
	}
	return $hash->{$name};

}

#
# Return modified date of name if it exists
#
sub date {
	my ( $self, $name ) = @_;
	my $path = $self->pathname($name);
	unless ( exists $date{$path} ) {
		$date{$path} = -M $path;
	}
	return $date{$path};
}

#
# Check to see if name is a target we can make or an existing
# file - used to see if pattern rules are valid
# - Needs extending to do vpath lookups
#
## no critic (Subroutines::ProhibitBuiltinHomonyms)
sub exists {
## use critic
	my ( $self, $name ) = @_;
	return 1 if ( exists $self->{Depend}{$name} );
	return 1 if defined $self->date($name);

	# print STDERR "$name '$path' does not exist\n";
	return 0;
}

#
# See if we can find a %.o : %.c rule for target
# .c.o rules are already converted to this form
#
sub patrule {
	my ( $self, $target ) = @_;

	# print STDERR "Trying pattern for $target\n";
	foreach my $key ( keys %{ $self->{Pattern} } ) {
		my $Pat;
		if ( defined( $Pat = patmatch( $key, $target ) ) ) {
			my $t = $self->{Pattern}{$key};
			foreach my $rule ( $t->dcolon ) {
				my @dep = $rule->exp_depend;
				if (@dep) {
					my $dep = $dep[0];
					$dep =~ s/%/$Pat/g;

					# print STDERR "Try $target : $dep\n";
					if ( $self->exists($dep) ) {
						foreach (@dep) {
							s/%/$Pat/g;
						}
						return ( \@dep, scalar $rule->command );
					}
				}
			}
		}
	}
	return ();
}

#
# Old code to handle vpath stuff - not used yet
#
sub needs {
	my ( $self, $target ) = @_;
	unless ( $self->{Done}{$target} ) {
		if ( exists $self->{Depend}{$target} ) {
			my @depend = split( /\s+/, $self->subsvars( $self->{Depend}{$target} ) );
			foreach (@depend) {
				$self->needs($_);
			}
		}
		else {
			my $vtarget = $self->locate($target);
			if ( defined $vtarget ) {
				$self->{Need}{$vtarget} = $target;
			}
			else {
				$self->{Need}{$target} = $target;
			}
		}
	}
	return;
}

#
# Substitute $(xxxx) and $x style variable references
# - should handle ${xxx} as well
# - recurses till they all go rather than doing one level,
#   which may need fixing
#
## no critic (RequireArgUnpacking)
sub subsvars {
	my $self = shift;
	local $_ = shift;
	my @var = @_;
## use critic
	push( @var, $self->{Override}, $self->{Vars}, \%ENV );
	croak("Trying to subsitute undef value") unless ( defined $_ );
	## no critic (Variables::ProhibitMatchVars)
	while ( /(?<!\$)\$\(([^()]+)\)/ || /(?<!\$)\$([<\@^?*])/ ) {
		my ( $key, $head, $tail ) = ( $1, $`, $' );
		## use critic
		my $value;
		if ( $key =~ /^([\w._]+|\S)(?::(.*))?$/ ) {
			my ( $var, $op ) = ( $1, $2 );
			foreach my $hash (@var) {
				$value = $hash->{$var};
				if ( defined $value ) {
					last;
				}
			}
			unless ( defined $value ) {
				die "$var not defined in '$_'" unless ( length($var) > 1 );
				$value = '';
			}
			if ( defined $op ) {
				if ( $op =~ /^s(.).*\1.*\1/ ) {
					local $_ = $self->subsvars($value);
					$op =~ s/\\/\\\\/g;
					next unless $op;

					#I'm not sure what purpose this eval served, and it
					#creates some warnings. Removing until I know a good
					#reason for it's existence.
					#eval { $op . 'g' };
					$value = $_;
				}
				else {
					die "$var:$op = '$value'\n";
				}
			}
		}
		elsif ( $key =~ /wildcard\s*(.*)$/ ) {
			$value = join( ' ', glob( $self->pathname($1) ) );
		}
		elsif ( $key =~ /shell\s*(.*)$/ ) {
			$value = join( ' ', split( '\n', `$1` ) );
		}
		elsif ( $key =~ /addprefix\s*([^,]*),(.*)$/ ) {
			$value = join( ' ', map { $1 . $_ } split( '\s+', $2 ) );
		}
		elsif ( $key =~ /notdir\s*(.*)$/ ) {
			my @files = split( /\s+/, $1 );
			foreach (@files) {
				s#^.*/([^/]*)$#$1#;
			}
			$value = join( ' ', @files );
		}
		elsif ( $key =~ /dir\s*(.*)$/ ) {
			my @files = split( /\s+/, $1 );
			foreach (@files) {
				s#^(.*)/[^/]*$#$1#;
			}
			$value = join( ' ', @files );
		}
		elsif ( $key =~ /^subst\s+([^,]*),([^,]*),(.*)$/ ) {
			my ( $a, $b ) = ( $1, $2 );
			$value = $3;
			$a =~ s/\./\\./;
			$value =~ s/$a/$b/;
		}

		# ($mktmp) appears to be a dmake only macro
		# its not yet clear to me just how temporary this temporary
		# file is expected to be, but hopefully we can replace this
		# with Path::Tiny->tempfile or the use of File::Temp directly
		# this also only handles one use of the macro, where the content
		# and filename are provided together. they may be provided
		# separately, which I don't think we handle yet
		elsif ( $key =~ /^mktmp,(\S+)\s*(.*)$/ ) {
			my ( $file, $content ) = ( $1, $2 );
			open( my $tmp, ">", $file ) or die "Cannot open $file: $!";
			$content =~ s/\\n//g;
			print TMP $content;
			close(TMP);

			# will have to see if we really want to return the filename
			# here, or if returning the filehandle is the right thing to do
			$value = $file;
		}
		else {
			warn "Cannot evaluate '$key' in '$_'\n";
		}
		$_ = "$head$value$tail";
	}
	s/\$\$/\$/g;
	return $_;
}

#
# Split a string into tokens - like split(/\s+/,...) but handling
# $(keyword ...) with embedded \s
# Perhaps should also understand "..." and '...' ?
#
sub tokenize {
	local $_ = $_[0];
	my @result = ();
	s/\s+$//;
	while ( length($_) ) {
		s/^\s+//;
		last unless (/^\S/);
		my $token = "";
		while (/^\S/) {
			## no critic (Variables::ProhibitMatchVars)
			if (s/^\$([\(\{])//) {
				$token .= $&;
				my $paren = $1 eq '(';
				my $brace = $1 eq '{';
				my $count = 1;
				while ( length($_) && ( $paren || $brace ) ) {
					s/^.//;
					$token .= $&;
					$paren += ( $& eq '(' );
					$paren -= ( $& eq ')' );
					$brace += ( $& eq '{' );
					$brace -= ( $& eq '}' );
				}
				die "Mismatched {} in $_[0]" if ($brace);
				die "Mismatched () in $_[0]" if ($paren);
			}
			elsif (s/^(\$\S?|[^\s\$]+)//) {
				$token .= $&;
			}
			## use critic
		}
		push( @result, $token );
	}
	return (wantarray) ? @result : \@result;
}

#
# read makefile (or fragment of one) either as a result
# of a command line, or an 'include' in another makefile.
#
sub makefile {
	my ( $self, $makefile, $name ) = @_;
	local $_;
	print STDERR "Reading $name\n";
Makefile:
	while (<$makefile>) {
		last unless ( defined $_ );
		chomp($_);
		if (/\\$/) {
			chop($_);
			s/\s*$//;
			my $more = <$makefile>;
			$more =~ s/^\s*/ /;
			$_ .= $more;
			redo;
		}
		next if (/^\s*#/);
		next if (/^\s*$/);
		s/#.*$//;
		s/^\s+//;
		if (/^(-?)include\s+(.*)$/) {
			my $opt = $1;
			foreach my $file ( tokenize( $self->subsvars($2) ) ) {
				my $path = $self->pathname($file);
				if ( open( my $mf, "<", $path ) ) {
					$self->makefile( $mf, $path );
					close($mf);
				}
				else {
					warn "Cannot open $path: $!" unless ( $opt eq '-' );
				}
			}
		}
		elsif (/^\s*([\w._]+)\s*:?=\s*(.*)$/) {
			$self->{Vars}{$1} = ( defined $2 ) ? $2 : "";

			#    print STDERR "$1 = ",$self->{Vars}{$1},"\n";
		}
		elsif (/^vpath\s+(\S+)\s+(.*)$/) {
			my ( $pat, $path ) = ( $1, $2 );
			$self->{Vpath}{$pat} = $path;
		}
		elsif (/^\s*([^:]*)(::?)\s*(.*)$/) {
			my ( $target, $kind, $depend ) = ( $1, $2, $3 );
			my @cmnds;
			if ( $depend =~ /^([^;]*);(.*)$/ ) {
				( $depend, $cmnds[0] ) = ( $1, $2 );
			}
			while (<$makefile>) {
				next if (/^\s*#/);
				next if (/^\s*$/);
				last unless (/^\t/);
				chop($_);
				if (/\\$/) {
					chop($_);
					$_ .= ' ';
					$_ .= <$makefile>;
					redo;
				}
				next if (/^\s*$/);
				s/^\s+//;
				push( @cmnds, $_ );
			}
			$depend =~ s/\s\s+/ /;
			$target =~ s/\s\s+/ /;
			my @depend = tokenize($depend);
			foreach ( tokenize($target) ) {
				my $t     = $self->Target($_);
				my $index = 0;
				if ( $kind eq '::' || /%/ ) {
					$t->dcolon( \@depend, \@cmnds );
				}
				else {
					$t->colon( \@depend, \@cmnds );
				}
			}
			redo Makefile;
		}
		else {
			warn "Ignore '$_'\n";
		}
	}
	return;
}

sub pseudos {
	my $self = shift;
	foreach my $key (qw(SUFFIXES PHONY PRECIOUS PARALLEL)) {
		my $t = delete $self->{Dot}{ '.' . $key };
		if ( defined $t ) {
			$self->{$key} = {};
			foreach my $dep ( $t->colon->exp_depend ) {
				$self->{$key}{$dep} = 1;
			}
		}
	}
	return;
}

sub ExpandTarget {
	my $self = shift;
	foreach my $t ( @{ $self->{'Targets'} } ) {
		$t->ExpandTarget;
	}
	foreach my $t ( @{ $self->{'Targets'} } ) {
		$t->ProcessColon;
	}
	return;
}

sub parse {
	my ( $self, $file ) = @_;
	if ( defined $file ) {
		$file = $self->pathname($file);
	}
	else {
		my @files = qw(makefile Makefile);
		unshift( @files, 'GNUmakefile' ) if ( $self->{GNU} );
		foreach my $name (@files) {
			$file = $self->pathname($name);
			if ( -r $file ) {
				$self->{Makefile} = $name;
				last;
			}
		}
	}
	open( my $mf, "<", $file ) or croak("Cannot open $file: $!");
	$self->makefile( $mf, $file );
	close($mf);

	# Next bits should really be done 'lazy' on need.

	$self->pseudos;     # Pull out .SUFFIXES etc.
	$self->dotrules;    # Convert .c.o into %.o : %.c
	return;
}

sub PrintVars {
	my $self = shift;
	local $_;
	foreach ( keys %{ $self->{Vars} } ) {
		print "$_ = ", $self->{Vars}{$_}, "\n";
	}
	print "\n";
	return;
}

sub exec {
	my $self = shift;
	undef %date;
	$generation++;
	if ( $^O eq 'MSWin32' ) {
		my $cwd = cwd();
		my $ret;
		chdir $self->{Dir};
		$ret = system(@_);
		chdir $cwd;
		return $ret;
	}
	else {
		my $pid = fork;
		if ($pid) {
			waitpid $pid, 0;
			return $?;
		}
		else {
			my $dir = $self->{Dir};
			chdir($dir) || die "Cannot cd to $dir";

			# handle leading VAR=value here ?
			# To handle trivial cases like ': libpTk.a' force using /bin/sh
			exec( "/bin/sh", "-c", @_ ) || confess "Cannot exec " . join( ' ', @_ );
		}
	}
}

## no critic (Subroutines::RequireFinalReturn)
sub NextPass { shift->{Pass}++ }
sub pass     { shift->{Pass} }
## use critic

## no critic (RequireArgUnpacking)
sub apply {
	my $self   = shift;
	my $method = shift;
	$self->NextPass;
	my @targets = ();

	# print STDERR join(' ',Apply => $method,@_),"\n";
	foreach (@_) {
		if (/^(\w+)=(.*)$/) {

			# print STDERR "OVERRIDE: $1 = $2\n";
			$self->{Override}{$1} = $2;
		}
		else {
			push( @targets, $_ );
		}
	}
	#
	# This expansion is dubious as it alters the database
	# as a function of current values of Override.
	#
	$self->ExpandTarget;    # Process $(VAR) :
	@targets = ( $self->{'Targets'}[0] )->Name unless (@targets);

	# print STDERR join(' ',Targets => $method,map($_->Name,@targets)),"\n";
	foreach (@targets) {
		my $t = $self->{Depend}{$_};
		unless ( defined $t ) {
			print STDERR join( ' ', $method, @_ ), "\n";
			die "Cannot `$method' - no target $_";
		}
		$t->$method();
	}
	return;
}
## use critic

## no critic (Subroutines::RequireFinalReturn RequireArgUnpacking)
sub Script {
	shift->apply( Script => @_ );
}

sub Print {
	shift->apply( Print => @_ );
}

sub Make {
	shift->apply( Make => @_ );
}
## use critic

sub new {
	my ( $class, %args ) = @_;
	unless ( defined $args{Dir} ) {
		chomp( $args{Dir} = getcwd() );
	}
	my $self = bless {
		%args,
		Pattern  => {},    # GNU style %.o : %.c
		Dot      => {},    # Trad style .c.o
		Vpath    => {},    # vpath %.c info
		Vars     => {},    # Variables defined in makefile
		Depend   => {},    # hash of targets
		Targets  => [],    # ordered version so we can find 1st one
		Pass     => 0,     # incremented each sweep
		Pathname => {},    # cache of expanded names
		Need     => {},
		Done     => {},
	}, $class;
	$self->{Vars}{CC}     = $Config{cc};
	$self->{Vars}{AR}     = $Config{ar};
	$self->{Vars}{CFLAGS} = $Config{optimize};
	$self->makefile( \*DATA, __FILE__ );
	$self->parse( $self->{Makefile} );
	return $self;
}

=head1 NAME

Make - module for processing makefiles

=head1 SYNOPSIS

	require Make;
	my $make = Make->new(...);
	$make->parse($file);
	$make->Script(@ARGV)
	$make->Make(@ARGV)
	$make->Print(@ARGV)

        my $targ = $make->Target($name);
        $targ->colon([dependancy...],[command...]);
        $targ->dolon([dependancy...],[command...]);
        my @depends  = $targ->colon->depend;
        my @commands = $targ->colon->command;

=head1 DESCRIPTION

Make->new creates an object if C<new(Makefile =E<gt> $file)> is specified
then it is parsed. If not the usual makefile Makefile sequence is
used. (If GNU => 1 is passed to new then GNUmakefile is looked for first.)

C<$make-E<gt>Make(target...)> 'makes' the target(s) specified
(or the first 'real' target in the makefile).

C<$make-E<gt>Print> can be used to 'print' to current C<select>'ed stream
a form of the makefile with all variables expanded.

C<$make-E<gt>Script(target...)> can be used to 'print' to
current C<select>'ed stream the equivalent bourne shell script
that a make would perform i.e. the output of C<make -n>.

There are other methods (used by parse) which can be used to add and
manipulate targets and their dependants. There is a hierarchy of classes
which is still evolving. These classes and their methods will be documented when
they are a little more stable.

The syntax of makefile accepted is reasonably generic, but I have not re-read
any documentation yet, rather I have implemented my own mental model of how
make works (then fixed it...).

In addition to traditional

	.c.o :
		$(CC) -c ...

GNU make's 'pattern' rules e.g.

	%.o : %.c
		$(CC) -c ...

Likewise a subset of GNU makes $(function arg...) syntax is supported.

Via pmake Make has built perl/Tk from the C<MakeMaker> generated Makefiles...

=head1 BUGS

At present C<new> must always find a makefile, and
C<$make-E<gt>parse($file)> can only be used to augment that file.

More attention needs to be given to using the package to I<write> makefiles.

The rules for matching 'dot rules' e.g. .c.o   and/or pattern rules e.g. %.o : %.c
are suspect. For example give a choice of .xs.o vs .xs.c + .c.o behaviour
seems a little odd.

Variables are probably substituted in different 'phases' of the process
than in make(1) (or even GNU make), so 'clever' uses will probably not
work.

UNIXisms abound.

=head1 SEE ALSO

L<pmake>

=head1 AUTHOR

Nick Ing-Simmons

=head1 COPYRIGHT AND LICENSE

Copyright (c) 1996-1999 Nick Ing-Simmons.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

1;
#
# Remainder of file is in makefile syntax and constitutes
# the built in rules
#
__DATA__

.SUFFIXES: .o .c .y .h .sh .cps

.c.o :
	$(CC) $(CFLAGS) $(CPPFLAGS) -c -o $@ $<

.c   :
	$(CC) $(CFLAGS) $(CPPFLAGS) -o $@ $< $(LDFLAGS) $(LDLIBS)

.y.o:
	$(YACC) $<
	$(CC) $(CFLAGS) $(CPPFLAGS) -c -o $@ y.tab.c
	$(RM) y.tab.c

.y.c:
	$(YACC) $<
	mv y.tab.c $@
