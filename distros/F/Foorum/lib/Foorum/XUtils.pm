package Foorum::XUtils;

use strict;
use warnings;

our $VERSION = '1.001000';

use YAML::XS qw/LoadFile/;     # config
use TheSchwartz::Moosified;    # theschwartz
use DBI;
use Template;                  # template
use Template::Stash::XS;
use base 'Exporter';
use vars qw/@EXPORT_OK $base_path $config $cache $tt2 $theschwartz/;
@EXPORT_OK = qw/
    base_path
    config
    cache
    tt2
    theschwartz
    /;

use File::Spec;
use Cwd qw/abs_path/;
my ( undef, $path ) = File::Spec->splitpath(__FILE__);
$path = abs_path($path);

# XXX? since make test copy files to blib
$path =~ s/[\\\/]blib($|\\|\/)/$1/isg;

sub base_path {
    return $base_path if ($base_path);
    $base_path = abs_path( File::Spec->catdir( $path, '..', '..' ) );
    return $base_path;
}

sub config {

    return $config if ($config);

    $config
        = LoadFile( File::Spec->catfile( $path, '..', '..', 'foorum.yml' ) );
    if ( -e File::Spec->catfile( $path, '..', '..', 'foorum_local.yml' ) ) {
        my $extra_config = LoadFile(
            File::Spec->catfile( $path, '..', '..', 'foorum_local.yml' ) );
        $config = { %$config, %$extra_config };
    }
    if ( $ENV{TEST_FOORUM} ) {

        # use SQLite and FileCache for test
        my $sqlite_file
            = File::Spec->catfile( $path, '..', '..', 't', 'lib', 'Foorum',
            'foorum.db' );
        $config->{dsn}      = "dbi:SQLite:dbname=$sqlite_file";
        $config->{dsn_user} = '';
        $config->{dsn_pwd}  = '';
        $config->{cache}    = {
            backends => {
                default => {
                    class              => 'Cache::FileCache',
                    namespace          => 'FoorumTest',
                    default_expires_in => 300
                }
            }
        };
    }

    return $config;
}

sub cache {

    return $cache if ($cache);
    $config = config() unless ($config);

    my %params = %{ $config->{cache}{backends}{default} };
    my $class  = delete $params{class};

    eval("use $class;");    ## no critic (ProhibitStringyEval)
    unless ($@) {
        $cache = $class->new( \%params );
    }

    return $cache;
}

sub tt2 {

    return $tt2 if ($tt2);
    $config    = config()    unless ($config);
    $base_path = base_path() unless ($base_path);

    $tt2 = Template->new(
        {   INCLUDE_PATH => [ File::Spec->catdir( $base_path, 'templates' ) ],
            PRE_CHOMP    => 1,
            POST_CHOMP   => 1,
            STASH        => Template::Stash::XS->new,
        }
    );
    return $tt2;
}

sub theschwartz {

    return $theschwartz if ($theschwartz);
    $config = config() unless ($config);

    my $dbh = DBI->connect(
        $config->{theschwartz_dsn},
        $config->{theschwartz_user} || $config->{dsn_user},
        $config->{theschwartz_pwd}  || $config->{dsn_pwd},
        { PrintError => 1, RaiseError => 1 }
    );
    $theschwartz = TheSchwartz::Moosified->new( databases => [$dbh] );

    return $theschwartz;
}

1;
__END__

=pod

=head1 NAME

Foorum::XUtils - Utils for cron

=head1 FUNCTIONS

=over 4

=item base_path

the same as $c->config->{home} or $c->path_to

=item config

the same as $c->config expect ->{home}

=item cache

the same as $c->cache

=item tt2

generally like $c->view('TT'), yet a bit different

=item theschwartz

L<TheSchwartz::Moosified> ->new with correct database from $config

=back

=head1 AUTHOR

Fayland Lam <fayland at gmail.com>

=cut
