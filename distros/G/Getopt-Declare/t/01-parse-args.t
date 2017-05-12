#!perl

use lib 'lib';
use strict;
use warnings;
no warnings qw(once);
use Test::More tests => 24;

BEGIN { use_ok( 'Getopt::Declare' ); }


my $spec = q{
	[pvtype: bool /0|1/]
	[pvtype: one /asdf/ { $_VAL_ = 1; } ]
	-a <aval>		option 1
	-b <bval:qs>		option 2
	bee <bval:qs>		[ditto] (again)
	<c>			option 3
	+d <dval:n>...		option 4 [repeatable]
	-1			option 5
	--out <out:of>...	option 6
	<d>			
	-y			option 8
	-z			option 9
	-e <eval:bool>		option 10
	-f <a> * <b> @ <step>	option 11
	-g <gval:one>		option 12
	-p <perc:0+n>		option 13
			{ $::use_percentage = 'on'; }
Decorations using brackets need to be escaped with '\\\[', e.g. \[ditto], \[repeatable]
};

my $usage = quotemeta( q{
Options:

        -a <aval>               option 1
        -b <bval>               option 2
        bee <bval>                "    " (again)

        <c>                     option 3
        +d <dval>...            option 4 
        -1                      option 5
        --out <out>...          option 6
        <d>                     
        -y                      option 8
        -z                      option 9
        -e <eval>               option 10
        -f <a> * <b> @ <step>   option 11
        -g <gval>               option 12
        -p <perc>               option 13
Decorations using brackets need to be escaped with '\[', e.g. [ditto], [repeatable]

} );

@ARGV = (
    '-g',        'asdf',
    'bee',       'BB BB',
    '--out',     'dummy.txt', 'fake.csv',
    '-aA',
    's e e',
    'remainder',
    '-yz',
    '+d',        '8', '1.2345', '0.99', '1000123', '.3', 'a',
    '-e',        '0',
    '-p',        '0.452',
    '-f',        '1', '*', '10', '@', '0.1',
    '+d',        '9', '1.2345', '1e3', '2.1E-01', '.3', '-1',
);

ok my $args = Getopt::Declare->new($spec), 'new';
isa_ok $args, 'Getopt::Declare';
ok $args->version, 'version';
ok $args->usage, 'usage';
ok $args->usage_string =~ m/$usage/;
is $args->{'-a'}, 'A', 'argument parsing';
is $args->{'bee'}, 'BB BB';
is $args->{'<c>'}, 's e e';
is join(',',@{$args->{'+d'}}), '8,1.2345,0.99,1000123,.3,9,1.2345,1e3,2.1E-01,.3';
is $args->{'<d>'}, undef;
is $args->{'-1'}, -1;
is $args->{'--out'}->[0], 'dummy.txt';
is $args->{'--out'}->[1], 'fake.csv';
is $args->{'-f'}->{'<a>'}, 1;
is $args->{'-f'}->{'<b>'}, 10;
is $args->{'-f'}->{'<step>'}, 0.1;
is $args->{'-g'}, 1;
is $args->{'-e'}, 0;
is $args->{'-p'}, 0.452;
is $::use_percentage, 'on';
is scalar @ARGV, 2;
is $ARGV[0], 'remainder';
is $ARGV[1], 'a';


