use strict;
use warnings;
use Test::More tests => 7;

use HTML::FormFu;
use lib qw(t/lib lib);
use DBICTestLib 'new_schema';
use MySchema;

my $form = HTML::FormFu->new;

$form->load_config_file('t/update/has_many_repeatable_many_new.yml');

my $schema     = new_schema();
my $user_rs    = $schema->resultset('User');
my $address_rs = $schema->resultset('Address');

{
	$form->process(
		{
			'id'                  => '',
			'name'                => 'new nick',
			'master'              => 1,
			'count'               => 2,
			'addresses_1.id'      => '',
			'addresses_1.address' => 'new home',
			'addresses_2.id'      => '',
			'addresses_2.address' => 'new office',
            'addresses_3.id'      => '',
			'addresses_3.address' => 'new office2',
		}
	);

	ok( $form->submitted_and_valid );

    my $row = $user_rs->new( {} );

    $form->model('DBIC')->update($row);

    my $user = $user_rs->find(1);

    is( $user->name, 'new nick' );

    my @add = $user->addresses->all;

    # 3rd address isn't inserted

    is( scalar @add,      2 );

    is( $add[0]->id,      1 );
	is( $add[0]->address, 'new home' );
	is( $add[1]->id,      2 );
	is( $add[1]->address, 'new office' );
}
