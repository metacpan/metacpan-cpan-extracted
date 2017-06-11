package TestInfo;

use strict;
use warnings;

use Grep::Query::FieldAccessor;

use TestObject;

my $data =
	{
		numbers => [ -5 .. 5 ],

		strings => [ qw( abc def ghi 012 345 678 ) ],

		regexps => [ 'a' .. 'z' ],
		
		records =>
			{
				a =>
					{
						name => 'Alison',
						byear => 1952,
						siblings => 2,
						city => 'Dallas',
						sex => 'F',
					},
				b =>
					{
						name => 'Bronwen',
						byear => 1937,
						siblings => 0,
						city => 'Cardiff',
						sex => 'F',
					},
				c =>,
					{
						name => 'Curt',
						byear => 1971,
						siblings => 4,
						city => 'Leipzig',
						sex => 'M',
					},
				d =>
					{
						name => 'Daraja',
						byear => 2015,
						siblings => 0,
						city => 'Ibadan',
						sex => 'F',
					},
				e =>
					{
						name => 'Emin',
						byear => 1941,
						siblings => 0,
						city => 'Diyarbakir',
						sex => 'M',
					},
				f =>
					{
						name => 'Florian',
						byear => 1941,
						siblings => 2,
						city => 'Szczecin',
						sex => 'M',
					},
				g =>
					{
						name => 'Gatsharan',
						byear => 1928,
						siblings => 2,
						city => 'Mumbai',
						sex => 'F',
					},
				h =>
					{
						name => 'Helena',
						byear => 1960,
						siblings => 1,
						city => 'Birmingham',
						sex => 'F',
					},
				i =>
					{
						name => 'Inessa',
						byear => 1992,
						siblings => 0,
						city => 'Omsk',
						sex => 'F',
					},
				j =>
					{
						name => 'Jinghua',
						byear => 1960,
						siblings => 9,
						city => 'Taipei',
						sex => 'F',
					},
				k =>
					{
						name => 'Kenneth',
						byear => 1963,
						siblings => 1,
						city => 'Stockholm',
						sex => 'M',
					},
				l =>
					{
						name => 'Laverne',
						byear => 1985,
						siblings => 0,
						city => 'Vancouver',
						sex => 'F',
					},
				m =>
					{
						name => 'Martinien',
						byear => 1920,
						siblings => 8,
						city => 'Mendoza',
						sex => 'M',
					},
				n =>
					{
						name => 'Niilo',
						byear => 1974,
						siblings => 2,
						city => 'Rovaniemi',
						sex => 'M',
					},
				o =>
					{
						name => 'Oarona',
						byear => 1987,
						siblings => 4,
						city => 'Maseru',
						sex => 'F',
					},
				p =>
					{
						name => 'Paulette',
						byear => 1950,
						siblings => 7,
						city => 'Toulouse',
						sex => 'F',
					},
				q =>
					{
						name => 'Quibilah',
						byear => 1957,
						siblings => 2,
						city => 'Hurghada',
						sex => 'F',
					},
				r =>
					{
						name => 'Rebecca',
						byear => 1995,
						siblings => 1,
						city => 'Haifa',
						sex => 'F',
					},
				s =>
					{
						name => 'Shania',
						byear => 1956,
						siblings => 9,
						city => 'Seattle',
						sex => 'F',
					},
				t =>
					{
						name => 'Therese',
						byear => 1993,
						siblings => 1,
						city => 'Billund',
						sex => 'F',
					},
				u =>
					{
						name => 'Umoja',
						byear => 1991,
						siblings => 4,
						city => 'Manaus',
						sex => 'F',
					},
				v =>
					{
						name => 'Vidura',
						byear => 1967,
						siblings => 6,
						city => 'Bangkok',
						sex => 'M',
					},
				w =>
					{
						name => 'Wangara',
						byear => 1944,
						siblings => 3,
						city => 'Perth',
						sex => 'M',
					},
				x =>
					{
						name => 'Xavier',
						byear => 2008,
						siblings => 5,
						city => 'Palma',
						sex => 'M',
					},
				y =>
					{
						name => 'Yoshimasa',
						byear => 1943,
						siblings => 1,
						city => 'Nagoya',
						sex => 'F',
					},
				z =>
					{
						name => 'Zotico',
						byear => 2010,
						siblings => 4,
						city => 'Havana',
						sex => 'M',
					},
			},
			
		objects =>
			{
				# FIXUP
			},
			
		lonehash =>
			{
				# FIXUP
			},
	};

