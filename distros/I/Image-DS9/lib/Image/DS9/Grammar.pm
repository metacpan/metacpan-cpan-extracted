package Image::DS9::Grammar;

# ABSTRACT: Grammar definitions
use v5.10;
use strict;
use warnings;

our $VERSION = 'v1.0.0';

use Safe::Isa;

use Image::DS9::Util 'is_TODO';
use Image::DS9::Grammar::V8_5 '_grammar';
use Exporter::Shiny 'grammar';

#
# This file is part of Image-DS9
#
# This software is Copyright (c) 2017 by Smithsonian Astrophysical Observatory.
#
# This is free software, licensed under:
#
#   The GNU General Public License, Version 3, June 2007
#

sub grammar {
    my $entry = _grammar( @_ );
    # $entry may be the entire grammar or just the entry for a single
    # command.  Either way, the following statement works.
    return is_TODO( $entry ) ? undef : $entry;
}

1;

__END__

=pod

=for :stopwords Diab Jerius Smithsonian Astrophysical Observatory

=head1 NAME

Image::DS9::Grammar - Grammar definitions

=head1 VERSION

version v1.0.0

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
