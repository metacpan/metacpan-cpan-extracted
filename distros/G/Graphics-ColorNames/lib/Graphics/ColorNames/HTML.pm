package Graphics::ColorNames::HTML;

# ABSTRACT: HTML color names and equivalent RGB values


use strict;
use warnings;

our $VERSION = 'v3.2.1';

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

version v3.2.1

=head1 SYNOPSIS

  require Graphics::ColorNames::HTML;

  $NameTable = Graphics::ColorNames::HTML->NamesRgbTable();
  $RgbBlack  = $NameTable->{black};

=head1 DESCRIPTION

This module defines color names and their associated RGB values from the
HTML 4.0 Specification.

This module is deprecated, and will be split into a separate
distribution.  You should use L<Graphics::ColorNames::WWW> instead.

=head1 KNOWN ISSUES

In versions prior to 1.1, "fuchsia" was misspelled "fuscia". This
mispelling came from un unidentified HTML specification.  It also
appears to be a common misspelling, so rather than change it, the
proper spelling was added.

=head1 SEE ALSO

L<Graphics::ColorNames>

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
