package Forest::Tree::Roles::JSONable;
use Moose::Role;

our $VERSION   = '0.10';
our $AUTHORITY = 'cpan:STEVAN';

requires 'as_json';

no Moose::Role; 1;

__END__

=pod

=head1 NAME

Forest::Tree::Roles::JSONable - An abstract role for providing JSON serialization

=head1 DESCRIPTION

This is just an abstract role for trees capable of JSON serialization.

=head1 REQUIRED METHODS

=over 4

=item B<as_json (?%options)>

Return a JSON string of the invocant. Takes C<%options>
parameter to specify the way the tree is to be dumped.

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
