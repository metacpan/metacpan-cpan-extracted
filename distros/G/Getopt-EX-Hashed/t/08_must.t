use strict;
use warnings;
use Test::More;
use lib './t';
use Data::Dumper;
$Data::Dumper::Sortkeys = 1;

use Getopt::Long;
use Getopt::EX::Hashed 'has';

has answer => spec => '=i',
    must => sub { $_[1] == 42 };

has answer_is => spec => '=i',
    must   => sub { $_[1] == 42 },
    action => sub {
	$_->{$_[0]} = "Answer is $_[1]";
    };

has question => spec => 'q=s@', default => [],
    must => sub {
	grep { lc($_[1]) eq $_ } qw(life universe everything);
    };

has nature => spec => '=s%', default => {},
    must => sub {
	grep { lc($_[2]) eq $_ } qw(paranoid);
    };

VALID: {
    local @ARGV = qw(--answer 42
		     --answer-is 42
		     -q life
		     -q universe
		     -q everything
		     --nature Marvin=Paranoid
		   );

    my $app = Getopt::EX::Hashed->new() or die;
    GetOptions($app->optspec); # or die;

    is($app->{answer}, 42, "Number");
    is($app->{answer_is}, "Answer is 42", "Number with action");
    is_deeply($app->{question}, [ "life", "universe", "everything" ], "List");
    is($app->{nature}->{Marvin}, "Paranoid", "Hash");
}

INVALID: {
    local @ARGV = qw(--answer 41
		     --answer-is 41
		     -q life
		     -q space
		     -q everything
		     -nature Marvin=Sociable
		   );

    # has [ qw(+answer +answer_is +question +nature) ] => must => undef;

    my $app = Getopt::EX::Hashed->new() or die;
    GetOptions($app->optspec); # or die;

    isnt($app->{answer}, 41, "Number");
    isnt($app->{answer_is}, "Answer is 41", "Number with action");
    isnt($app->{question}->[1], "space", "List");
    isnt($app->{nature}->{Marvin}, "Sociable", "Hash");
}

done_testing;
