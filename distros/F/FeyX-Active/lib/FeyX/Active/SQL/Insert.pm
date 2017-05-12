package FeyX::Active::SQL::Insert;
use Moose;

our $VERSION   = '0.03';
our $AUTHORITY = 'cpan:STEVAN';

extends 'Fey::SQL::Insert';
   with 'FeyX::Active::SQL';

__PACKAGE__->meta->make_immutable;

no Moose; 1;

__END__

=pod

=head1 NAME

FeyX::Active::SQL::Insert - An active INSERT statement

=head1 DESCRIPTION

This is a subclass of L<Fey::SQL::Insert> that also consumes
the L<FeyX::Active::SQL> role. Please refer to both of those
modules for more infomation.

=head1 BUGS

All complex software has bugs lurking in it, and this module is no
exception. If you find a bug please either email me, or add the bug
to cpan-RT.

=head1 AUTHOR

Stevan Little E<lt>stevan.little@iinteractive.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2009-2010 Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
