# ============================================================================
package Mail::Builder::Image::Data;
# ============================================================================

use namespace::autoclean;
use Moose;
extends qw(Mail::Builder::Image);

use Carp;

our $VERSION = $Mail::Builder::VERSION;

before BUILDARGS => sub{
    carp '<Mail::Builder::Image::Data> is deprecated, use <Mail::Builder::Image> instead';
};

__PACKAGE__->meta->make_immutable;

1;