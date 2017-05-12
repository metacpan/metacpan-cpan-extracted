# $Id: Compact.pm 15 2006-09-04 20:00:01Z andrew $
# Copyright (c) 2004-2006 Andrew Stewart Williams. All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.

package Getopt::Compact;
use strict;
use Getopt::Long;
use Config;
use File::Spec;
use Carp;
use vars qw($VERSION);
use constant CONSTRUCTOR_OPTIONS =>
    (qw/struct usage name version author cmd args configure modes/);
use constant DEFAULT_CONFIG => (no_auto_abbrev => 1, bundling => 1);

$VERSION = "0.04";

sub new {
    my($class, %args) = @_;
    my $self = bless {}, $class;
    my(%opt, $i);

    $args{struct} ||= [];
    for $i (CONSTRUCTOR_OPTIONS) {
        next unless exists $args{$i};
        $self->{$i} = delete $args{$i};
    }
    croak("unrecognised option: $_") for keys %args;

    my $struct = $self->{struct};
    $self->{usage} = 1 unless exists $self->{usage};
    unless ($self->{cmd}) {
        require File::Basename;
        $self->{cmd} = File::Basename::basename($0 || '');
    }

    # more version munging
    my $v = $self->{version} || $main::VERSION || '1.0';
    $v = $1 if $v =~ /\$?Revision:?\s*([\d\.]+)/;
    $self->{version} = $v;

    # add mode options
    if ($self->{modes}) {
        my @modeopt;
        for my $m (@{$self->{modes}}) {
            my($mc) = $m =~ /^(\w)/;
            $mc = 'n' if $m eq 'test';
            push @modeopt, [[$mc, $m], qq($m mode)];
        }
        unshift @$struct, @modeopt;
    }

    # add --help option if usage is enabled
    unshift @$struct, [[qw(h help)], qq(this help message)]
        if $self->{usage} && !$self->_has_option('help');

    # add --man option unless one already exists
    unless($self->_has_option('man')) {
        push @$struct, ['man', qq(Display documentation)];
        $self->{_allow_man} = 1;
    }

    my $opthash = {};
    $self->{opt} = \%opt;
    for my $s (@$struct) {
        my($m, $descr, $spec, $ref) = @$s;
	my @onames = $self->_option_names($m);
	my($longname) = grep length($_) > 1, @onames;  # first long name
        my $o = join('|', @onames).($spec || '');
	my $dest = $longname ? $longname : $onames[0];
        $opt{$dest} = undef;  # initialise destination
        $opthash->{$o} = ref $ref ? $ref : \$opt{$dest};
    }

    # configure getopt option preferences
    my %config = (DEFAULT_CONFIG, %{$self->{configure} || {}});
    my @gconf = grep $config{$_}, keys %config;
    Getopt::Long::Configure(@gconf) if @gconf;

    # parse options
    $self->{ret} = GetOptions(%$opthash);

    return $self;
}

sub opts {
    my($self) = @_;
    my $opt = $self->{opt};
    if ($self->{_allow_man} && $opt->{man}) {
        # display modified POD
        $self->pod2usage();
        exit !$self->status;
    } elsif ($self->{usage} && ($opt->{help} || $self->status == 0)) {
        # display usage message & exit
        print $self->usage;
        exit !$self->status;
    }
    return $opt;
}

# munge & print a POD manpage
sub pod2usage {
    my $self = shift;
    my $usage = $self->usage;
    my $script = $self->_find_program;

    require Getopt::Compact::PodMunger;
    my $pod = new Getopt::Compact::PodMunger;
    $pod->parse_from_file($script) if defined $script;
    $pod->insert('NAME', $self->{name} || $self->{cmd});
    $pod->insert('USAGE', $usage, 1);
    $pod->insert('VERSION', $self->{version});
    $pod->insert('AUTHOR', $self->{author});
    $pod->print_manpage;
}

# return return value of GetOptions
sub status { shift->{ret} }

# return a string explaining usage
sub usage {
    my($self) = @_;
    my $usage = "";
    my($v, @help);

    my($name, $version, $cmd, $struct, $args) = map
	$self->{$_} || '', qw/name version cmd struct args/;

    if($name) {
        $usage .= $name;
	$usage .= " v$version" if $version;
        $usage .= "\n";
    }
    $usage .= "usage: $cmd [options] $args\n";

    for my $o (@$struct) {
	my($opts, $desc) = @$o;
        next unless defined $desc;
	my @onames = $self->_option_names($opts);
        my $optname = join
            (', ', map { (length($_) > 1 ? '--' : '-').$_ } @onames);
	$optname = "    ".$optname unless length($onames[0]) == 1;
        push @help, [ $optname, ucfirst($desc) ];
    }
    require Text::Table;
    my $sep = '   ';
    my $tt = new Text::Table('options', \$sep, '');
    $tt->load(@help);
    $usage .= $tt."\n";
    return $usage;
}

