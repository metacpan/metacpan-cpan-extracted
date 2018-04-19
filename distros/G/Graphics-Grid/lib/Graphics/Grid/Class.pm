package Graphics::Grid::Class;

# ABSTRACT: For creating classes in Graphics::Grid

use Graphics::Grid::Setup ();

our $VERSION = '0.0001'; # VERSION

sub import {
    my ( $class, @tags ) = @_;
    Graphics::Grid::Setup->_import( scalar(caller), qw(:class), @tags );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Graphics::Grid::Class - For creating classes in Graphics::Grid

=head1 VERSION

version 0.0001

=head1 SYNOPSIS

    use Graphics::Grid::Class;

=head1 DESCRIPTION

C<use Graphics::Grid::Class ...;> is equivalent of 

    use Graphics::Grid::Setup qw(:class), ...;

=head1 SEE ALSO

L<Graphics::Grid::Setup>

=head1 AUTHOR

Stephan Loyd <sloyd@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Stephan Loyd.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
