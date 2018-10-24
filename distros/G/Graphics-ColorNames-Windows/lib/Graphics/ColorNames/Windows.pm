package Graphics::ColorNames::Windows;

use v5.6;

# ABSTRACT: Windows color names and equivalent RGB values

# RECOMMEND PREREQ: Graphics::ColorNames


use strict;
use warnings;

our $VERSION = 'v3.3.1';

sub NamesRgbTable() {
    use integer;
    return {
        'black'       => 0x000000,
        'blue'        => 0x0000ff,
        'cyan'        => 0x00ffff,
        'green'       => 0x00ff00,
        'magenta'     => 0xff00ff,
        'red'         => 0xff0000,
        'yellow'      => 0xffff00,
        'white'       => 0xffffff,
        'darkblue'    => 0x000080,
        'darkcyan'    => 0x008080,
        'darkgreen'   => 0x008000,
        'darkmagenta' => 0x800080,
        'darkred'     => 0x800000,
        'darkyellow'  => 0x808000,
        'darkgray'    => 0x808080,
        'lightgray'   => 0xc0c0c0,
    };
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Graphics::ColorNames::Windows - Windows color names and equivalent RGB values

=head1 VERSION

version v3.3.1

=head1 SYNOPSIS

  require Graphics::ColorNames::Windows;

  $NameTable = Graphics::ColorNames::Windows->NamesRgbTable();
  $RgbBlack  = $NameTable->{black};

=head1 DESCRIPTION

This module defines color names and their associated RGB values used in
Microsoft Windows.

=head1 SEE ALSO

L<Graphics::ColorNames>

L<Graphics::ColorNames::IE>

=head1 SOURCE

The development version is on github at L<https://github.com/robrwo/Graphics-ColorNames-Windows>
and may be cloned from L<git://github.com/robrwo/Graphics-ColorNames-Windows.git>

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/robrwo/Graphics-ColorNames-Windows/issues>

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
