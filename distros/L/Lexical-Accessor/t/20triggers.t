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
		require B;
		sprintf(
			q[ %s->{%s} ],
			$selfvar,
			B::perlstring($me->{slot}),
		);
	}
};

my ( @FOO, @BAR );

BEGIN {
	package Local::MyClass;
	use Local::MyAccessor;
	
	sub new {
		my $class = shift;
		bless { @_ }, $class;
	}
	
	has foo => (
		is       => 'rw',
		trigger  => sub {
			my ( $self, @args ) = @_;
			push @FOO, \@args;
			$self->foo( $args[0] + 1 );
		},
	);
	
	has bar => (
		is       => 'rw',
		trigger  => 'trigger_bar',
	);
	
	sub trigger_bar {
		my ( $self, @args ) = @_;
		push @BAR, \@args;
		$self->bar( $args[0] + 1 );
	}
};

my $obj = Local::MyClass->new;
$obj->foo( 1 );
is $obj->foo, 2;
$obj->foo( 41 );
is $obj->foo, 42;
$obj->bar( 1 );
is $obj->bar, 2;
$obj->bar( 41 );
is $obj->bar, 42;

is_deeply(
	$obj,
	bless( { foo => 42, bar => 42 }, 'Local::MyClass' ),
) or diag explain($obj);

is_deeply(
	\@FOO,
	[
		[ 1 ],
		[ 41, 2 ],
	],
) or diag explain \@FOO;

is_deeply(
	\@BAR,
	[
		[ 1 ],
		[ 41, 2 ],
	],
) or diag explain \@FOO;

done_testing;
