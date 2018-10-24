package Graphics::ColorNames::HTML;

use v5.6;

# ABSTRACT: HTML color names and equivalent RGB values

# RECOMMEND PREREQ: Graphics::ColorNames


use strict;
use warnings;

our $VERSION = 'v3.3.1';

sub NamesRgbTable() {
    use integer;
    return {
        'black'   => 0x000000,
        'blue'    => 0x0000ff,
        'aqua'    => 0x00ffff,
        'lime'    => 0x00ff00,
        'fuchsia' => 0xff00ff,    # "fuscia" is incorrect but common
        'fuscia'  => 0xff00ff,    # mis-spelling...
        'red'     => 0xff0000,
        'yellow'  => 0xffff00,
        'white'   => 0xffffff,
        'navy'    => 0x000080,
        'teal'    => 0x008080,
        'green'   => 0x008000,
        'purple'  => 0x800080,
        'maroon'  => 0x800000,
        'olive'   => 0x808000,
        'gray'    => 0x808080,
        'silver'  => 0xc0c0c0,
    };
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Graphics::ColorNames::HTML - HTML color names and equivalent RGB values

=head1 VERSION

version v3.3.1

=head1 SYNOPSIS

  require Graphics::ColorNames::HTML;

  $NameTable = Graphics::ColorNames::HTML->NamesRgbTable();
  $RgbBlack  = $NameTable->{black};

=head1 DESCRIPTION

This module defines color names and their associated RGB values from the
HTML 4.0 Specification.

This module is deprecated.You should use L<Graphics::ColorNames::WWW>
instead.

=head1 KNOWN ISSUES

In versions prior to 1.1, "fuchsia" was misspelled "fuscia". This
mispelling came from un unidentified HTML specification.  It also
appears to be a common misspelling, so rather than change it, the
proper spelling was added.

=head1 SEE ALSO

L<Graphics::ColorNames>

=head1 SOURCE

The development version is on github at L<https://github.com/robrwo/Graphics-ColorNames-HTML>
and may be cloned from L<git://github.com/robrwo/Graphics-ColorNames-HTML.git>

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/robrwo/Graphics-ColorNames-HTML/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

=head1 COPYRIGHT AND LICENSE


Robert Rothenberg has dedicated the work to the Commons by waiving all of his
or her rights to the work worldwide under copyright law and all related or
neighboring legal rights he or she had in the work, to the extent allowable by
law.

Works under CC0 do not require attribution. When citing the work, you should
not imply endorsement by the author.

=cut
