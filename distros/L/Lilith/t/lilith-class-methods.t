#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

use_ok('Lilith') or BAIL_OUT('Lilith failed to load');

my $lilith = Lilith->new( dsn => 'dbi:Pg:dbname=test' );

#
# get_short_class tests
#

# undef input returns 'undefC'
is( $lilith->get_short_class(undef),  'undefC',   'get_short_class(undef) returns "undefC"' );
is( $lilith->get_short_class(),       'undefC',   'get_short_class() with no args returns "undefC"' );

# unknown class returns 'unknownC'
is( $lilith->get_short_class('NoSuchClass'), 'unknownC', 'get_short_class with unknown class returns "unknownC"' );

# known classes (case-insensitive)
is( $lilith->get_short_class('Spam'),                  'Spam',       'get_short_class: Spam' );
is( $lilith->get_short_class('spam'),                  'Spam',       'get_short_class: spam (lowercase) maps correctly' );
is( $lilith->get_short_class('SPAM'),                  'Spam',       'get_short_class: SPAM (uppercase) maps correctly' );
is( $lilith->get_short_class('Misc Attack'),           'MiscAtk',    'get_short_class: Misc Attack' );
is( $lilith->get_short_class('Denial of Service'),     'DoS',        'get_short_class: Denial of Service' );
is( $lilith->get_short_class('Web Application Attack'),'WebAppAtk',  'get_short_class: Web Application Attack' );
is( $lilith->get_short_class(''),                      'blankC',     'get_short_class: empty string returns "blankC"' );

# classes with leading '!' in their short form
is( $lilith->get_short_class('Not Suspicious Traffic'),  '!SusT',      'get_short_class: Not Suspicious Traffic' );
is( $lilith->get_short_class('Information Leak'),        'IL',         'get_short_class: Information Leak' );

#
# get_short_class_snmp tests
#

# undef input returns 'undefC'
is( $lilith->get_short_class_snmp(undef), 'undefC',  'get_short_class_snmp(undef) returns "undefC"' );
is( $lilith->get_short_class_snmp(),      'undefC',  'get_short_class_snmp() with no args returns "undefC"' );

# unknown class returns 'unknownC'
is( $lilith->get_short_class_snmp('NoSuchClass'), 'unknownC', 'get_short_class_snmp with unknown class returns "unknownC"' );

# SNMP version replaces leading '!' with 'not_'
is( $lilith->get_short_class_snmp('Not Suspicious Traffic'), 'not_SusT', 'get_short_class_snmp: ! replaced with not_' );
is( $lilith->get_short_class_snmp('Attempted Information Leak'), 'not_IL', 'get_short_class_snmp: Attempted Information Leak' );

# classes without '!' are the same in snmp form
is( $lilith->get_short_class_snmp('Spam'),         'Spam',    'get_short_class_snmp: Spam unchanged' );
is( $lilith->get_short_class_snmp('Misc Attack'),  'MiscAtk', 'get_short_class_snmp: Misc Attack unchanged' );

# case-insensitive
is( $lilith->get_short_class_snmp('SPAM'),         'Spam',    'get_short_class_snmp: case-insensitive lookup' );

#
# get_short_class_snmp_list tests
#

my $list = $lilith->get_short_class_snmp_list;

ok( defined($list),            'get_short_class_snmp_list returns a value' );
is( ref($list), 'ARRAY',       'get_short_class_snmp_list returns an arrayref' );
ok( scalar(@$list) > 2,        'get_short_class_snmp_list returns more than the two sentinel values' );

# sentinel values are always present
ok( ( grep { $_ eq 'undefC'   } @$list ), 'list includes "undefC"' );
ok( ( grep { $_ eq 'unknownC' } @$list ), 'list includes "unknownC"' );

# a known SNMP class is in the list
ok( ( grep { $_ eq 'Spam' } @$list ), 'list includes "Spam"' );

# snmp classes should not start with '!'
my @bang = grep { /^\!/ } @$list;
is( scalar(@bang), 0, 'no SNMP class names start with "!"' );

done_testing();
