package MYDan::Util::Screen;

use warnings;
use strict;
use Carp;

=head1 SYNOPSIS

 use MYDan::Util::Screen;

 MYDan::Util::Screen->check( );

 MYDan::Util::Screen->in( 'sessionname' );

=cut

sub check
{
    my $class = shift;
    $ENV{TERM} && $ENV{TERM} ne 'screen' ? 0 : 1;
}

#sub screen
#{
#    my ( $class, $sn ) = @_;
#    confess "screen fail\n" 
#        unless exec sprintf 'screen %s', $sn ? "-S $sn" : "";
#}
#

1;
