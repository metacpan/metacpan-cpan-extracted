#!/usr/bin/env perl
use strict;
use warnings;
use utf8;
use lib './lib';
use open ':std' => 'utf8';
use Test::More;
use JSON;

BEGIN
{
    use_ok( 'JSON::Schema::Validate' ) || BAIL_OUT( "Unable to load JSON::Schema::Validate" );
};

# Test that the 'format' option can be used to define custom validation criteria.

my $js = JSON::Schema::Validate->new(
	{
		type => 'object',
		properties => 
		{
			mydate => { format => 'date-time' }
		},
	},
	format => 
	{
		'date-time' => sub
		{
			ok(1, 'callback fired');
			$_[0] =~ /^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z$/i;
		}
	}
);

my $result;

$result = $js->validate({ mydate => '2011-11-11T11:11:11Z' });
ok( $result, 'this should pass' ) or diag( $js->error );

$result = $js->validate({ mydate => '2011-11-11T11:11:1Z' });
ok( !$result, 'this should fail' ) or diag( $js->error );

done_testing();

__END__
