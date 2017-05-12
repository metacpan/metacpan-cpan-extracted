#!perl -T

use strict;
use warnings;
use utf8;

use Lingua::TH::Numbers;
use Test::Exception;
use Test::FailWarnings -allow_deps => 1;
use Test::More tests => 13;


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

	my ( $input, $thai_numerals ) = split( /\t/, $line );

	subtest(
		"Convert $input to Thai numerals.",
		sub
		{
			plan( tests => 2 );

			my $builder = Test::More->builder();
			binmode( $builder->output(), ":utf8" );
			binmode( $builder->failure_output(), ":utf8" );
			binmode( $builder->todo_output(), ":utf8" );

			my $output;
			lives_ok(
				sub
				{
					$output = Lingua::TH::Numbers
						->new( $input )
						->thai_numerals();
				},
				"Convert input.",
			);

			is(
				$output,
				$thai_numerals,
				'The output is correct.',
			);
		}
	);
}


__DATA__
# Input	Thai numerals
0	๐
1	๑
2	๒
3	๓
4	๔
5	๕
6	๖
7	๗
8	๘
9	๙
10	๑๐
123456789	๑๒๓๔๕๖๗๘๙
๑๒๓๔๕๖๗๘๙	๑๒๓๔๕๖๗๘๙
