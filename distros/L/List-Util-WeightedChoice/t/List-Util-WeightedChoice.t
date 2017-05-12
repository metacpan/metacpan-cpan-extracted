# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl List-Util-WeightedChoice.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test;
BEGIN { plan tests => 5};
use List::Util::WeightedChoice qw(choose_weighted);
ok(1); # If we made it this far, we're ok.

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.


my $choicesAref = [ 'Not so much', 'Popular','Unpopular'];
my %allChoices = map { ($_=>1)} @$choicesAref;
my $weightsAref = [ 2, 50, 1] ;
my $choice = choose_weighted( $choicesAref, $weightsAref );

ok($allChoices{$choice});	# 2
$choice ='';
for(1..40){
    $choice = choose_weighted( $choicesAref, $weightsAref );
    last if $choice eq 'Popular';
}
ok( $choice eq 'Popular');	# 3

my $complexChoices = [ 
    {val=>"Not so much", weight=>2},
    {val=>"Popular", weight=>50},
    {val=>"Unpopular", weight=>1},
    ];

$choice = choose_weighted($complexChoices, sub{ $_[0]->{weight} } );
ok($choice->{val});		# 4

$choice = undef;
for(1..40){
    $choice = choose_weighted( $complexChoices, sub{ $_[0]->{weight} } );
    last if $choice->{val}  eq 'Popular';
}
ok( $choice->{val} eq 'Popular');	# 5
