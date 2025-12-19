=pod

=encoding utf-8

=head1 PURPOSE

Test implementation of triggers.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2025 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use Test2::V0;

my ( @FOO, @BAR );

BEGIN {
	package Local::MyClass;
	use Marlin
		foo => {
			is       => 'rw',
			trigger  => sub {
				my ( $self, @args ) = @_;
				push @FOO, \@args;
				$_[1] = $args[0] + 1; # $_[1] is an alias to the slot
			},
		},
		bar => {
			is       => 'rw',
			trigger  => 'trigger_bar',
		};
	
	sub trigger_bar {
		my ( $self, @args ) = @_;
		push @BAR, \@args;
		$self->bar( $args[0] + 1 );
	}
};

my $obj = Local::MyClass->new( foo => 9 );
is( $obj->foo, 10 );
is( $obj->bar, undef );
$obj->foo( 1 );
is $obj->foo, 2;
$obj->foo( 41 );
is $obj->foo, 42;
$obj->bar( 1 );
is $obj->bar, 2;
$obj->bar( 41 );
is $obj->bar, 42;

is(
	$obj,
	bless( { foo => 42, bar => 42 }, 'Local::MyClass' ),
);

is(
	\@FOO,
	[
		[ 9 ],
		[ 1, 10 ],
		[ 41, 2 ],
	],
);

is(
	\@BAR,
	[
		[ 1 ],
		[ 41, 2 ],
	],
);

done_testing;
