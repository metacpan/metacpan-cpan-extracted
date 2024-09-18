use Test::More;
use Lingua::EN::Inflexion;

# Smartmatching is on the way out...
no  if $] >= 5.017, warnings => "experimental::smartmatch";   # Grrrrrrr!!!
no  if $] >= 5.037, warnings => "deprecated::smartmatch";     # Grrrrrrrrrrrrrrr!!!
use if $] >= 5.041, 'Test::More', skip_all => 'No smartmatch in Perl 5.42+';

BEGIN { exit if $] >= 5.041; }

sub should_pass {
    my ($test, $desc) = @_;
    ok $test => "$desc\t(should pass)";
}

sub should_fail {
    my ($test, $desc) = @_;
    ok !$test => "$desc\t(should fail)";
}

while (my $test_case= readline(*DATA)) {
    my ($should_match, @words) = split /\s+/, $test_case;


    # Try all combinations...
    for my $word1 (@words) {
    for my $word2 (@words) {

        my $ok    = $should_match eq '+' || $word1 eq $word2 ? \&should_pass : \&should_fail;
        my $ok_eq =                         $word1 eq $word2 ? \&should_pass : \&should_fail;

        subtest "Smartmatching: $word1 ~~ $word2" => sub {
            $ok->(          (noun($word1) ~~ noun($word2) )  => "noun('$word1') ~~ noun('$word2')" );
            $ok->(          (     $word1  ~~ noun($word2) )  => "     '$word1'  ~~ noun('$word2')" );
            $ok->(          (noun($word1) ~~      $word2  )  => "noun('$word1') ~~      '$word2' " );
            done_testing();
        };
    }}
}


done_testing();

__DATA__
+ cat       cats      CAT       Cat     CaT
- cat       dog
+ cow       cows      kine
+ brother   brothers  brethren

