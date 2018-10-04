package Graphics::ColorNames::Windows;

# ABSTRACT: Windows color names and equivalent RGB values


use strict;
use warnings;

our $VERSION = 'v3.2.0';

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

version v3.2.0

=head1 SYNOPSIS

  require Graphics::ColorNames::Windows;

  $NameTable = Graphics::ColorNames::Windows->NamesRgbTable();
  $RgbBlack  = $NameTable->{black};

=head1 DESCRIPTION

This module defines color names and their associated RGB values used in
Microsoft Windows.

=head1 SEE ALSO

C<Graphics::ColorNames>

=head1 SOURCE

The development version is on github at L<https://github.com/robrwo/Graphics-ColorNames>
and may be cloned from L<git://github.com/robrwo/Graphics-ColorNames.git>

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://rt.cpan.org/Public/Dist/Display.html?Name=Graphics-ColorNames> or
by email to
L<bug-Graphics-ColorNames@rt.cpan.org|mailto:bug-Graphics-ColorNames@rt.cpan.org>.

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2001-2018 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
