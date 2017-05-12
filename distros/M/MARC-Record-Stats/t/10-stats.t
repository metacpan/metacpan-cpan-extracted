use warnings;
use strict;

use Test::Most qw{no_plan};

use MARC::Record;

BEGIN {
	use_ok('MARC::Record::Stats');
}

my $records = [
	[
		['001', '/RU/IV/IGTA/001'],
		['100', ' ', ' ',
			'a' => 'Ivanov, I. I.'],
		['701', ' ', ' ',
			'a' => 'Petrov, P. P'
		],
		['701', ' ', ' ',
			'a' => 'Sidorov, S. S.'
		],
		['245', ' ', ' ',
			'a' => 'Some title',
			'e' => 'first e',
			'e' => 'second e'],
	],
	[
		['001','/RU/IV/IGTA/002'],
		['100', ' ', ' ',
			'a'	=> 'Petrov, P. P.',
			'u' => 'Physics dept.',
		],
		['245', ' ', ' ',
			'a' => 'Another title',
		],
		['700', ' ', ' ',
			'a' => 'Sidorov, S. S.',
			'u' => 'Chemistry dept.',
		]
	],
];

my $expected_stats_0 = {
	nrecords	=> 1,
	tags		=> {
		'001' => {
			occurence	=> 1,
			repeatable	=> 0,
			subtags		=> {},
		},
		'100' => {
			occurence	=> 1,
			repeatable	=> 0,
			subtags		=> {
				'a'	=> {
					occurence	=> 1,
					repeatable	=> 0
				}
			}
		},
		'245' => {
			occurence	=> 1,
			repeatable	=> 0,
			subtags	=> {
				'a' => {
					occurence	=> 1,
					repeatable	=> 0
				},
				'e' => {
					occurence => 1,
					repeatable => 1,
				}
			}
		},
		'701' => {
			occurence	=> 1,
			repeatable	=> 1,
			subtags 	=> { 'a' => { occurence => 1, repeatable => 0} }
		}
	}
};

my $expected_stats_01 = {
	nrecords	=> 2,
	tags		=> {
		'001' => {
			occurence	=> 2,
			repeatable	=> 0,
			subtags		=> {},
		},
		'100' => {
			occurence	=> 2,
			repeatable	=> 0,
			subtags		=> {
				'a'	=> {
					occurence	=> 2,
					repeatable	=> 0
				},
				'u'	=> {
					occurence	=> 1,
					repeatable	=> 0
				},
			}
		},
		'245' => {
			occurence	=> 2,
			repeatable	=> 0,
			subtags	=> {
				'a' => {
					occurence	=> 2,
					repeatable	=> 0
				},
				'e' => {
					occurence   => 1,
					repeatable  => 1,
				}
			}
		},
		
		'700' => {
			occurence	=> 1,
			repeatable	=> 0,
			subtags		=> {
				'a'	=> { occurence => 1, repeatable	=> 0},
				'u' => { occurence => 1, repeatable	=> 0},
			}
		},
		'701' => {
			occurence	=> 1,
			repeatable	=> 1,
			subtags		=> {
				'a'	=> { occurence => 1, repeatable => 0 },
			}
		}
	}
};


my ($marc1, $marc2, $stat, $stat01);

$marc1 = MARC::Record->new( );
$marc1->add_fields( @{ $records->[0] } );

$stat = MARC::Record::Stats->new( $marc1 );

cmp_deeply($stat->get_stats_hash, $expected_stats_0, "Single record stats");

$marc2 = MARC::Record->new();
$marc2->add_fields( @{ $records->[1] } );

$stat01 = MARC::Record::Stats->new(
	$marc2,
	$stat
);

cmp_deeply( $stat01->get_stats_hash, $expected_stats_01, "Two records one by one stats");

$stat = MARC::Record::Stats->new( [$marc1, $marc2] );
cmp_deeply( $stat01->get_stats_hash, $stat->get_stats_hash, "One by one stats and batch stats are the same" ); 