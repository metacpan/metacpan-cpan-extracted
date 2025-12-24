=pod

=encoding utf-8

=head1 PURPOSE

Tests different options for attribute storage.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2025 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use Test2::V0;
use Data::Dumper;

{
	package Local::User;
	use Marlin::Util -all;
	use Types::Common -types;
	use Marlin
		'username!',  => Str,
		'password!'   => {
			is            => bare,
			isa           => Str,
			writer        => 'change_password',
			required      => true,
			storage       => 'PRIVATE',
			handles_via   => 'String',
			handles       => { check_password => 'eq' },
		},
}

my $bob = Local::User->new(
	username => 'bd',
	password => 'zi1ch',
);

is( $bob->username, 'bd' );

my $e = dies { $bob->password };
like( $e, qr/locate object method/ );

ok( !$bob->check_password( 'monk33' ) );

ok( $bob->check_password( 'zi1ch' ) );

is(
	$bob,
	bless( { username => 'bd' }, 'Local::User' ),
);

$bob->change_password( 'monk33' );

ok( $bob->check_password( 'monk33' ) );

ok( !$bob->check_password( 'zi1ch' ) );

is(
	$bob,
	bless( { username => 'bd' }, 'Local::User' ),
);

is(
	Marlin->find_meta( ref $bob )->to_string( $bob ),
	q{LocalUser[username => "bd"]},
	'Private attribute excluded from stringification',
);

done_testing;
