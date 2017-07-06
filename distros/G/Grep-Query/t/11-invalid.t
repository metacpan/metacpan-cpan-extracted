use strict;
use warnings;

use Grep::Query;
use Grep::Query::FieldAccessor;

use Test::More;
use Test::Exception;

my @tests = getTests();

plan tests => ( scalar(@tests) + 4 );

foreach my $t (@tests)
{
	my $desc = "'$t->{q}'" . ($t->{desc} ? " ($t->{desc})" : ''); 
	throws_ok(sub { Grep::Query->new($t->{q}) }, $t->{e}, $desc);
}

my $gqWithField = Grep::Query->new('field.regexp(.*)');
my $gqWithoutField = Grep::Query->new('regexp(.*)');
my $fieldAccessor =  Grep::Query::FieldAccessor->new();

lives_ok
	(
		sub
			{
				$gqWithField->qgrep(1, 2, 3);
			},
		'not passing a fieldaccessor when needed but calling in a void context'
	);
	
throws_ok
	(
		sub
			{
				my $hits = $gqWithField->qgrep(1, 2, 3);
			},
		qr/field names used in query; first argument must be a field accessor/,
		'not passing a fieldaccessor when needed'
	);

lives_ok
	(
		sub
			{
				$gqWithoutField->qgrep(1, 2, 3);
			},
		'pass a fieldaccessor when not needed but calling in a void context'
	);
	
throws_ok
	(
		sub
			{
				my $hits = $gqWithoutField->qgrep($fieldAccessor, 1, 2, 3);
			},
		qr/no fields used in query, yet the first argument is a field accessor\?/,
		'pass a fieldaccessor when not needed'
	);

sub getTests
{
	return
		(
			{
				desc => 'empty',
				q => '',
				e => qr/Invalid query at offset 0: '' /,
			}, 
			{
				desc => 'blank',
				q => '           ',
				e => qr/Invalid query at offset 0: ' ' /,
			}, 
			{
				desc => q(mispelled 'regexp'),
				q => 'regex(.*)',
				e => qr/Invalid query at offset 0: 'regex\(.*\)' /,
			}, 
			{
				desc => q(invalid regexp),
				q => 'regexp([dkob)',
				e => qr/Unmatched \[ in regex/,
			}, 
			{
				desc => q(missing test),
				q => '(.*)',
				e => qr/Invalid query at offset 0: '\(.*\)' /,
			}, 
			{
				desc => q(missing part 2),
				q => 'regexp(.*) AND',
				e => qr/Invalid query at offset 10: ' AND' /,
			}, 
			{
				desc => q(can't mix fielded matches with unfielded),
				q => 'field.regexp(B) OR REGEXP(b)',
				e => qr/Query must use field names for all matches or none /,
			}, 
			{
				desc => q(invalid field name),
				q => 'my.field.regexp(.*)',
				e => qr/Invalid query at offset 0:/,
			}, 
			{
				desc => q(invalid number),
				q => '==(a)',
				e => qr/Not a number for '==': 'a' /,
			}, 
			{
				desc => q'invalid same delimiter (',
				q => '==(42(',
				e => qr/Invalid query at offset 0:/,
			}, 
			{
				desc => q'invalid same delimiter )',
				q => '==)42)',
				e => qr/Invalid query at offset 0:/,
			}, 
			{
				desc => q'invalid same delimiter {',
				q => '=={42{',
				e => qr/Invalid query at offset 0:/,
			}, 
			{
				desc => q'invalid same delimiter }',
				q => '==}42}',
				e => qr/Invalid query at offset 0:/,
			}, 
			{
				desc => q'invalid same delimiter [',
				q => '==[42[',
				e => qr/Invalid query at offset 0:/,
			}, 
			{
				desc => q'invalid same delimiter ]',
				q => '==]42]',
				e => qr/Invalid query at offset 0:/,
			}, 
			{
				desc => q'invalid same delimiter <',
				q => '==<42<',
				e => qr/Invalid query at offset 0:/,
			}, 
			{
				desc => q'invalid same delimiter >',
				q => '==>42>',
				e => qr/Invalid query at offset 0:/,
			}, 
		);
}