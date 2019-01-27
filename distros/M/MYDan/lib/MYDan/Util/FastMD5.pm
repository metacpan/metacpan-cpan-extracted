package MYDan::Util::FastMD5;

=head1 NAME

MYDan::Util::FastMD5

=cut
use warnings;
use strict;

use Digest::MD5;
use MYDan::Util::OptConf;
use Fcntl qw(:flock SEEK_END);

our $threshold; 
BEGIN{ 
    $threshold = MYDan::Util::OptConf->load()->dump('util')->{fastmd5} || 1099511627776; 
};

=head1 SYNOPSIS

 use MYDan::Util::FastMD5;
 MYDan::Util::FastMD5->hexdigest( '/path/file' );

=head1 Methods

=head3 hexdigest( $file )

=cut

sub hexdigest
{
    my ( $class, $file ) = splice @_;

    my ( $len, $md5 ) = 1048576;

    open my $H, '<', $file or die "Can't open '$file': $!";

    my $size = ( stat $file )[7];
    if( $size > $threshold && $size > $len * 2 )
    {
         my ( $head, $tail );

         die "read fail" unless $len eq sysread $H, $head, $len;
         die "seek fail" unless seek $H, -$len, SEEK_END;
         die "read fail" unless $len eq sysread $H, $tail, $len;

         $md5 = Digest::MD5->new->add( join ':', $size, $head, $tail )->hexdigest;
    }
    else { $md5 = Digest::MD5->new()->addfile( $H )->hexdigest(); }

    close $H;

    return $md5;
}

1;