$data->{objects}->{$_} = TestObject->new($_, $data->{records}->{$_}) foreach (keys(%{$data->{records}}));
$data->{lonehash} = { lonehash => $data->{records} };

my $tests =
	{
		numbers =>
			[
				{
					q => 'true',
					e => $data->{numbers},
				}, 
				{
					q => 'false',
					e => [ ],
				}, 
				{
					q => '>(-6)',
					e => $data->{numbers},
					dbq => q/number > -6/,
				}, 
				{
					q => '==(0)',
					e => [ 0 ],
					dbq => q/number == 0/,
				}, 
				{
					q => '!=(0)',
					e => [ -5, -4, -3, -2, -1, 1, 2, 3, 4, 5 ],
					dbq => q/number != 0/,
				}, 
				{
					q => '>=(1)',
					e => [ 1, 2, 3, 4, 5 ],
					dbq => q/number >= 1/,
				}, 
				{
					q => '<=(1)',
					e => [ -5, -4, -3, -2, -1, 0, 1 ],
					dbq => q/number <= 1/,
				}, 
				{
					q => '>=(0.5) AND <=(1.5)',
					e => [ 1 ],
					dbq => q/number >= 0.5 AND number <= 1.5/,
				}, 
			],
			
		strings =>
			[
				{
					q => 'TRUE',
					e => $data->{strings},
				}, 
				{
					q => 'FALSE',
					e => [ ],
				}, 
				{
					q => 'NE(*%&)',
					e => $data->{strings},
				}, 
				{
					q => 'EQ(def)',
					e => [ qw(def) ],
				}, 
				{
					q => 'NE(def)',
					e => [ qw( abc ghi 012 345 678 ) ],
				}, 
				{
					q => 'GT()',
					e => $data->{strings},
				}, 
				{
					q => 'GT(0)',
					e => $data->{strings},
				}, 
				{
					q => 'GT(1)',
					e => [ qw( abc def ghi 345 678 ) ],
				}, 
				{
					q => 'GT(a)',
					e => [ qw( abc def ghi ) ],
				}, 
				{
					q => 'GE(def)',
					e => [ qw( def ghi ) ],
				}, 
				{
					q => 'LT()',
					e => [ ],
				}, 
				{
					q => 'LT(0)',
					e => [ ],
				}, 
				{
					q => 'LT(1)',
					e => [ qw( 012 ) ],
				}, 
				{
					q => 'LT(a)',
					e => [ qw( 012 345 678 ) ],
				}, 
				{
					q => 'LE(def)',
					e => [ qw( abc def 012 345 678 ) ],
				}, 
			],
		
		regexps =>
			[
				{
					q => 'REGEXP(.*)',
					e => $data->{regexps},
					dbq => q/line REGEXP '.*'/,
				}, 
				{
					q => 'REGEXP([dkob])',
					e => [ qw(b d k o) ],
					dbq => q/line REGEXP '[dkob]'/,
				}, 
				{
					desc => "use alt delimiter instead of paren pair: braces pair '{}'",
					q => 'REGEXP{[dkob]}',
					e => [ qw(b d k o) ],
				}, 
				{
					desc => "use alt delimiter instead of paren pair: brackets pair '[]'",
					q => 'REGEXP[d|k|o|b]',
					e => [ qw(b d k o) ],
				}, 
				{
					desc => "use alt delimiter instead of paren pair: angles pair '<>'",
					q => 'REGEXP<[dkob]>',
					e => [ qw(b d k o) ],
				}, 
				{
					desc => "use alt delimiter instead of paren pair: arbitrary character '/'",
					q => 'REGEXP/[dkob]/',
					e => [ qw(b d k o) ],
				}, 
				{
					desc => "use alt delimiter instead of paren pair: arbitrary character ':'",
					q => 'REGEXP:[dkob]:',
					e => [ qw(b d k o) ],
				}, 
				{
					desc => "use alt delimiter instead of paren pair: arbitrary character 'x' (quite confusing though...)",
					q => 'REGEXPx[dkob]x',
					e => [ qw(b d k o) ],
				}, 
				{
					q => 'NOT REGEXP([dkob])',
					e => [ qw(a c e f g h i j l m n p q r s t u v w x y z) ],
					dbq => q/NOT line REGEXP '[dkob]'/,
				}, 
				{
					q => 'REGEXP([dkob]) OR REGEXP([yaxkz])',
					e => [ qw(a b d k o x y z) ],
					dbq => q/line REGEXP '[dkob]' OR line REGEXP '[yaxkz]'/,
				}, 
				{
					q => 'REGEXP([yaxkz]) OR REGEXP([dkob])',
					e => [ qw(a b d k o x y z) ],
					dbq => q/line REGEXP '[yaxkz]' OR line REGEXP '[dkob]'/,
				}, 
				{
					q => 'NOT REGEXP([dkob]) OR REGEXP([yaxkz])',
					e => [ qw(a c e f g h i j k l m n p q r s t u v w x y z) ],
					dbq => q/NOT line REGEXP '[dkob]' OR line REGEXP '[yaxkz]'/,
				}, 
				{
					q => 'REGEXP([yaxkz]) OR NOT REGEXP([dkob])',
					e => [ qw(a c e f g h i j k l m n p q r s t u v w x y z) ],
					dbq => q/line REGEXP '[yaxkz]' OR NOT line REGEXP '[dkob]'/,
				}, 
				{
					q => 'REGEXP([dkob]) OR NOT REGEXP([yaxkz])',
					e => [ qw(b c d e f g h i j k l m n o p q r s t u v w) ],
					dbq => q/line REGEXP '[dkob]' OR NOT line REGEXP '[yaxkz]'/,
				}, 
				{
					q => 'NOT REGEXP([yaxkz]) OR REGEXP([dkob])',
					e => [ qw(b c d e f g h i j k l m n o p q r s t u v w) ],
					dbq => q/NOT line REGEXP '[yaxkz]' OR line REGEXP '[dkob]'/,
				}, 
				{
					q => 'NOT ( REGEXP([dkob]) OR REGEXP([yaxkz]) )',
					e => [ qw(c e f g h i j l m n p q r s t u v w) ],
					dbq => q/NOT ( line REGEXP '[dkob]' OR line REGEXP '[yaxkz]' )/,
				}, 
				{
					q => 'NOT ( REGEXP([yaxkz]) OR REGEXP([dkob]) )',
					e => [ qw(c e f g h i j l m n p q r s t u v w) ],
					dbq => q/NOT ( line REGEXP '[yaxkz]' OR line REGEXP '[dkob]' )/,
				}, 
				{
					q => 'REGEXP([dkob]) AND REGEXP([yaxkz])',
					e => [ qw(k) ],
					dbq => q/line REGEXP '[dkob]' AND line REGEXP '[yaxkz]'/,
				}, 
				{
					q => 'REGEXP([yaxkz]) AND REGEXP([dkob])',
					e => [ qw(k) ],
					dbq => q/line REGEXP '[yaxkz]' AND line REGEXP '[dkob]'/,
				}, 
				{
					q => 'NOT REGEXP([dkob]) AND REGEXP([yaxkz])',
					e => [ qw(a x y z) ],
					dbq => q/NOT line REGEXP '[dkob]' AND line REGEXP '[yaxkz]'/,
				}, 
				{
					q => 'REGEXP([yaxkz]) AND NOT REGEXP([dkob])',
					e => [ qw(a x y z) ],
					dbq => q/line REGEXP '[yaxkz]' AND NOT line REGEXP '[dkob]'/,
				}, 
				{
					q => 'REGEXP([dkob]) AND NOT REGEXP([yaxkz])',
					e => [ qw(b d o) ],
					dbq => q/line REGEXP '[dkob]' AND NOT line REGEXP '[yaxkz]'/,
				}, 
				{
					q => 'NOT REGEXP([yaxkz]) AND REGEXP([dkob])',
					e => [ qw(b d o) ],
					dbq => q/NOT line REGEXP '[yaxkz]' AND line REGEXP '[dkob]'/,
				}, 
				{
					q => 'NOT ( REGEXP([dkob]) AND REGEXP([yaxkz]) )',
					e => [ qw(a b c d e f g h i j l m n o p q r s t u v w x y z) ],
					dbq => q/NOT ( line REGEXP '[dkob]' AND line REGEXP '[yaxkz]' )/,
				}, 
				{
					q => 'NOT ( REGEXP([yaxkz]) AND REGEXP([dkob]) )',
					e => [ qw(a b c d e f g h i j l m n o p q r s t u v w x y z) ],
					dbq => q/NOT ( line REGEXP '[yaxkz]' AND line REGEXP '[dkob]' )/,
				}, 
				{
					q => 'REGEXP([almn]) OR REGEXP([dkob]) AND REGEXP([yaxkz])',
					e => [ qw(a k l m n) ],
					dbq => q/line REGEXP '[almn]' OR line REGEXP '[dkob]' AND line REGEXP '[yaxkz]'/,
				}, 
				{
					q => 'REGEXP([dkob]) AND REGEXP([yaxkz]) OR REGEXP([almn])',
					e => [ qw(a k l m n) ],
					dbq => q/line REGEXP '[dkob]' AND line REGEXP '[yaxkz]' OR line REGEXP '[almn]'/,
				}, 
				{
					q => '( REGEXP([dkob]) AND REGEXP([yaxkz]) ) OR REGEXP([almn])',
					e => [ qw(a k l m n) ],
					dbq => q/( line REGEXP '[dkob]' AND line REGEXP '[yaxkz]' ) OR line REGEXP '[almn]'/,
				}, 
				{
					q => 'REGEXP([dkob]) AND ( REGEXP([yaxkz]) OR REGEXP([almn]) )',
					e => [ qw(k) ],
					dbq => q/line REGEXP '[dkob]' AND ( line REGEXP '[yaxkz]'  OR line REGEXP '[almn]' )/,
				}, 
				{
					q => 'NOT ( REGEXP([dkob]) AND REGEXP([yaxkz]) OR REGEXP([almn]) )',
					e => [ qw(b c d e f g h i j o p q r s t u v w x y z) ],
					dbq => q/NOT ( line REGEXP '[dkob]' AND line REGEXP '[yaxkz]' OR line REGEXP '[almn]' )/,
				}, 
				{
					q => 'REGEXP([dkob]) AND NOT ( REGEXP([yaxkz]) OR REGEXP([almn]) )',
					e => [ qw(b d o) ],
					dbq => q/line REGEXP '[dkob]' AND NOT ( line REGEXP '[yaxkz]' OR line REGEXP '[almn]' )/,
				}, 
				{
					desc => "use alt symbols for AND (&&), OR (||) and NOT (!) and be case-insensitive",
					q => 'RegExp([dkob]) && ! ( Regexp([yaxkz]) || regexp([almn]) )',
					e => [ qw(b d o) ],
				}, 
			],
			
		records =>
			[
				{
					q => 'name.REGEXP(.*)',
					e => undef,		# FIXUP
					dbq => q/name REGEXP '.*'/,
				},
				{
					q => 'name.true',
					e => [ map { $data->{records}->{$_} } ('a' .. 'z') ],
				},
				{
					q => 'name.FALSE',
					e => [ ],
				},
				{
					q => 'name.REGEXP/(?i)a/',
					e => [ map { $data->{records}->{$_} } split('', 'adfghijlmopqrsuvwxy') ],
					dbq => q/name REGEXP '(?i)a'/,
				},
				{
					q => 'name.REGEXP/(?i)a/ AND siblings.>(1)',
					e => [ map { $data->{records}->{$_} } split('', 'afgjmopqsuvwx') ],
					dbq => q/name REGEXP '(?i)a' AND siblings > 1/,
				},
				{
					q => 'name.REGEXP/(?i)a/ AND siblings.>(1) AND byear.<(1960)',
					e => [ map { $data->{records}->{$_} } split('', 'afgmpqsw') ],
					dbq => q/name REGEXP '(?i)a' AND siblings > 1 AND byear < 1960/,
				},
				{
					q => 'name.REGEXP/(?i)a/ AND siblings.>(1) AND byear.<(1960) AND sex.REGEXP(M)',
					e => [ map { $data->{records}->{$_} } split('', 'fmw') ],
					dbq => q/name REGEXP '(?i)a' AND siblings > 1 AND byear < 1960 AND sex REGEXP 'M'/,
				},
				{
					q => 'name.REGEXP/(?i)a/ AND siblings.>(1) AND byear.<(1960) AND sex.REGEXP(M) AND city.REGEXP(z)',
					e => [ map { $data->{records}->{$_} } split('', 'fm') ],
					dbq => q/name REGEXP '(?i)a' AND siblings > 1 AND byear < 1960 AND sex REGEXP 'M' AND city REGEXP 'z'/,
				},
				{
					q => <<'QRY',
						name.REGEXP/(?i)a/
							AND
						siblings.>(1)
							AND
						byear.<(1960)
							AND
						(
							(
								sex.REGEXP(M)
									AND
								city.REGEXP(z)
							)
								OR
							(
								sex.REGEXP(F)
									AND
								city.REGEXP(l)
							)
						)
QRY
					e => [ map { $data->{records}->{$_} } split('', 'afmps') ],
					dbq => q/name REGEXP '(?i)a' AND siblings > 1 AND byear < 1960 AND ( ( sex REGEXP 'M' AND city REGEXP 'z' ) OR ( sex REGEXP 'F' AND city REGEXP 'l' ) )/,
				},
				{
					q => <<'QRY',
						/* lots of comments */
						
						/* first check that the name contains an 'a' or 'A' 
						name.REGEXP/(?i)a/
							AND
						/* and then:
						     check that siblings are > 1
						*/
						siblings.>(1)
							AND
						/*
							and, that birth year is less than 1960 */
						byear.<(1960)
							AND
						(
							/* while also determining things about sex/city */
							(
								sex.REGEXP(M)
									AND
								city.REGEXP(z)
							)
								OR /**/
							(
								sex.REGEXP(F)
									AND
								city.REGEXP(l)
							)
						)
QRY
					e => [ map { $data->{records}->{$_} } split('', 'afmps') ],
				},
			],
		
		objects =>
			[
				{
					q => 'name.REGEXP(.*)',
					e => undef,		# FIXUP
				},
				{
					q => 'name.REGEXP/(?i)a/',
					e => [ qw(a d f g h i j l m o p q r s u v w x y) ],
				},
				{
					q => 'name.REGEXP/(?i)a/ AND siblings.>(1)',
					e => [ qw(a f g j m o p q s u v w x) ],
				},
				{
					q => 'name.REGEXP/(?i)a/ AND siblings.>(1) AND byear.<(1960)',
					e => [ qw(a f g m p q s w) ],
				},
				{
					q => 'name.REGEXP/(?i)a/ AND siblings.>(1) AND byear.<(1960) AND sex.REGEXP(M)',
					e => [ qw(f m w) ],
				},
				{
					q => 'name.REGEXP/(?i)a/ AND siblings.>(1) AND byear.<(1960) AND sex.REGEXP(M) AND city.REGEXP(z)',
					e => [ qw(f m) ],
				},
				{
					q => 'NOT name.REGEXP/(?i)a/ AND sex.REGEXP(M) OR city.REGEXP(z)',
					e => [ qw(c e f k m n z) ],
				},
				{
					q => <<'QRY',
						name.REGEXP/(?i)a/
							AND
						siblings.>(1)
							AND
						byear.<(1960)
							AND
						(
							(
								sex.REGEXP(M)
									AND
								city.REGEXP(z)
							)
								OR
							(
								sex.REGEXP(F)
									AND
								city.REGEXP(l)
							)
						)
QRY
					e => [ qw(a f m p s) ],
				},
				{
					q => 'age.==(53)',
					e => [ qw(k) ],
				},
				{
					q => 'name.REGEXP/(?i)a/ AND siblings.>(1) AND age.>(30) AND city.REGEXP(l)',
					e => [ qw(a p s) ],
				},
				{
					q => 'age.>=(30) AND age.<=(60)',
					e => [ qw(c h j k l n q s v) ],
				},
			],
			
		lonehash =>
			[
				{
					q => 'key.REGEXP(.*)',
					e => undef,		# FIXUP
				},
				{
					q => 'key.REGEXP([dkob])',
					e => [ qw(b d k o) ],
				},

				{
					q => 'name.REGEXP/(?i)a/',
					e => [ qw(a d f g h i j l m o p q r s u v w x y) ],
				},
				{
					q => 'name.REGEXP/(?i)a/ AND siblings.>(1)',
					e => [ qw(a f g j m o p q s u v w x) ],
				},
				{
					q => 'name.REGEXP/(?i)a/ AND siblings.>(1) AND byear.<(1960)',
					e => [ qw(a f g m p q s w) ],
				},
				{
					q => 'name.REGEXP/(?i)a/ AND siblings.>(1) AND byear.<(1960) AND sex.REGEXP(M)',
					e => [ qw(f m w) ],
				},
				{
					q => 'name.REGEXP/(?i)a/ AND siblings.>(1) AND byear.<(1960) AND sex.REGEXP(M) AND city.REGEXP(z)',
					e => [ qw(f m) ],
				},
				{
					q => <<'QRY',
						name.REGEXP/(?i)a/
							AND
						siblings.>(1)
							AND
						byear.<(1960)
							AND
						(
							(
								sex.REGEXP(M)
									AND
								city.REGEXP(z)
							)
								OR
							(
								sex.REGEXP(F)
									AND
								city.REGEXP(l)
							)
						)
QRY
					e => [ qw(a f m p s) ],
				},
			]
	};

