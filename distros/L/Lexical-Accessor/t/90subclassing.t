=pod

=encoding utf-8

=head1 PURPOSE

Test that Lexical::Accessor can be subclassed to enable other
interesting accessor generators to build upon it.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2014 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.


=cut

use strict;
use warnings;
use Test::More;

BEGIN {
	package Local::MyAccessor;
	
	use base qw(Sub::Accessor::Small);
	our @EXPORT = qw( has );
	$INC{'Local/MyAccessor.pm'} = __FILE__;
	
	# Store in a hashref instead of inside-out.
	sub inline_access {
		my $me = shift;
		my $selfvar = shift || '$_[0]';
		sprintf(
			q[ %s->{%s} ],
			$selfvar,
			$me->{slot},
		);
	}
};

BEGIN {
	package Local::MyClass;
	use Local::MyAccessor;
	
	sub new {
		bless {}, shift;
	}
	
	has foo => (accessor => 'foo');
	has bar => (accessor => 'bar');
};

my $obj = Local::MyClass->new;

$obj->foo(42);
$obj->bar(666);

is($obj->foo, 42);
is($obj->bar, 666);

is_deeply(
	+{ %$obj },
	+{ foo => 42, bar => 666 },
);

done_testing;
