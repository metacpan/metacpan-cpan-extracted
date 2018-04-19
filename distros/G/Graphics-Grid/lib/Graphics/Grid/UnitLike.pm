package Graphics::Grid::UnitLike;

# ABSTRACT: Role for unit-like classes in Graphics::Grid

use Graphics::Grid::Role;

our $VERSION = '0.0001'; # VERSION

use Graphics::Grid::Types qw(:all);


requires 'elems';


requires 'at';


requires 'stringify';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Graphics::Grid::UnitLike - Role for unit-like classes in Graphics::Grid

=head1 VERSION

version 0.0001

=head1 DESCRIPTION

This role describes something that can be used as unit-value.

=head1 METHODS

=head2 elems

Number of effective values in the object.

=head2 at

=head2 stringify

=head1 SEE ALSO

L<Graphics::Grid>

=head1 AUTHOR

Stephan Loyd <sloyd@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Stephan Loyd.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