my @recordValues;
push(@recordValues, $data->{records}->{$_}) foreach (sort(keys(%{$data->{records}})));
$tests->{records}->[0]->{e} = \@recordValues;

my @objectValues;
push(@objectValues, $data->{objects}->{$_}) foreach (sort(keys(%{$data->{objects}})));
$tests->{objects}->[0]->{e} = [ map { $_->get_id() } @objectValues ];

my @lonehashValues;
push(@lonehashValues, $_) foreach (sort(keys(%{$data->{lonehash}->{lonehash}})));
$tests->{lonehash}->[0]->{e} = \@lonehashValues;

my $fieldAccessors =
	{
		records =>
			[
				undef,
				Grep::Query::FieldAccessor->new
					(
						{
							name => sub { $_[0]->{name} },
							byear => sub { $_[0]->{byear} },
							siblings => sub { $_[0]->{siblings} },
							city => sub { $_[0]->{city} },
							sex => sub { $_[0]->{sex} },
						}
					),
			],
			
		objects =>
			[
				Grep::Query::FieldAccessor->new
					(
						{
							name => sub { $_[0]->get_name() },
							byear => sub { $_[0]->get_byear() },
							siblings => sub { $_[0]->get_siblings() },
							city => sub { $_[0]->get_city() },
							sex => sub { $_[0]->get_sex() },
							age => sub { $_[0]->get_age() },
						}
					),
			],	

		lonehash =>
			[
				Grep::Query::FieldAccessor->new
					(
						{
							key => sub { $_[0]->[0] },
							name => sub { $_[0]->[1]->{name} },
							byear => sub { $_[0]->[1]->{byear} },
							siblings => sub { $_[0]->[1]->{siblings} },
							city => sub { $_[0]->[1]->{city} },
							sex => sub { $_[0]->[1]->{sex} },
						}
					),
			],	
	};
	
