#!perl -T
use warnings; use strict;

=head1 NAME

dao-unpack.t

=head1 DESCRIPTION

The unpacking pass precedes thawing. It involves interpreting simple data
and C<Collection> and C<Map> containers within the data. These are all
converted to arrays by the Elive::Entity->_unpack_as_list() method.

=cut

use Test::More tests => 8;
use Test::Warn;

use Elive::Entity;
use Elive::Util;

my %user = (
	'FirstName' => 'Blinky',
	'Role' => {
	    'RoleAdapter' => {
		'RoleId' => '0'
	    }
	},
	'Id' => '123456789000',
	'LoginPassword' => 'a&b',
	'LastName' => 'Bill',
	'Deleted' => 'false',
	'LoginName' => 'bbill',
	'Email' => 'bbill@test.org'
    );

my $canonical = {
    'UserAdapter' => \%user
};

my $canonical_encoded = {
    'UserAdapter' => {
                   %user,
    },
};

#
# The following should all unpack to canoncial
#

#------ Simple value

my $simple_unpacked = Elive::Entity->_unpack_as_list(Elive::Util::_clone($canonical_encoded));
isa_ok($simple_unpacked, 'ARRAY');
is_deeply($canonical, $simple_unpacked->[0], 'Simple unpacking');

#------ Collection

my $collection = {
    Collection => {
	Entry => [
	    Elive::Util::_clone($canonical_encoded),
	]
    }
};

my $collection_unpacked = Elive::Entity->_unpack_as_list($collection);
is_deeply($canonical, $collection_unpacked->[0], 'Collection unpacking');

#------ Collection - singular

my $collection1 = {
    Collection => {
	Entry => Elive::Util::_clone($canonical_encoded),
    }
};

my $collection1_unpacked = Elive::Entity->_unpack_as_list($collection1);
is_deeply($canonical, $collection1_unpacked->[0], 'Collection unpacking');

#------ Hash Map

my $hash_map = {
    Map => {
	Entry => [
	    {
		Key   => 123456789000,
		Value => Elive::Util::_clone($canonical_encoded),
	    },
	],
    }
};

my $hash_map_unpacked = Elive::Entity->_unpack_as_list($hash_map);
is_deeply([$canonical], $hash_map_unpacked, 'Hash Map unpacking');

#------ Hash Map - singular

my $hash_map1 = {
    Map => {
	Entry => {
		Key   => 123456789000,
		Value => Elive::Util::_clone($canonical_encoded),
	    },
    }
};

my $hash_map1_unpacked = Elive::Entity->_unpack_as_list($hash_map1);
is_deeply([$canonical], $hash_map1_unpacked, 'Hash Map unpacking');

#------ Empty Collection (no results)

my $empty_collection = {
    Collection => ''
};

my $empty_collection_unpacked = Elive::Entity->_unpack_as_list($empty_collection);
is_deeply([], $empty_collection_unpacked, 'Empty collection unpacking');

#------ Check that we can handle irregularity in sub-group packing

my $group_collection = {
    GroupAdapter => {
	Id => '1111',
	Members => {
	    Collection => {
		Entry => [
		    2222,
		    3333,
		    {
			GroupAdapter => {
			    Id => 444,
			    # irregularity occurs here, there's no intermediate
			    # Members property
			    Collection => {
				Entry => [
				    '4141',
				    '4242',
				    '3333', # deliberate duplicate
				    ],
			    }
			}
		    }
		]
	    }
	}
    }
};

my $group_collection_unpacked = Elive::Entity->_unpack_as_list($group_collection);

do {
    my $expected = [{
	'GroupAdapter' => {
	    'Id' => '1111',
	    'Members' => [
		2222,
		3333,
		{
		    'GroupAdapter' => {
			'Id' => 444,
			'Entry' => [
			    '4141',
			    '4242',
			    '3333', # deliberate duplicate
			    ]
		    }
		}
	    ]
	}
   }];

    is_deeply($group_collection_unpacked, $expected, 'Nested group unpacking');
};

