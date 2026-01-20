BEGIN {
	package Local::User;
	use Marlin::Util -all;
	use Marlin qw( name url ),
		':ToHash' => { extra_args => true };

	sub to_json_ld {
		my ( $self ) = @_;
		return $self->to_hash(
			'@context' => 'http://schema.org/',
			'@type'    => 'Person',
		);
	}
};

use Test2::V0;

my $user = Local::User->new( name => 'Bob' );

is(
	$user->to_hash,
	{ name => 'Bob' },
);

is(
	$user->to_json_ld,
	{
		'@context' => 'http://schema.org/',
		'@type'    => 'Person',
		'name'     => 'Bob',
	},
);

done_testing;
