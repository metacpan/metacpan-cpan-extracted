package Graphics::Grid::HasGPar;

# ABSTRACT: Role for graphics parameters (gpar) in Graphics::Grid

use Graphics::Grid::Role;

our $VERSION = '0.0001'; # VERSION

use Graphics::Grid::GPar;
use Graphics::Grid::Types qw(:all);



has gp => (
    is  => 'ro',
    isa => GPar,
    coerce => 1,
    default => sub { Graphics::Grid::GPar->new() },
);

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Graphics::Grid::HasGPar - Role for graphics parameters (gpar) in Graphics::Grid

=head1 VERSION

version 0.0001

=head1 DESCRIPTION

This role describes something that has the graphical parameters.

=head1 ATTRIBUTES

=head2 gp

An object of Graphics::Grid::GPar. Default is an empty gpar object.

=head1 SEE ALSO

L<Graphics::Grid>

L<Graphics::Grid::GPar>

=head1 AUTHOR

Stephan Loyd <sloyd@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Stephan Loyd.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
