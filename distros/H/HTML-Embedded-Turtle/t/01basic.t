=pod

=encoding utf-8

=head1 PURPOSE

Test HTML::Embedded::Turtle compiles and offers the correct API.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010-2011, 2013 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;
use Test::More tests => 7;

BEGIN { use_ok('HTML::Embedded::Turtle') };
can_ok('HTML::Embedded::Turtle', 'VERSION');
can_ok('HTML::Embedded::Turtle', 'AUTHORITY');
ok(HTML::Embedded::Turtle->AUTHORITY('cpan:TOBYINK'), 'Correct AUTHORITY');
can_ok('HTML::Embedded::Turtle', 'new');
ok(my $obj = HTML::Embedded::Turtle->new('','http://example.com/'), 'Object can be instantiated.');
ok($obj->AUTHORITY('cpan:TOBYINK'), 'Correct AUTHORITY');
