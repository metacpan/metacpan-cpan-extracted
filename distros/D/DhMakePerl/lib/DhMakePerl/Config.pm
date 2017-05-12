package DhMakePerl::Config;

use strict;
use warnings;

our $VERSION = '0.77';

=head1 NAME

DhMakePerl::Config - dh-make-perl configuration class

=cut

use base 'Class::Accessor';
use Dpkg::Source::Package;

my @OPTIONS = (
    'apt-contents-dir=s',
    'arch=s',          'backups!',
    'basepkgs=s',
    'bdepends=s',      'bdependsi=s',
    'build-source!',
    'build!',          'closes=i',
    'config-file=s',   'core-ok',
    'cpan-mirror=s',   'cpan=s',
    'cpanplus=s',      'data-dir=s',
    'dbflags=s',       'depends=s',
    'desc=s',          'dh=i',
    'dist=s',          'email|e=s',
    'exclude|i:s{,}',
    'home-dir=s',      'install!',
    'intrusive!',
    'network!',
    'nometa',          'notest',
    'only|o=s@',
    'packagename|p=s', 'pkg-perl!',
    'recursive!',
    'requiredeps',     'sources-list=s',
    'source-format=s', 'vcs=s',
    'verbose!',        'version=s',
);

my @COMMANDS =
    ( 'make', 'refresh|R', 'refresh-cache', 'dump-config', 'locate', 'help' );

__PACKAGE__->mk_accessors(
    do {
        my @opts = ( @OPTIONS, @COMMANDS );
        for (@opts) {
            s/[=:!|].*//;
            s/-/_/g;
        }
        @opts;
    },
    'command',
    'cpan2deb',
    'cpan2dsc',
    '_explicitly_set',
);

use File::Basename qw(basename);
use File::Spec::Functions qw(catfile);
use Getopt::Long;
use Tie::IxHash ();
use YAML        ();

use constant DEFAULTS => {
    backups       => 1,
    data_dir      => '/usr/share/dh-make-perl',
    dbflags       => ( $> == 0 ? "" : "-rfakeroot" ),
    dh            => 9,
    dist          => '',
    email         => '',
    exclude       => qr/$Dpkg::Source::Package::diff_ignore_default_regexp/,
    home_dir      => "$ENV{HOME}/.dh-make-perl",
    network       => 1,
    only          => {
        map (
            ( $_ => 1 ),
            qw(control copyright docs examples rules)
        ),
    },
    source_format => '3.0 (quilt)',
    vcs           => 'git',
    verbose       => 1,
};

use constant cpan2deb_DEFAULTS => {
    build   => 1,

    #recursive   => 1,
};

use constant cpan2dsc_DEFAULTS => {
    build_source => 1,

    #recursive   => 1,
};

sub new {
    my $class = shift;
    my $values = shift || {};

    my $cpan2deb = basename($0) eq 'cpan2deb';
    my $cpan2dsc = basename($0) eq 'cpan2dsc';

    my $self = $class->SUPER::new(
        {   %{ $class->DEFAULTS },
            (   $cpan2deb
                ? %{ $class->cpan2deb_DEFAULTS }
                : ()
            ),
            (   $cpan2dsc
                ? %{ $class->cpan2dsc_DEFAULTS }
                : ()
            ),
            cpan2deb    => $cpan2deb,
            cpan2dsc    => $cpan2dsc,
            %$values,
        },
    );

    $self->_explicitly_set( {} ) unless $self->_explicitly_set;

    return $self;
}

=head1 METHODS

=over

=item parse_command_line_options()

Parses command line options and populates object members.

=cut

