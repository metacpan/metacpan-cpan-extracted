# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as
# `perl Filter-Arguments.t'

#########################

use strict;
use Test::More tests => 3;

BEGIN {
	use_ok('Filter::Arguments');
};

@ARGV = qw( --unknown --holey );

my $carbohydrate             = Argument( alias => '--carb', default => 'rice' );
my $noodles                  = Argument;
my ($wasabi,$rooster,$cream) = Arguments;
my $beans                    = Argument( 'holey' => 'moley' );
my $function                 = Argument( default => 'search' );
my $keyword                  = Argument( default => "" );
my $page                     = Argument( default => 1 );

my @warnings;
my @expected_warnings = (
    'no value supplied for noodles',
    'no value supplied for cream',
    'no value supplied for rooster',
    'no value supplied for wasabi',
    'unexpected argument --unknown'
);

eval {
    local $SIG{__WARN__} = sub {
        my ($warning) = $_[0];
        chop $warning;
        push @warnings, $warning;
    };
    Arguments::verify_usage();
};
my $usage_text = $@ || "";
$usage_text =~ s{\A .*? t/usage}{t/usage}xmsg;

my $expected_usage_text = <<"USAGE_TEXT";
t/usage.t
  --keyword\t(default is empty string)
  --page\t(default is '1')
  --function\t(default is 'search')
  --carb\t(default is 'rice')
  --noodles
  --cream
  --rooster
  --wasabi
  --holey\t(default is 'moley')

USAGE_TEXT

is_deeply( \@warnings, \@expected_warnings, 'correct warnings' );

is( $usage_text, $expected_usage_text, 'correct usage text' );

1;
