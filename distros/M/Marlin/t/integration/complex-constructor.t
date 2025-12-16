=pod

=encoding utf-8

=head1 PURPOSE

A more complex constructor with coercions and defaults.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2025 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use Test2::V0;

{
	package Local::Foo;
	use Types::Common 'Bool';
	use Marlin
		bar1 => { default => 42 },
		bar2 => { default => [] },
		bar3 => { isa => Bool, coerce => 1 };
}

sub is_xs {
	my $sub = $_[0];
	if ( Scalar::Util::blessed($sub) and $sub->isa( "Class::MOP::Method" ) ) {
		$sub = $sub->body;
	}
	elsif ( not ref $sub ) {
		no strict "refs";
		if ( not exists &{$sub} ) {
			my ( $pkg, $method ) = ( $sub =~ /\A(.+)::([^:]+)\z/ );
			if ( my $found = $pkg->can($method) ) {
				return lc(is_xs($found));
			}
			return "--";
		}
		$sub = \&{$sub};
	}
	require B;
	B::svref_2object( $sub )->XSUB ? 'XS' : 'PP';
}

is( is_xs('Local::Foo::new'), 'XS' );

my $thing = Local::Foo->new( bar3 => 'Hi' );

is(
	$thing,
	bless( {
		bar1 => 42,
		bar2 => [],
		bar3 => !!1,
	}, 'Local::Foo'),
);

done_testing;

