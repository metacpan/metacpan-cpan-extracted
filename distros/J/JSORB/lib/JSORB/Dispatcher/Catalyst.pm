package JSORB::Dispatcher::Catalyst;
use Moose;
use Moose::Util::TypeConstraints;

our $VERSION   = '0.04';
our $AUTHORITY = 'cpan:STEVAN';

class_type 'Catalyst' unless find_type_constraint('Catalyst');

extends 'JSORB::Dispatcher::Path';
   with 'JSORB::Dispatcher::Traits::WithContext';

has '+context_class' => (default => 'Catalyst');

__PACKAGE__->meta->make_immutable;

no Moose; no Moose::Util::TypeConstraints; 1;

__END__

=pod

=head1 NAME

JSORB::Dispatcher::Catalyst - A dispatcher for use with Catalyst

=head1 DESCRIPTION

All this basically does it apply the L<JSORB::Dispatcher::Traits::WithContext>
to L<JSORB::Dispatcher::Path> and tell it to use the L<Catalyst> context
class. 

=head1 BUGS

All complex software has bugs lurking in it, and this module is no 
exception. If you find a bug please either email me, or add the bug
to cpan-RT.

=head1 AUTHOR

Stevan Little E<lt>stevan.little@iinteractive.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2008-2010 Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
