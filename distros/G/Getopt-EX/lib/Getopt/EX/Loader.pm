package Getopt::EX::Loader;

use strict;
use warnings;
use Carp;

use Exporter 'import';
our @EXPORT      = qw();
our %EXPORT_TAGS = ( );
our @EXPORT_OK   = qw();

use Data::Dumper;
use Getopt::EX::Module;
use Getopt::EX::Func qw(parse_func);

our $debug = 0;

sub new {
    my $class = shift;

    my $obj = bless {
	BUCKETS => [],
	BASECLASS => undef,
	MODULE_OPT => '-M',
	DEFAULT => 'default',
	PARSE_MODULE_OPT => 1,
	IGNORE_NO_MODULE => 0,
    }, $class;

    configure $obj @_ if @_;

    $obj;
}

my @OPTIONS = qw(
    BASECLASS
    MODULE_OPT
    DEFAULT
    PARSE_MODULE_OPT
    IGNORE_NO_MODULE
    );

sub configure {
    my $obj = shift;
    my %opt = @_;

    for my $opt (@OPTIONS) {
	if (defined (my $value = delete $opt{$opt})) {
	    $obj->{$opt} = $value;
	}
    }

    if (my $rc = delete $opt{RCFILE}) {
	my @rc = ref $rc eq 'ARRAY' ? @$rc : $rc;
	for (@rc) {
	    $obj->load(FILE => $_);
	}
    }

    warn "Unknown option: ", Dumper \%opt if %opt;

    $obj;
}

sub baseclass {
    my $obj = shift;
    @_  ? $obj->{BASECLASS} = shift
	: $obj->{BASECLASS};
}

sub buckets {
    my $obj = shift;
    @{ $obj->{BUCKETS} };
}

sub append {
    my $obj = shift;
    push @{ $obj->{BUCKETS} }, @_;
}

sub load {
    my $obj = shift;
    my $bucket =
	new Getopt::EX::Module @_, BASECLASS => $obj->baseclass;
    $obj->append($bucket);
    $bucket;
}

sub load_file {
    my $obj = shift;
    $obj->load(FILE => shift);
}

sub load_module {
    my $obj = shift;
    $obj->load(MODULE => shift);
}

sub defaults {
    my $obj = shift;
    map { $_->default } $obj->buckets;
}

sub calls {
    my $obj = shift;
    map { $_->call } $obj->buckets;
}

sub builtins {
    my $obj = shift;
    map { $_->builtin } $obj->buckets;
}

sub deal_with {
    my $obj = shift;
    my $argv = shift;

    if (my $default = $obj->{DEFAULT}) {
	if (my $bucket = eval { $obj->load_module($default) }) {
	    $bucket->run_inits($argv);
	} else {
	    $!{ENOENT} or die $@;
	}
    }
    $obj->modopt($argv) if $obj->{PARSE_MODULE_OPT};
    $obj->expand($argv);
    $obj;
}

sub modopt {
    my $obj = shift;
    my $argv = shift;

    my $start = $obj->{MODULE_OPT} // return ();
    $start eq '' and return ();
    my $start_re = qr/\Q$start\E/;
    my @modules;
    while (@$argv) {
	if (my($modpart) = ($argv->[0] =~ /^$start_re(.+)/)) {
	    if (my $mod = $obj->parseopt($modpart, $argv)) {
		push @modules, $mod;
	    } else {
		last;
	    }
	    next;
	}
	last;
    }
    @modules;
}

sub parseopt {
    my $obj = shift;
    my($mod, $argv) = @_;
    my $call;

    ##
    ## Check -Mmod::func(arg) or -Mmod::func=arg
    ##
    if ($mod =~ s{
	^ (?<name> \w+ (?: :: \w+)* )
	  (?:
	    ::
	    (?<call>
		\w+
		(?: (?<P>[(]) | = )  ## start with '(' or '='
		(?<arg> [^)]* )      ## optional arg list
		(?(<P>) [)] | )      ## close ')' or none
	    )
	  )?
	  $
    }{$+{name}}x) {
	$call = $+{call};
    }

    my $bucket = eval { $obj->load_module($mod) } or do {
	if ($!{ENOENT}) {
	    if ($obj->{IGNORE_NO_MODULE}) {
		return undef;
	    } else {
		die "$mod: module not found\n";
	    }
	} else {
	    die $@;
	}
    };

    shift @$argv;

    if ($call) {
	$bucket->call(join '::', $bucket->module, $call);
    }

    ##
    ## If &getopt is defined in module, call it and replace @ARGV.
    ##
    $bucket->run_inits($argv);

    $bucket;
}

