package Forest::Tree::Writer;
use Moose::Role;

our $VERSION   = '0.10';
our $AUTHORITY = 'cpan:STEVAN';

has 'tree' => (
    is          => 'rw',
    isa         => 'Forest::Tree::Pure',
    required    => 1,
);

requires 'as_string';

sub write {
    my ($self, $fh) = @_;
    print $fh $self->as_string;
}

no Moose::Role; 1;

__END__

=pod

=head1 NAME

Forest::Tree::Writer - An abstract role for tree writers

=head1 DESCRIPTION

This is an abstract role for tree writers.

=head1 ATTRIBUTES

=over 4

=item I<tree>

=back

=head1 REQUIRED METHODS

=over 4

=item B<as_string>

=back

=head1 METHODS

=over 4

=item B<write ($fh)>

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
