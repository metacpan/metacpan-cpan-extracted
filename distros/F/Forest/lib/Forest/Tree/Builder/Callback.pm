package Forest::Tree::Builder::Callback;
use Moose::Role;

our $VERSION   = '0.10';
our $AUTHORITY = 'cpan:STEVAN';

with 'Forest::Tree::Builder' => { -excludes => [qw(create_new_subtree)] };

has new_subtree_callback => (
    isa => "CodeRef|Str",
    is  => "ro",
    required => 1,
    default => "Forest::Tree::Constructor::create_new_subtree",
);

sub create_new_subtree {
    my ( $self, @args ) = @_;

    my $method = $self->new_subtree_callback;

    $self->$method(@args);
}

no Moose::Role; 1;

__END__

=pod

=head1 NAME

Forest::Tree::Builder::Callback - A Forest tree builder with a callback for subtree construction

=head1 DESCRIPTION

TODO

=head1 BUGS

All complex software has bugs lurking in it, and this module is no
exception. If you find a bug please either email me, or add the bug
to cpan-RT.

=head1 AUTHOR

Yuval Kogman

=head1 COPYRIGHT AND LICENSE

Copyright 2008-2014 Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut