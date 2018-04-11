use strict;

package HTML::FormFu::Role::HasParent;
$HTML::FormFu::Role::HasParent::VERSION = '2.06';
use Moose::Role;

sub BUILD {
    my ( $self, $args ) = @_;

    # Moose's new() only handles attributes - not methods

    if ( exists $args->{parent} ) {
        $self->parent( delete $args->{parent} );
    }

    return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

HTML::FormFu::Role::HasParent

=head1 VERSION

version 2.06

=head1 AUTHOR

Carl Franks <cpan@fireartist.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Carl Franks.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
