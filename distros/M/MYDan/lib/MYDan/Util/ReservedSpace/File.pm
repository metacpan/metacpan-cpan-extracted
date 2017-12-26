package MYDan::Util::ReservedSpace::File;

=head1 NAME

MYDan::ReservedSpace::File

=head1 SYNOPSIS

 use MYDan::ReservedSpace::File;

 MYDan::ReservedSpace::File::dump( 'path/file', \%hash );
 my $hash = MYDan::ReservedSpace::File::load( 'path/file' );

 
=cut

use strict;
use warnings;
use Carp;
use Fcntl qw( :flock );
use MYDan;
use YAML::XS;

sub dump
{
    die "file undef" unless my $file = shift;
    if( $ENV{UseReservedSpace} )
    {
       die "no ReservedSpace" unless _space( $file );
    }
    YAML::XS::DumpFile( "$MYDan::PATH/tmp/$file", @_ );
}

sub load
{
    die "file undef" unless my $file = shift;
    YAML::XS::LoadFile( "$MYDan::PATH/tmp/$file" );
}

sub unlink
{
    die "file undef" unless my $file = shift;
    unlink "$MYDan::PATH/tmp/$file";
}

sub filename
{
    die "file undef" unless my $file = shift;
    return "$MYDan::PATH/tmp/$file";
}

sub _space
{

    my ( $file, $fh ) = shift;

    open( $fh, ">>", "$MYDan::PATH/var/ReservedSpace/lock" ) or die "Can't open lock: $!";

    die "lock fail" unless flock $fh, LOCK_EX | LOCK_NB;

    for ( glob "$MYDan::PATH/var/ReservedSpace/*" )
    {
        next unless $_ =~ /\/(\d+)$/;
        my $id = $1;
        next unless _rsok( $_ );
        die "ln fail" if system( "ln '$MYDan::PATH/var/ReservedSpace/$id' '$MYDan::PATH/tmp/$file'" );
        die "clean fail" if system( "echo > '$MYDan::PATH/tmp/$file'" );
        flock $fh, LOCK_UN;
        close $fh;
        return 1;
    }

    flock $fh, LOCK_UN;
    close $fh;

    return 0;
}

sub _rsok
{
    my $file = shift;
    return ( $file && -f $file && ( stat $file )[3] == 1 ) ? 1 : 0;
}

1;
