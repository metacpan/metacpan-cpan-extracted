use strict;
use warnings;

use Test::More;
use Cwd;
use lib qw( lib ../lib );

BEGIN { 
	plan tests => 19 
};

my $in_dir = (-e ''? '' : 't/');

use_ok( 'HTML::SummaryBasic' );


my $p = new HTML::SummaryBasic  {
	PATH => $in_dir.'full.html',
	NOT_AVAILABLE => undef,
};

isa_ok( $p, 'HTML::SummaryBasic' );

my $t = {
	AUTHOR => 'AN AUTHOR',
	TITLE => 'Title Element Text',
	CREATED_META => 'Yesterday',
	DESCRIPTION => 'A description',
	LAST_MODIFIED_META => 'Today',
	FIRST_PARA => 'First paragraph',
	HEADLINE => 'The Headline',
};


foreach ( keys %$t ){
	is( 
		$p->{SUMMARY}->{$_}, $t->{$_}, $_. ' from filled HTML'
	);
}


$p = new HTML::SummaryBasic  {
	PATH => $in_dir.'blank.html',
	NOT_AVAILABLE => undef,
};

isa_ok( $p, 'HTML::SummaryBasic' );

foreach (qw(
	AUTHOR FIRST_PARA TITLE CREATED_META DESCRIPTION LAST_MODIFIED_META HEADLINE
)){
	is( 
		$p->{SUMMARY}->{$_}, $p->{NOT_AVAILABLE}, $_. ' from blank HTML'
	);
}

isnt( 
	$p->{SUMMARY}->{CREATED_FILE}, $p->{NOT_AVAILABLE}, 'Created file from blank HTML'
);

isnt( 
	$p->{SUMMARY}->{LAST_MODIFIED_FILE}, $p->{NOT_AVAILABLE}, 'Last modified file from blank HTML'
);









