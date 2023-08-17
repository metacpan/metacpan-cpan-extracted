use Test::More;
use Lingua::EN::Inflexion;

use if $] < 5.012, 'Test::More', skip_all => 'No regex coercions in Perl 5.10 or earlier';
BEGIN { exit if $] < 5.012 }

sub should_pass {
    my ($test, $desc) = @_;
    ok $test => "$desc\t(should pass)";
}

sub should_fail {
    my ($test, $desc) = @_;
    ok !$test => "$desc\t(should fail)";
}

while (my $test_case = readline(*DATA)) {
    my ($should_match, @words) = split /\s+/, $test_case;


    # Try all combinations...
    for my $word1 (@words) {
    for my $word2 (@words) {

        my $ok    = $should_match eq '+' || $word1 eq $word2 ? \&should_pass : \&should_fail;
        my $ok_eq =                         $word1 eq $word2 ? \&should_pass : \&should_fail;

        subtest "Regex matching: $word1 =~ $word2" => sub {
            $ok->(    scalar(noun($word1) =~ noun($word2) )  => "noun('$word1') =~ noun('$word2')" );
            $ok->(    scalar(     $word1  =~ noun($word2) )  => "     '$word1'  =~ noun('$word2')" );
            $ok_eq->( scalar(noun($word1) =~    /^$word2$/)  => "noun('$word1') =~      '$word2' " );
            done_testing();
        } if $] >= 5.012;
    }}
}


done_testing

__DATA__
+ cat       cats      CAT       Cat     CaT
- cat       dog
+ cow       cows      kine
+ brother   brothers  brethren
