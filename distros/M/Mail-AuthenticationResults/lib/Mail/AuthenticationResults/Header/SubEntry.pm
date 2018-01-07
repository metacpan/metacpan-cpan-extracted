package Mail::AuthenticationResults::Header::SubEntry;
require 5.010;
use strict;
use warnings;
our $VERSION = '1.20171230'; # VERSION
use Carp;

use base 'Mail::AuthenticationResults::Header::Base';

sub HAS_KEY{ return 1; }
sub HAS_VALUE{ return 1; }
sub HAS_CHILDREN{ return 1; }

sub ALLOWED_CHILDREN {
    my ( $self, $child ) = @_;
    return 1 if ref $child eq 'Mail::AuthenticationResults::Header::Comment';
    return 1 if ref $child eq 'Mail::AuthenticationResults::Header::Version';
    return 0;
}

1;
