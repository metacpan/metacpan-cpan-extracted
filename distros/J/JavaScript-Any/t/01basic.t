=pod

=encoding utf-8

=head1 PURPOSE

Test that JavaScript::Any compiles and runs.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2017 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.


=cut

use strict;
use warnings;
use Test::More;

use JavaScript::Any qw(jseval);

is(
	jseval('1 + 2'),
	3,
);

my $ctx = JavaScript::Any->new_context;

# string vs number depends on engine!
$ctx->define('x' => 3);
$ctx->define('y' => sub { 4 });

is(
	$ctx->eval('parseInt(x) + parseInt(y())'),
	7,
);

done_testing;

