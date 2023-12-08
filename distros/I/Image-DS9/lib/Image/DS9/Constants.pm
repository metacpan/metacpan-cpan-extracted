package Image::DS9::Constants;

# ABSTRACT:  predefined constants

use v5.10;
use strict;
use warnings;

require Image::DS9::Constants::V0;

our $VERSION = 'v1.0.1';

sub import {
    goto &Image::DS9::Constants::V0::import;
}


#
# This file is part of Image-DS9
#
# This software is Copyright (c) 2017 by Smithsonian Astrophysical Observatory.
#
# This is free software, licensed under:
#
#   The GNU General Public License, Version 3, June 2007
#

1;

__END__

=pod

=for :stopwords Diab Jerius Smithsonian Astrophysical Observatory

=head1 NAME

Image::DS9::Constants - predefined constants

=head1 VERSION

version v1.0.1

=head1 SYNOPSIS

  # import all of the constants
  use Image::DS9::Constants;

=head1 DESCRIPTION

This module is now a front end to L<Image::DS9::Constants::V0>. It
eventually will be a front end to L<Image::DS9::Constants::V1>, as the
L<Image::DS9::Constants::V0/V0> version is now deprecated.

Please migrate your code to L<Image::DS9::Constants::V1>.

=head1 SUPPORT

=head2 Bugs

Please report any bugs or feature requests to bug-image-ds9@rt.cpan.org  or through the web interface at: L<https://rt.cpan.org/Public/Dist/Display.html?Name=Image-DS9>

=head2 Source

Source is available at

  https://gitlab.com/djerius/image-ds9

and may be cloned from

  https://gitlab.com/djerius/image-ds9.git

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<Image::DS9|Image::DS9>

=back

=head1 AUTHOR

Diab Jerius <djerius@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017 by Smithsonian Astrophysical Observatory.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
