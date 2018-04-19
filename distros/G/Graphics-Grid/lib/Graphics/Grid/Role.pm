package Graphics::Grid::Role;

# ABSTRACT: For creating roles in Graphics::Grid

use Graphics::Grid::Setup ();

our $VERSION = '0.0001'; # VERSION

sub import {
    my ( $class, @tags ) = @_;
    Graphics::Grid::Setup->_import( scalar(caller), qw(:role), @tags );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Graphics::Grid::Role - For creating roles in Graphics::Grid

=head1 VERSION

version 0.0001

=head1 SYNOPSIS

    use Graphics::Grid::Role;

=head1 DESCRIPTION

C<use Graphics::Grid::Role ...;> is equivalent of 

    use Graphics::Grid::Setup qw(:role), ...;

=head1 SEE ALSO

L<Graphics::Grid::Setup>

=head1 AUTHOR

Stephan Loyd <sloyd@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Stephan Loyd.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
