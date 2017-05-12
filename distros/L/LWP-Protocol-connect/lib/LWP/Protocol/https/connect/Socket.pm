package LWP::Protocol::https::connect::Socket;

use strict;
use warnings;

our $VERSION = '6.09'; # VERSION

require LWP::Protocol::https;
use IO::Socket::SSL;
use LWP::Protocol::connect::Socket::Base;
our @ISA = qw(LWP::Protocol::connect::Socket::Base IO::Socket::SSL LWP::Protocol::https::Socket);

sub new {
    my $class = shift;
    my %args = @_;
    my $conn = $class->_proxy_connect( \%args );

    unless ($class->start_SSL($conn, %args)) {
        my $status = 'error while setting up ssl connection';
        if( $@ ) {
            $status .= " (".$@.")";
        }
        die($status);
    }
    
    $conn->http_configure( \%args );
    return $conn;
}

1;
