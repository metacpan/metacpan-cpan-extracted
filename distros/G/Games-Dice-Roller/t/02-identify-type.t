#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Test::Exception;

use_ok( 'Games::Dice::Roller' ); 
diag( "Testing the _identify_type internal subroutine" );
dies_ok { Games::Dice::Roller::_identify_type() } "expected to die without arguments";

# _identify_type does not dies with the following values
my @valid = (qw( 
					1d6 10d10 8d8+3 8d8+30 
					3d6kh2 3d6kl2 3d6dh1 3d6dl1 30d6kl20
					3d6r1 3d6x6 3d6cs4 3d6avg
					1d6+3 1d6-3 1d100+20 1d100-20
					
					3d6kh2+44 3d6kl2+44 3d6dh1+44 3d6dl1+44 30d6kl20+44
					3d6r1+44 3d6x6+44 3d6avg+44
					
			)); # 3d6cs4+44  no sense

foreach my $exp ( @valid ){
	ok ( Games::Dice::Roller::_identify_type($exp), "accepted expression [$exp]" );
}

# _identify_type dies with following values because they miss minimum requirement for a dice roll
my @not_valid_too_short = ( qw(
					x3 1d 1d+3 
));
foreach my $exp ( @not_valid_too_short ){
	dies_ok {Games::Dice::Roller::_identify_type($exp)} "rejected expression [$exp] - not a dice roll" ;
}

# _identify_type dies with following values because removes everything matched from original expression
# to spot remaining garbage
my @not_valid_malformed = ( qw(
					1d3+3+3 1d6klkl 1d6kl1kl 1d6k

));
foreach my $exp ( @not_valid_malformed ){
	dies_ok {Games::Dice::Roller::_identify_type($exp)} "rejected expression [$exp] - malformed dice roll" ;
}

# check fields of a simple dice expression
foreach my $simple (qw( 1d6 10d6 2d100 20d100 )){
	my $res = Games::Dice::Roller::_identify_type( $simple );
	if(	 $$res{type} eq "dice_expression" and defined $$res{dice_exp} ){
		fail "dice expression must contain only 2 fields" if grep{ defined $$res{$_} }(qw( comp_mod die_mod die_mod_val res_mod res_mod_val res_sum));
		pass "only correct fields in a simple dice expression [$simple]";
	}
}


# check fields of a keep/drop dice expression
foreach my $keepdrop (qw( 3d6kh2 3d6kl2 3d6dh1 3d6dl1 30d6kl20 )){
	my $res = Games::Dice::Roller::_identify_type( $keepdrop );
	if(	 	$$res{type} eq "dice_expression" 	and 
			defined $$res{dice_exp} 			and 
			defined $$res{res_mod} 				and 
			defined $$res{res_mod_val} 
	){
		fail "dice expression must contain only 3 fields" if grep{ defined $$res{$_} }(qw( comp_mod die_mod die_mod_val res_sum));
		pass "only correct fields in a keep/drop dice expression [$keepdrop]";
	}
}


# check fields of a r/x/cs/avg dice expression
foreach my $othermod (qw( 3d6r1 3d6x6 3d6cs4 3d6avg )){
	my $res = Games::Dice::Roller::_identify_type( $othermod );
	if(	 	$$res{type} eq "dice_expression" 	and 
			defined $$res{dice_exp} 			and 
			defined $$res{die_mod} 
	){														#avg does not require die_mod_val 
		fail "dice expression must contain only 3 fields" if 1 < grep{ defined $$res{$_} }(qw( comp_mod die_mod_val res_mod res_mod_val res_sum));
		pass "only correct fields in a r/x/cs/avg dice expression [$othermod]";
	}
}

# check fields of a summation dice expression
foreach my $summed (qw( 1d6+3 1d6-3 1d100+20 1d100-20 )){
	my $res = Games::Dice::Roller::_identify_type( $summed );
	#use Data::Dump; dd $res; #next;
	if(	 	$$res{type} eq "dice_expression" 	and 
			defined $$res{dice_exp} 			and 
			defined $$res{res_sum} 
	){														#avg does not require die_mod_val 
		fail "dice expression must contain only 3 fields" if grep{ defined $$res{$_} }(qw( comp_mod die_mod die_mod_val res_mod res_mod_val ));
		pass "only correct fields in a summation dice expression [$summed]";
	}
}


# check fields of a keep/drop with summation dice expression
foreach my $kdsummed (qw( 3d6kh2+44 3d6kl2+44 3d6dh1+44 3d6dl1+44 30d6kl20+44 )){
	my $res = Games::Dice::Roller::_identify_type( $kdsummed );
	#use Data::Dump; dd $res; #next;
	if(	 	$$res{type} eq "dice_expression" 	and 
			defined $$res{dice_exp} 			and 
			defined $$res{res_mod} 				and
			defined $$res{res_mod_val} 			and
			defined $$res{res_sum} 
	){														#avg does not require die_mod_val 
		fail "dice expression must contain only 5 fields" if grep{ defined $$res{$_} }(qw( comp_mod die_mod die_mod_val ));
		pass "only correct fields in a keep/drop with summation dice expression [$kdsummed]";
	}
}


# check fields of a r/x/cs/avg with summation dice expression
foreach my $othermodsum (qw( 3d6r1+44 3d6x6+44 3d6avg+44 )){
	my $res = Games::Dice::Roller::_identify_type( $othermodsum );
	if(	 	$$res{type} eq "dice_expression" 	and 
			defined $$res{dice_exp} 			and 
			defined $$res{die_mod} 				and
			defined $$res{res_sum} 
	){														#avg does not require die_mod_val 
		fail "dice expression must contain only 4 fields" if 1 < grep{ defined $$res{$_} }(qw( comp_mod die_mod_val res_mod res_mod_val ));
		pass "only correct fields in a r/x/cs/avg with summation dice expression [$othermodsum]";
	}
}


done_testing;
 


























