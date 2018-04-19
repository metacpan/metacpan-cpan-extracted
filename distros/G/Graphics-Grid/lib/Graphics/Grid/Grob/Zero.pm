package Graphics::Grid::Grob::Zero;

# ABSTRACT: Empty grob with minimal size

use Graphics::Grid::Class;

with qw(
  Graphics::Grid::Grob
);

our $VERSION = '0.0001'; # VERSION

method _build_elems() { 0 }

method draw($driver) { }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Graphics::Grid::Grob::Zero - Empty grob with minimal size

=head1 VERSION

version 0.0001

=head1 SYNOPSIS

    use Graphics::Grid::Grob::Zero;
    my $grob = Graphics::Grid::Grob::Zero->new();

    # or use the function interface
    use Graphics::Grid::Functions qw(:all);
    my $grob = zero_grob();

=head1 DESCRIPTION

A "zero" grob is even simpler than a "null" grob.

=head1 SEE ALSO

L<Graphics::Grid::Grob>

=head1 AUTHOR

Stephan Loyd <sloyd@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Stephan Loyd.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
