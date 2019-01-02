package MYDan::Util::Debug;

=head1 NAME

MYDan::Util::Debug

=cut
use warnings;
use strict;

=head1 SYNOPSIS

 use MYDan::Util::Debug;

 MYDan::Util::Debug->isdebug( 1 );

=head1 Methods

=head3 isdebug( $level )

=cut

sub isdebug
{
    my ( $class, $level ) = splice @_;
    $level = 1 unless $level && $level =~ /^\d+$/;

    my $env = $ENV{MYDan_DEBUG};
    $env = 0 unless $env && $env =~ /^\d+$/;

    return $env >= $level ? 1 :  0;
}


1;
