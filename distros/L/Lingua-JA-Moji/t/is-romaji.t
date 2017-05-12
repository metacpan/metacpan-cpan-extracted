use warnings;
use strict;
use Test::More;
use Lingua::JA::Moji 'is_romaji';

my @tests = (
{
    word => 'Maractite',
    is => undef,
},
{
    word => 'WHO',
    is => 'uxo',
},
{
    word => 'who',
    is => 'uxo',
},
{
    word => 'thya',
    is => undef,
},
{
    word => 'thy',
    is => undef,
},
{
    word => 'rojji',
    is => 'rozzi',
},
);

run (@tests);
TODO: {
    local $TODO = 'bugs';
    my @bug_tests = (
    );
    run (@bug_tests);
}
done_testing ();
exit;

sub run
{
    my (@list) = @_;
    for my $test (@list) {
        my $message = "'$test->{word}' is ";
	if (! $test->{is}) {
	    $message .= "not ";
	}
	$message .= " romaji.";
        is (is_romaji ($test->{word}), $test->{is}, $message);
    }
}

