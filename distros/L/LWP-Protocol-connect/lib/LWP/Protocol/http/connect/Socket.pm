package LWP::Protocol::http::connect::Socket;

use strict;
use warnings;

our $VERSION = '6.09'; # VERSION

require LWP::Protocol::http;
use LWP::Protocol::connect::Socket::Base;
our @ISA = qw(LWP::Protocol::connect::Socket::Base LWP::Protocol::http::Socket);

1;