sub parse_command_line_options {
    my $self = shift;

    # first get 'regular' options. commands are parsed in another
    # run below.
    Getopt::Long::Configure( qw( pass_through no_auto_abbrev no_ignore_case ) );
    my %opts;
    GetOptions( \%opts, @OPTIONS )
        or die "Error parsing command-line options\n";

    # "If no argument is given (but the switch is specified - not specifying
    # the switch will include everything), it defaults to dpkg-source's
    # default values."
    $opts{exclude} = '^$' if ! defined $opts{exclude};                 # switch not specified
                                                                       # take everything
    $opts{exclude} = $self->DEFAULTS->{'exclude'} if ! $opts{exclude}; # arguments not specified
                                                                       # back to defaults

    # handle comma-separated multiple values in --only
    $opts{only}
        = { map ( ( $_ => 1 ), split( /,/, join( ',', @{ $opts{only} } ) ) ) }
        if $opts{only};

    while ( my ( $k, $v ) = each %opts ) {
        my $field = $k;
        $field =~ s/-/_/g;
        $self->$field( $opts{$k} );
        $self->_explicitly_set->{$k} = 1;
    }

    # see what are we told to do
    %opts = ();
    Getopt::Long::Configure('no_pass_through');
    GetOptions( \%opts, @COMMANDS )
        or die "Error parsing command-line options\n";

    if (%opts) {
        my $cmd = ( keys %opts )[0];
        warn "WARNING: double dashes in front of sub-commands are deprecated\n";
        warn "WARNING: for instance, use '$cmd' instead of '--$cmd'\n";
    }
    else {
        my %cmds;
        for (@COMMANDS) {
            my $c = $_;
            $c =~ s/\|.+//;     # strip short alternatives
            $cmds{$c} = 1;
        }

        # treat the first non-option as command
        # if it looks like one
        $opts{ shift(@ARGV) } = 1
            if $ARGV[0]
                and $cmds{ $ARGV[0] };

        # by default, create source package
        $opts{make} = 1 unless %opts;
    }

    if ( scalar( keys %opts ) > 1 ) {
        die "Only one of " .
            join(', ', @COMMANDS ) . " can be specified\n";
    }

    $self->command( ( keys %opts )[0] );

    $self->verbose(1)
        if $self->command eq 'make'
            and not $self->_explicitly_set->{verbose};

    if ($self->cpan2deb) {
        @ARGV == 1 or die "cpan2deb requires exactly one non-option argument";

        $self->cpan( shift @ARGV );
        $self->_explicitly_set->{cpan} = 1;
        $self->build(1);
        $self->command('make');
    }

    if ($self->cpan2dsc) {
        @ARGV == 1 or die "cpan2dsc requires exactly one non-option argument";

        $self->cpan( shift @ARGV );
        $self->_explicitly_set->{cpan} = 1;
        $self->build_source(1);
        $self->command('make');
    }

    # Make CPAN happy, make the user happy: Be more tolerant!
    # Accept names to be specified with double-colon, dash or slash
    if ( my $name = $self->cpan ) {
        $name =~ s![/-]!::!g;
        $self->cpan($name);
    }

    $self->check_obsolete_entries;
}

=item parse_config_file()

Parse configuration file. I<config_file> member is used for location the file,
if not set, F<dh-make-perl.conf> file in I<home_dir> is used.

=cut

sub parse_config_file {
    my $self = shift;

    my $fn = $self->config_file
        || catfile( $self->home_dir, 'dh-make-perl.conf' );

    if ( -e $fn ) {
        local $@;
        my $yaml = eval { YAML::LoadFile($fn) };

        die "Error parsing $fn: $@" if $@;

        die
            "Error parsing $fn: config-file is not allowed in the configuration file"
            if $yaml->{'config-file'};

        for (@OPTIONS) {
             ( my $key = $_ ) =~ s/[!=|].*//;

            next unless exists $yaml->{$key};

            my $value = delete $yaml->{$key};
            next
                if $self->_explicitly_set
                    ->{$key};    # cmd-line opts take precedence

            ( my $opt = $key ) =~ s/-/_/g;
            $self->$opt($value);
        }

        die "Error parsing $fn: the following keys are not known:\n"
            . join( "\n", map( "  - $_", keys %$yaml ) )
            if %$yaml;

        $self->check_obsolete_entries;
    }
}

=item dump_config()

Returns a string representation of all configuration options. Suitable for
populating configuration file.

=cut

sub dump_config {
    my $self = shift;

    my %hash;
    tie %hash, 'Tie::IxHash';

    for my $opt (@OPTIONS) {
        $opt =~ s/[=!|].*//;
        ( my $field = $opt ) =~ s/-/_/g;
        $hash{$opt} = $self->$field;
    }

    local $YAML::UseVersion = 1;
    local $YAML::Stringify  = 1;

    return YAML::Dump( \%hash );
}

=item check_obsolete_entries

Checks for presence of deprecated/obsolete entries and warns/dies if any is
found.

=cut

sub check_obsolete_entries {
    my ($self) = @_;

    warn "--notest ignored. if you don't want to run the tests when building the package, add 'nocheck' to DEB_BUILD_OPTIONS\n"
        if $self->notest;

    if ( $self->dh < 8 ) {
        warn "debhelper compatibility levels before 8 are not supported.\n";
        exit(1);
    }
}

=back

=head1 COPYRIGHT & LICENSE

=over

=item Copyright (C) 2008-2010 Damyan Ivanov <dmn@debian.org>

=item Copyright (C) 2009-2010 Gregor Herrmann <gregoa@debian.org>

=item Copyright (C) 2009 Ryan Niebur <RyanRyan52@gmail.com>

=back

This program is free software; you can redistribute it and/or modify it under
the terms of the GNU General Public License version 2 as published by the Free
Software Foundation.

This program is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE.  See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with
this program; if not, write to the Free Software Foundation, Inc., 51 Franklin
Street, Fifth Floor, Boston, MA 02110-1301 USA.

=cut

1;