my $recordFieldAccessor = Grep::Query::FieldAccessor->new();
foreach my $field (qw(name byear siblings city sex))
{
	$recordFieldAccessor->add($field, sub { $_[0]->{$field} });
}
push(@{$fieldAccessors->{records}}, $recordFieldAccessor);

my $objectFieldAccessor = Grep::Query::FieldAccessor->new();
$objectFieldAccessor->add('name', sub { $_[0]->get_name() } );
$objectFieldAccessor->add('byear', sub { $_[0]->get_byear() } );
$objectFieldAccessor->add('siblings', sub { $_[0]->get_siblings() } );
$objectFieldAccessor->add('city', sub { $_[0]->get_city() } );
$objectFieldAccessor->add('sex', sub { $_[0]->get_sex() } );
$objectFieldAccessor->add('age', sub { $_[0]->get_age() } );
push(@{$fieldAccessors->{objects}}, $objectFieldAccessor);

my $matchAdjustors =
	{
		records => sub { $_[0] },
		objects => sub { [ map { $_->get_id() } @{$_[0]} ] },
		lonehash => sub { [ sort(keys(%{$_[0]->[0]})) ] },
	};

sub getData
{
	return $data->{$_[0]};
}

sub getTests
{
	return $tests->{$_[0]};
}

sub getFieldAccessors
{
	return $fieldAccessors->{$_[0]};
}

sub getMatchAdjustor
{
	return $matchAdjustors->{$_[0]};
}

1;
