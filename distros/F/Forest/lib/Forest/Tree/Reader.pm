package Forest::Tree::Reader;
use Moose::Role;

our $VERSION   = '0.10';
our $AUTHORITY = 'cpan:STEVAN';

with 'Forest::Tree::Loader';

requires 'read';

# satisfy the Loader interface here ...
sub load {
    my $self = shift;
    $self->read(@_);
}

no Moose::Role; 1;

__END__

=pod

=head1 NAME

Forest::Tree::Reader - An abstract role for top down tree reader

=head1 DESCRIPTION

B<This role should generally not be used, it has been largely superseded by Forest::Tree::Builder>.

This is an abstract role for tree readers.

Tree readers are also Tree loaders, that is why this module
also does the L<Forest::Tree::Loader> role.

=head1 ATTRIBUTES

=over 4

=item I<tree>

=back

=head1 REQUIRED METHODS

=over 4

=item B<read>

=back

=head1 METHODS

=over 4

=item B<load>

This satisfies the L<Forest::Tree::Loader> interface.

=back

=head1 BUGS

All complex software has bugs lurking in it, and this module is no
exception. If you find a bug please either email me, or add the bug
to cpan-RT.

=head1 AUTHOR

Stevan Little E<lt>stevan.little@iinteractive.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2008-2014 Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