sub version { $VERSION }

######################################################################
# Private subs/methods

sub _option_names {
    my($self, $m) = @_;
    return sort _opt_sort (ref $m eq 'ARRAY' ? @$m : $m);
}
sub _opt_sort {
    my($la, $lb) = map length($_), $a, $b;
    return $la <=> $lb if $la < 2 or $lb < 2;
    return 0;
}

sub _has_option {
    my($self, $option) = @_;
    return 1 if grep $_ eq $option, map
	$self->_option_names($_->[0]), @{$self->{struct}};
    return 0;
}

# find the full path to the program, or undefined if it couldn't be found
sub _find_program {
    my($self) = @_;
    return $self->{_program} if exists $self->{_program};
    my $script = $0;
    if(defined $script && ! -e $script) {
	# $0 is not the full path to script.  look for script in path.
        require Env::Path;
        ($script) = Env::Path->Whence($script);
    }
    return $self->{_program} = $script;
}

1;

=head1 NAME

Getopt::Compact - getopt processing in a compact statement with both
long and short options, and usage functionality.

=head1 SYNOPSIS

inside foobar.pl:

    use Getopt::Compact;

    # (1) simple usage:
    my $opts = new Getopt::Compact
        (struct =>
         [[[qw(b baz)], qq(baz option)],  # -b or --baz
          ["foobar", qq(foobar option)],  # --foobar only
         ])->opts();

    # (2) or, a more advanced usage:
    my $go = new Getopt::Compact
        (name => 'foobar program', modes => [qw(verbose test debug)],
         struct =>
         [[[qw(w wibble)], qq(specify a wibble parameter), ':s'],
          [[qw(f foobar)], qq(apply foobar algorithm)],
          [[qw(j joobies)], qq(jooby integer list), '=i', \@joobs],
         ]
        );
    my $opts = $go->opts;

    print "applying foobar algorithm\n" if $opt->{foobar};
    print "joobs: @joobs\n" if @joobs;
    print $go->usage if MyModule::some_error_condition($opts);

using (2), running the command './foobar.pl -x' results in the
following output:

    Unknown option: x
    foobar program v1.0
    usage: foobar.pl [options]
    options
    -h, --help      This help message
    -v, --verbose   Verbose mode
    -n, --test      Test mode
    -d, --debug     Debug mode
    -w, --wibble    Specify a wibble parameter
    -f, --foobar    Apply foobar algorithm
    -j, --joobies   Jooby integer list
        --man       Display documentation

=head1 DESCRIPTION

This is yet another Getopt related module.  Getopt::Compact is geared
towards compactly and yet quite powerfully describing an option
syntax.  Options can be parsed, returned as a hashref of values,
and/or displayed as a usage string or within the script POD.

=head1 PUBLIC METHODS

=over 4

=item new()

    my $go = new Getopt::Compact(%options)

Instantiates a Getopt::Compact object.  This will parse the command
line arguments and store them for later retrieval (via the opts()
method).  On error a usage string is printed and exit() is called,
unless you have set the 'usage' option to false.

The following constructor options are recognised:

=over 4

=item C<name>

The name of the program.  This is printed at the start of the usage string.

=item C<cmd>

The command used to execute this program.  Defaults to $0.  This will be
printed as part of the usage string.

=item C<version>

Program version.  Can be an RCS Version string, or any other string.
Displayed in usage information.  The default is ($main::VERSION || '1.0')

=item C<usage>

'usage' is set to true by default.  Set it to false (0) to disable the
default behaviour of automatically printing a usage string and exiting
when there are parse errors or the --help option is given.

=item C<args>

A string describing mandatory arguments to display in the usage string.
eg: 

    print new Getopt::Compact
        (args => 'foo', cmd => 'bar.pl')->usage;

displays:

    usage: bar.pl [options] foo

=item C<modes>

