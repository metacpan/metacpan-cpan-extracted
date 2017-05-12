#!perl -T

use strict;
use warnings;
use utf8;

use Lingua::TH::Numbers;
use Test::Exception;
use Test::FailWarnings -allow_deps => 1;
use Test::More tests => 12;


# Change all the Test::More pipes to output utf8, to prevent
# "Wide character in print" warnings. This is only available for Perl 5.8+
# however due to the reliance on PerlIO, so earlier versions will fail with
# "Unknown discipline ':utf8'".
if ( $] > 5.008 )
{
	my $builder = Test::More->builder();
	binmode( $builder->output(), ":utf8" );
	binmode( $builder->failure_output(), ":utf8" );
	binmode( $builder->todo_output(), ":utf8" );
}


foreach my $line ( <DATA> )
{
	chomp( $line );
	next unless defined( $line ) && $line ne '';
	next if substr( $line, 0, 1 ) eq '#';

	my ( $input, $is_valid ) = split( /\t/, $line );

	if ( $is_valid eq 'Yes' )
	{
		lives_ok(
			sub
			{
				my $number = Lingua::TH::Numbers->new( $input );
			},
			"Build an object with $input as input (success)."
		);
	}
	else
	{
		dies_ok(
			sub
			{
				my $number = Lingua::TH::Numbers->new( $input );
			},
			"Build an object with $input as input (failure).",
		);
	}
}


__DATA__
# Input	Valid
๐	Yes
0	Yes
10	Yes
-10	Yes
๑๐	Yes
-๑๐	Yes
3.14	Yes
๑.๐๒	Yes
-3.14	Yes
-๑.๐๒	Yes
A	No
ล้าน	No
