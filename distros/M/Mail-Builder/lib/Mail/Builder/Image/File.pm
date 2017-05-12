# ============================================================================
package Mail::Builder::Image::File;
# ============================================================================

use Moose;
extends qw(Mail::Builder::Image);

use Carp;

our $VERSION = $Mail::Builder::VERSION;

before BUILDARGS => sub{
    carp '<Mail::Builder::Image::File> is deprecated, use <Mail::Builder::Image> instead';
};

no Moose;
__PACKAGE__->meta->make_immutable;


1;