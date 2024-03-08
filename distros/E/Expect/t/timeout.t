use strict;
use warnings;

use Test::More tests => 2;
use Expect;

my $Perl = $^X;
my $slow_program = "$Perl t/utils/slow-interaction.pl";

subtest "implicit timeout" => sub {
	plan tests => 1;

	my $exp = Expect->spawn($slow_program);
    $exp->timeout(10);
	$exp->log_user(0);

	$exp->expect( 
        [ "string to transform", sub { $_[0]->send("banana\n") } ]
    );

	is $exp->expect( "BANANA" ) => 1;
};

subtest "undef as timeout" => sub {
	plan tests => 2;

    subtest "no explicit timeout, we get default" => sub {
        my $exp = Expect->spawn($slow_program);
        $exp->timeout(1);
        $exp->log_user(0);

        # no explicit timeout, we get the default of '1' and fail
        is $exp->expect( 
            [ "string to transform", sub { $_[0]->send("banana\n") } ]
        ) => undef;
    };

    subtest "explicit timeout, we wait forever" => sub {
        my $exp = Expect->spawn($slow_program);
        $exp->timeout(1);
        $exp->log_user(0);

        is $exp->expect( undef,
            [ "string to transform", sub { $_[0]->send("banana\n") } ]
        ) => 1;
    };

};
