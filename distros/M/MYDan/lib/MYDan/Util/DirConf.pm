package MYDan::Util::DirConf;

=head1 NAME

MYDan::Util::DirConf - Interface module: directory configuration with a YAML file.

=head1 SYNOPSIS

 use base MYDan::Util::DirConf;

 sub define { qw( log code ) };

 my $conf = MYDan::Util::DirConf->new( '/conf/file' );
 my $conf->make() if ! $conf->check;

 my $conf = $conf->path(); ## HASH ref
 my $logdir = $conf->path( 'log' );
 my $logfile = $conf->path( log => 'foobar.log' );

=cut
use strict;
use warnings;

use Cwd;
use Carp;
use YAML::XS;
use File::Spec;
use FindBin qw( $Bin $RealBin $Script $RealScript );

sub new
{
    my ( $class, $conf, ) = splice @_;
    my ( %conf, %path ) = ( abscent => {}, path => {} );

    confess "undefined config" unless $conf;
    $conf = readlink $conf if -l $conf;

    my $error = "invalid config $conf";
    confess "$error: not a regular file" unless -f $conf;

    eval { $conf = YAML::XS::LoadFile( $conf ) };

    confess "$error: $@" if $@;
    confess "$error: not HASH" if ref $conf ne 'HASH';

    for ( my $loop = keys %$conf; $loop; )
    {
        for ( $loop = 0; my ( $name, $path ) = each %$conf; )
        {
            $conf->{$name} = $path = $class->macro( $path );
            $loop = $path{$name} = delete $conf->{$name} if $path !~ /\$/;
        }

        while ( my ( $name, $path ) = each %path )
        {
            for my $dir ( keys %$conf )
            {
                $conf->{$dir} =~ s/\$$name\b/$path/g;
                $conf->{$dir} =~ s/\$\{$name\}/$path/g;
            }
        }
    }

    confess "$error: unresolved variable" if %$conf;

    my $self = bless \%conf, ref $class || $class;

    map { confess "$error: $_ not defined"
        unless $conf{path}{$_} = Cwd::abs_path( $path{$_} ) } $self->define();

    return $self;
}

=head1 METHODS

=head3 check()

Inspect directories. Returns true if all directories exist, false otherwise.

=cut
sub check
{
    my $self = shift;
    my %dir = reverse %{ $self->{path} };

    map { delete $dir{$_} if -d $_ || -l $_ } keys %dir;
    $self->{abscent} = { reverse %dir };
    return ! keys %dir;
}

=head3 make()

Set up directories. Returns invoking object.

=cut
sub make
{
    my $self = shift;

    map { confess "cannot mkdir $_" if system( "rm -f $_ && mkdir -p $_" ) }
        values %{ $self->{abscent} } unless $self->check();

    $self->{abscent} = {};
    return $self;
}

=head3 path( name => @name )

Join a known path I<name> with @name. See File::Spec->join().

=cut
sub path
{
    my ( $self, $name ) = splice @_, 0, 2;
    my $path = $self->{path};
    return $path unless defined $name;
    return $path unless ( $path = $path->{$name} ) && @_;
    File::Spec->join( $path, @_ );
}

=head3 macro( $path )

Replace $RealBin and $Bin in $path

=cut
sub macro
{
    my ( $self, $path ) = splice @_;
    if ( $path )
    {
        $path =~ s/\$Bin\b/$Bin/g; $path =~ s/\$RealScript\b/$RealScript/g;
        $path =~ s/\$\{Bin\}/$Bin/g; $path =~ s/\$\{RealScript\}/$RealScript/g;
        $path =~ s/\$Script\b/$Script/g; $path =~ s/\$RealBin\b/$RealBin/g;
        $path =~ s/\$\{Script\}/$Script/g; $path =~ s/\$\{RealBin\}/$RealBin/g;
    }
    return $path;
}

1;