sub expand {
    my $obj = shift;
    my $argv = shift;

    ##
    ## Insert module defaults.
    ##
    unshift @$argv, map {
	if (my @s = $_->default()) {
	    my @modules = $obj->modopt(\@s);
	    [ @s, map { $_->default } @modules ];
	} else {
	    ();
	}
    } $obj->buckets;

    ##
    ## Expand user defined option.
    ##
  ARGV:
    for (my $i = 0; $i < @$argv; $i++) {

	last if $argv->[$i] eq '--';
	my $current = $argv->[$i];

	for my $bucket ($obj->buckets) {

	    my @s;
	    if (ref $current eq 'ARRAY') {
		##
		## Expand defaults.
		##
		@s = @$current;
		$current = 'DEFAULT';
	    }
	    else {
		##
		## Try entire string match, and check --option=value.
		##
		@s = $bucket->getopt($current);
		if (not @s) {
		    $current =~ /^(.+?)=(.*)/ or next;
		    @s = $bucket->getopt($1)  or next;
		    splice @$argv, $i, 1, ($1, $2);
		}
	    }

	    my @follow = splice @$argv, $i;

	    ##
	    ## $<n>
	    ##
	    s/\$<(-?\d+)>/$follow[$1]/ge foreach @s;

	    shift @follow;

	    ##
	    ## $<shift>, $<move>, $<remove>, $<copy>
	    ##
	    @s = map sub {
		s/\$<shift>/@follow ? shift @follow : ''/ge;
		my($cmd) = m{^\$ < (.+) >$}x or return $_;
		($cmd =~ m{^(?<cmd> move | remove | copy )
			   (?: \(      (?<off> -?\d+ ) ?
				  (?: ,(?<len> -?\d+ ))? \) )? $ }x)
		    or return $_;
		my $p = ($+{cmd} ne 'copy')
		    ? \@follow
		    : do { my @new = @follow; \@new };
		my @arg = @$p == 0 ? ()
		    : defined $+{len} ? splice @$p, $+{off}//0, $+{len}
		    : splice @$p, $+{off}//0;
		($+{cmd} eq 'remove') ? () : @arg;
	    }->(), @s;

	    @s = $bucket->expand_args(@s);

	    if ($debug) {
		printf STDERR
		    "\@ARGV = %s\n",
		    join(' ',
			 @$argv,
			 join(' ', '<', @s, '>'),
			 @follow);
	    }

	    my @module = $obj->modopt(\@s);

	    my @default = map { [ $_->default ] } @module;
	    push @$argv, @default, @s, @follow;

	    redo ARGV if $i < @$argv;
	}
    }
}

sub modules {
    my $obj = shift;
    my $class = $obj->baseclass // return ();
    my @base = ref $class eq 'ARRAY' ? @$class : ($class);
    for (@base) {
	s/::/\//g;
	$_ = "/$_" if $_ ne "";
    }

    map {
	my $base = $_;
	grep { /^[a-z]/ }
	map  { /(\w+)\.pm$/ }
	map  { glob $_ . $base . "/*.pm" }
	@INC;
    } @base;
}

1;

=head1 NAME

Getopt::EX::Loader - RC/Module loader

=head1 SYNOPSIS

  use Getopt::EX::Loader;

  my $loader = new Getopt::EX::Loader
      BASECLASS => 'App::example';

  $loader->load_file("$ENV{HOME}/.examplerc");

  $loader->deal_with(\@ARGV);

  my $parser = new Getopt::Long::Parser;
  $parser->getoptions( ... , $loader->builtins )

=head1 DESCRIPTION

This is the main interface to use L<Getopt::EX> modules.  You can
create loader object, load user defined rc file, load modules
specified by command arguments, substitute user defined option and
insert default options defined in rc file or modules, get module
defined built-in option definition for option parser.

Most of work is done in C<deal_with> method.  It parses command
arguments and load modules specified by B<-M> option by default.  Then
it scans options and substitute them according to the definitions in
rc file or modules.  If RC and modules defines default options, they
are inserted to the arguments.

Module can define built-in options which should be handled option
parser.  They can be taken by C<builtins> method, so you should give
them to option parser.

If C<App::example> is given as a C<BASECLASS> of the loader object, it
is prepended to all module names.  So command line

    % example -Mfoo

will load C<App::example::foo> module.

In this case, if module C<App::example::default> exists, it is loaded
automatically without explicit indication.  Default module can be used
just like a startup RC file.


=head1 METHODS

=over 4

=item B<configure> I<name> => I<value>, ...

=over 4

=item BASECLASS

Define base class for user defined module.  Use array reference to
specify multiple base classes; they are tried to be loaded in order.

=item MODULE_OPT

Define module option string.  String B<-M> is set by default.

=item DEFAULT

Define default module name.  String B<default> is set by default.  Set
C<undef> if you don't want load any default module.

=item PARSE_MODULE_OPT

Default true, and parse module options given to C<deal_with> method.
When disabled, module option in command line argument is not
processed, but module option given in rc or module files are still
effective.

=item IGNORE_NO_MODULE

Default false, and process dies when given module was not found on the
system.  When set true, program ignores not-existing module and stop
parsing at the point leaving the argument untouched.

=back

=item B<buckets>

Return loaded L<Getopt::EX::Module> object list.

=item B<load_file>

Load specified file.

=item B<load_module>

Load specified module.

=back
