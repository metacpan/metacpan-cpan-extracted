#   ------------------------------------------------------------------------------------------------
#
#   file: ex/ManifestWithFileSize.pm
#
#   This file is part of perl-Dist-Zilla-Plugin-Manifest-Write.
#
#   ------------------------------------------------------------------------------------------------
#
#   This module is used as synopsis in `Dist/Zilla/Plugin/Manifest/Write.pm`. Heading and trailing
#   comments are stripped. Having this module in a separate file allows us to test it, see
#   `t/examples.t`.
#

package ManifestWithFileSize;

use Moose;
use namespace::autoclean;
extends 'Dist::Zilla::Plugin::Manifest::Write';
our $VERSION = '0.007';

#   Overload any method or modify it with all the Moose power, e. g.:
around _file_comment => sub {
    my ( $orig, $self, $file ) = @_;
    my $comment = $self->$orig( $file );
    if ( $file->name ne $self->manifest ) { # Avoid infinite recursion.
        $comment .= sprintf( ' (%d bytes)', length( $file->encoded_content ) );
    };
    return $comment;
};

__PACKAGE__->meta->make_immutable;
1;

# end of file #
