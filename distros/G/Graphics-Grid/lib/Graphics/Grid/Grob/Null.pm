package Graphics::Grid::Grob::Null;

# ABSTRACT: Empty grob

use Graphics::Grid::Class;

with qw(
  Graphics::Grid::Grob
  Graphics::Grid::Positional
);

our $VERSION = '0.0001'; # VERSION

method _build_elems() { 0 }

method draw($driver) { }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Graphics::Grid::Grob::Null - Empty grob

=head1 VERSION

version 0.0001

=head1 SYNOPSIS

    use Graphics::Grid::Grob::Null;
    my $grob = Graphics::Grid::Grob::Null->new();

    # or use the function interface
    use Graphics::Grid::Functions qw(:all);
    my $grob = null_grob();

=head1 DESCRIPTION

This class represents an null grob which has zero width, zero height, and
draw nothing. It can be used as a place-holder or as an invisible reference
point for other drawing.

=head1 SEE ALSO

L<Graphics::Grid::Grob>

=head1 AUTHOR

Stephan Loyd <sloyd@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Stephan Loyd.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
