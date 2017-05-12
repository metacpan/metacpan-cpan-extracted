use strict;
use warnings FATAL => 'all';
use Test::More tests => 3;

BEGIN { use_ok('List::MapMulti') };
my $iter = new_ok 'List::MapMulti::Iterator' => [ [1] ];
can_ok $iter => qw(next current next_indices current_indices);

=head1 PURPOSE

Checks that the module loads; that the iterator class can be instantiated; and
that an iterator object can do the following methods:

=over

=item *

C<next>

=item *

C<current>

=item *

C<next_indices>

=item *

C<current_indices>

=back

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2012 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

