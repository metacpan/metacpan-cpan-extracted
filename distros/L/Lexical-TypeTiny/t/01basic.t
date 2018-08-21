=pod

=encoding utf-8

=head1 PURPOSE

Test that Lexical::TypeTiny compiles and works.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2018 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.


=cut

use strict;
use warnings;
use Test::More;
use Test::Fatal;

use Types::Standard qw(Int);
use Lexical::TypeTiny;

my Int $x = 1;

$x++;

my $e = exception { $x += 0.1 };

like($e, qr/type constraint/);
is($x, '2.1');  # behaviour may change in a future version

done_testing;