This is a shortcut for defining boolean mode options, such as verbose
and test modes.  Set it to an arrayref of mode names, eg
[qw(verbose test)].  The following statements are equivalent:

    # longhand version
    my $go = new Getopt::Compact
        (struct => [[[qw(v verbose)], qw(verbose mode)],
                    [[qw(n test)],    qw(test mode)],
                    [[qw(d debug)],   qw(debug mode)],
                    [[qw(f foobar)],  qw(activate foobar)],
                   ]);

and

    # shorthand version
    my $go = new Getopt::Compact
        (modes => [qw(verbose test debug)],
         struct => [[[qw(f foobar)], qq(activate foobar)]]);

Mode options will be prepended to any options defined via the 'struct'
option.

=item C<struct>

This is where most of the option configuration is done.  The format
for a struct option is an arrayref of arrayrefs (see C<SYNOPSIS>) in
the following form (where [ ] denotes an array reference):

    struct => [optarray, optarray, ...]

and each optarray is an array reference in the following form:
(only 'name specification' is required)

    [name spec, description, argument spec, destination]

name specification may be a scalar string, eg "length", or a reference
to an array of alternate option names, eg [qw(l length)].  The option
name specification is also used to determine the key to the option
value in the hashref returned by C<opts()>.  See C<opts()> for more
information.

The argument specification is passed directly to Getopt::Long, so any
syntax recognised by Getopt::Long should also work here.  Some argument
specifications are:

    =s  Required string argument
    :s  Optional string argument
    =i  Required integer argument
    +   Value incrementing
    !   Negatable option

Refer to L<Getopt::Long> documentation for more details on argument
specifications.

The 'destination' is an optional reference to a variable that will
hold the option value.  If destination is not specified it will be
stored internally by Getopt::Compact and can be retrieved via the
opts() method.
This is useful if you want options to accept multiple values.  The
only way to achieve this is to use a destination that is a reference
to a list (see the joobies option in C<SYNOPSIS> by way of example).

=item C<configure>

Optional configure arguments to pass to Getopt::Long::Configure in the form
of a hashref of key, boolean value pairs.
By default, the following configuration is used:

{ no_auto_abbrev => 1, bundling => 1 }

To disable bundling and have case insensitive single-character options you
would do the following:

new Getopt::Compact
    (configure => { ignorecase_always => 1, bundling => 0 });

see Getopt::Long documentation for more information on configuration options.

=back

=item $go->usage()

    print $go->usage();

Returns a usage string.  Normally the usage string will be printed
automatically and the program will exit if the user supplies an
unrecognised argument or if the -h or --help option is given.
Automatic usage and exiting can be disabled by setting 'usage'
to false (0) in the constructor (see new()).
This method uses L<Text::Table> internally to format the usage output.

The following options may be automatically added by Getopt::Compact:

=over 4

=item "This help message" (-h or --help)

A help option is automatically prepended to the list of available
options if the C<usage> constructor option is true (this is enabled by
default).  When invoked with -h or --help, Getopt::Compact
automatically displays the usage string and exits.

=item "Display documentation" (--man)

This option is appended to the list of available options unless an
alternative --man option has been defined.  When invoked with --man,
Getopt::Compact prints a modified version of its POD to stdout and
exits.

=back

=item $go->pod2usage()

Displays the POD for the script.  The POD will be altered to include
C<USAGE>, C<NAME> and C<VERSION> sections unless they already exist.
This is invoked automatically when the --man option is given.

=item $go->status()

    print "getopt ".($go->status ? 'success' : 'error'),"\n";

The return value from Getopt::Long::Getoptions(). This is a true value
if the command line was processed successfully. Otherwise it returns a
false result.

=item $go->opts()

    $opt = $go->opts;

Returns a hashref of options keyed by option name.  If the
constructor usage option is true (on by default), then a usage string
will be printed and the program will exit if it encounters an
unrecognised option or the -h or --help option is given.

The key in %$opt for each option is determined by the option names
in the specification used in the C<struct> definition.  For example:

=over 4

=item ["foo", qw(foo option)]

The key will be "foo".

=item [[qw(f foo)], qw(foo option)]

=item [[qw(f foo foobar)], qw(foo option)]

In both cases the key will be "foo".  If multiple option names are
given, the first long option name (longer than one character) will be
used as the key.

=item [[qw(a b)], qq(a or b option)]

The key here will be "a".  If all alternatives are one character, the first option name in the list is used as the key

=back

=back

=head1 AUTHOR

Andrew Stewart Williams

=head1 SEE ALSO

Getopt::Long

=cut
