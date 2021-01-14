package Games::Dice::Roller;

use 5.010;
use strict;
use warnings;

use Carp;

our $VERSION = '0.03';
our $debug = $ENV{DICE_ROLLER_DEBUG} // 0;

sub new{
	my $class = shift;
	my %opts = @_;
	if ( defined $opts{sub_rand} ){
		croak "sub_rand must be a code reference meant to replace core rand function"
			unless ref $opts{sub_rand} eq 'CODE';
	}
	return bless {
		sub_rand =>  $opts{sub_rand} // sub{ rand($_[0]) },
	}, $class;
}


sub roll{
	my $self = shift;
	my $arg = shift;
	croak "roll method expects one argument" unless $arg;
	croak "roll method expects a single string argument" if @_;
	
	# trim spaces
	$arg =~ s/^\s+//;
	$arg =~ s/\s+$//;
	
	# check if we received a dice pool
	my @args = split /\s+/, $arg;
	
	# a dice pool
	if ( scalar @args > 1 ){
		# transform each one in resulting hashref returned by _identify_type
		@args = map { _identify_type($_) } @args;
		@args = _validate_pool( @args );
		# transform each dice expression in its resulting format
		foreach my $ele( @args ){
			next unless $ele->{type} eq 'dice_expression';
			my ($res, $descr) = $self->roll( $ele->{original} );
			$ele = { result => $res, result_description => $descr, original => $ele->{original}};
		}
		# is the last element 
		my $global_modifier = pop @args;
		my @sorted = sort{ $a->{result} <=> $b->{result} }@args;
		@sorted = reverse @sorted if $global_modifier->{value} eq 'kh';
		my $global_result = $sorted[0]->{result};
		my @global_descr  = ( 
								($sorted[0]->{original} ? $sorted[0]->{original} : $sorted[0]->{result}).
								($sorted[0]->{result_description} ? " = $sorted[0]->{result_description}": '') 
		);
		shift @sorted;
		push @global_descr, "( ".
							($_->{original} ? $_->{original} : '').
							($_->{result_description}?" = $_->{result_description} = ":'').
							($_->{result}?"$_->{result} ":'').
							")" for @sorted;
		
		return ($global_result, join ', ',@global_descr);
		
	}
	# a single dice expression
	else{
		# transform it in a hashref as returned by _identify_type
		# this will be returned as third element
		my $ref = _identify_type( shift @args );

		# used to accumulate partial results and descriptive string elements
		my ( @partial, @descr );
		
		my ($times, $sides) = split 'd', $ref->{dice_exp};
		while( $times > 0 ){
			
			my $single_res;
			
			# BARE DICE EXPRESSION
			unless ( $ref->{die_mod} ){
				$single_res = $self->single_die( $sides );
				push @partial, $single_res;
				push @descr, $single_res;
				$times--;
				next;
			}
			
			# DIE MODIFIERS #
			# avg does not require further processing
			if ( $ref->{die_mod} and $ref->{die_mod} eq 'avg' ){
					$single_res = (1 + $sides) / 2;
					push @partial, $single_res;
					push @descr, $single_res;
					$times--;
					next;
			}
			# if r x cs roll the die
			else{ 
					$single_res = $self->single_die( $sides ); 
			}
			# process r x cs die modifiers
			# if r 
			if ( $ref->{die_mod} and $ref->{die_mod} eq 'r' ){
				my $comp_num = $ref->{die_mod_val};
				my $comp_op = $ref->{comp_mod};
				# check if it must be rerolled
				if(		
					(not defined $ref->{comp_mod} and $single_res == $comp_num) 							or
					(defined $ref->{comp_mod} and $ref->{comp_mod} eq 'lt' and $single_res < $comp_num )	or
					(defined $ref->{comp_mod} and $ref->{comp_mod} eq 'gt' and $single_res > $comp_num )
				){
					# REROLL
					push @descr,"($single_res"."r)";
					next;
				}
				else{
					push @descr, $single_res;
					push @partial, $single_res;
					$times--;
					next;
				}
			} # end of r check
			# if x 
			if ( $ref->{die_mod} and $ref->{die_mod} eq 'x' ){
				my $comp_num = $ref->{die_mod_val};
				my $comp_op = $ref->{comp_mod};
				# check if it must be exploded
				if(		
					(not defined $ref->{comp_mod} and $single_res == $comp_num) 							or
					(defined $ref->{comp_mod} and $ref->{comp_mod} eq 'lt' and $single_res < $comp_num )	or
					(defined $ref->{comp_mod} and $ref->{comp_mod} eq 'gt' and $single_res > $comp_num )
				){
					# EXPLODE
					push @descr,$single_res."x";
					push @partial, $single_res;
					next;
				}
				else{
					push @descr, $single_res;
					push @partial, $single_res;
					$times--;
					next;
				}
				
			} # end of x check
			
			# if cs
			if ( $ref->{die_mod} and $ref->{die_mod} eq 'cs' ){
				my $comp_num = $ref->{die_mod_val};
				my $comp_op = $ref->{comp_mod};
				# initialize partial with zero succes
				push @partial, 0;
				# check if it is success
				if(		
					(not defined $ref->{comp_mod} and $single_res == $comp_num) 							or
					(defined $ref->{comp_mod} and $ref->{comp_mod} eq 'lt' and $single_res < $comp_num )	or
					(defined $ref->{comp_mod} and $ref->{comp_mod} eq 'gt' and $single_res > $comp_num )
				){
					# SUCCESS
					push @descr,$single_res;
					push @partial, 1;
					$times--;
					next;
				}
				else{
					push @descr, "($single_res)";
					$times--;
					next;
				}
			} # end of cs check
		} # end of while loop
		
		# RESULT MODIFIERS kh kl dh dl #
		if ( $ref->{res_mod} and $ref->{res_mod} =~/^(?:kh|kl|dh|dl)$/ ){
			my @wanted;
			my @dropped;
			# sort from lowest to highest partial, temporary results
			my @sorted = sort{ $a <=> $b }@partial;
			
			# kh and kl
			if ( $ref->{res_mod} eq 'kh' or $ref->{res_mod} eq 'kl'){
				# reverse if highest are needed
				@sorted = reverse @sorted if $ref->{res_mod} eq 'kh';
				# reset partial result array
				undef @partial;
				# unshift n highest values shortening @sorted
				unshift @partial, shift @sorted for 1..$ref->{res_mod_val};
				# consume what left in sorted to modify description
				while ( my $tobedropped = shift @sorted ){
					foreach my $ele( @descr ){
						if ( $ele eq $tobedropped ){
							$ele = "($ele)";
							last;
						}
					}				
				}
			@descr = reverse @descr if $ref->{res_mod} eq 'kl';
			} # end kh kl check
			
			# dh and dl
			if ( $ref->{res_mod} eq 'dh' or $ref->{res_mod} eq 'dl'){
				# reverse if lowest are needed
				@sorted = reverse @sorted if $ref->{res_mod} eq 'dl';
				# reset partial result array
				undef @partial;
				# unshift n highest values shortening @sorted
				unshift @partial, shift @sorted for 1 .. ( scalar @sorted - $ref->{res_mod_val} );
				# consume what left in sorted to modify description
				while ( my $tobedropped = shift @sorted ){
					foreach my $ele( $ref->{res_mod} eq 'dl' ? reverse @descr : @descr ){
						if ( $ele eq $tobedropped ){
							$ele = "($ele)";
							last;
						}
					}				
				}
			@descr = reverse @descr if $ref->{res_mod} eq 'dh';
			} # end dh dl check
		
		} # end of result modifiers processing
		
		# RESULT SUMMATION
		if ( $ref->{res_sum} ){
			push @descr, $ref->{res_sum};
			push @partial, $ref->{res_sum};
		}
				
		# COMPUTE RESULT AND DESCRIPTION
		# add them to the $ref detailed result hasref
		$ref->{result} += $_ for @partial;
		$ref->{result_description} = join ' ', @descr;
		
		print "Description: $ref->{result_description}\nResult     : $ref->{result}\n\n" if $debug;
		
		return ($ref->{result}, $ref->{result_description}, $ref);
	} # end of single dice expression evaluation
}

sub single_die{
	my $self = shift;
	my $sides = shift;
	croak "single_die expect one argument" unless $sides;
	croak "Invalid side [$sides]" unless $sides =~/^(\d+)$/;
	$sides = $1;
	return 1 + int( $self->{sub_rand}($sides) );
}

sub _validate_expr{
	my $result = shift;

	# NB: see ./t/04-validate-expr.t
	# many of the following check are never reached
	
	# die_mod = avg 
	if ( $result->{die_mod} and $result->{die_mod} eq 'avg' ){
		croak "with avg no result modification (k|d) are admitted. OK: 3d8avg NO: 3d8avgkh" if $result->{res_mod};
		croak "with avg no comparison modifiers (gt|lt) are admitted. OK: 3d8avg NO: 3d8avglt" if $result->{comp_mod};
		croak "with avg no modification value (number) is admitted. OK: 3d8avg NO: 3d8avg3" if $result->{die_mod_val};
	}
	# die_mod = cs
	if ( $result->{die_mod} and $result->{die_mod} eq 'cs' ){
		croak "with cs no result modification (k|d) are admitted. OK: 3d8cs3 NO: 3d8cs3kl" if $result->{res_mod};
		croak "with cs a number must be also specified. OK: 3d8cs2 NO: 3d8cs" unless $result->{die_mod_val};
		croak "with cs no sum are permitted. OK: 3d8cs2 NO: 3d8cs2+12" if $result->{res_sum};
	}
	# die_mod = x
	if ( $result->{die_mod} and $result->{die_mod} eq 'x' ){
		croak "with x no result modification (k|d) are admitted. OK: 3d8x8 NO: 3d8x8kl" if $result->{res_mod};
		croak "with x a number must be also specified. OK: 3d8x8 NO: 3d8x" unless $result->{die_mod_val};		
	}
	# die_mod = r
	if ( $result->{die_mod} and $result->{die_mod} eq 'r' ){
		croak "with r a number must be also specified. OK: 3d8r1 NO: 3d8r" unless $result->{die_mod_val};		
	}
	# comp_mod = gt|lt
	if ( $result->{comp_mod} and $result->{comp_mod} =~/^(?:gt|lt)$/ ){
		croak "a comparison modifier (lt or gt) can only be used with r x and cs. OK: 3d8rlt2 NO: 3d8avglt4" unless $result->{die_mod} =~ /^(?:r|x|cs)$/;		
	}
	# res_mod = kh|kl|dh|dl
	if ( $result->{res_mod} and $result->{res_mod} =~/^(?:kh|kl|dh|dl)$/ ){
		croak "a result modifier (kh, kl, dh and dl) can only be used with number after it. OK: 3d8kh2 NO: 3d8kl" unless $result->{res_mod_val};
		croak "a result modifier (kh, kl, dh and dl) cannot be used with a die modifier (r, x, cs or avg) OK: 3d8kh2 NO: 3d8x7kh3" if $result->{die_mod};
		croak "a result modifier (kh, kl, dh and dl) cannot be used with a comparison modifier (lt or gt). OK: 3d8kh2 NO: 3d8khlt2" if $result->{comp_mod};
		my $dice_num = $1 if $result->{dice_exp}=~ /^(\d+)d/;
		croak "too many dice to keep or drop ($dice_num) in $result->{dice_exp}" if $result->{res_mod_val} >= $dice_num;
	}
	# res_sum = +3|-3
	if ( $result->{res_sum} and $result->{res_sum} =~ /^[+-]\d+$/){
		croak "a result sum cannot be used when cs is used" if defined $result->{die_mod} and $result->{die_mod} eq 'cs';		
	}
}

sub _validate_pool{
	my @args = @_;
	# type => 'number'
	# type => 'global_modifier'
	# type => 'dice_expression'
	
	croak "too many bare number in dice pool" if 1 < grep{ $_->{type} eq 'number' }@args;
	croak "too many global modifiers (kh or kl) in dice pool" if 1 < grep{ $_->{type} eq 'global_modifier' }@args;
	# deafult to kh
	push @args, { type => 'global_modifier', value => 'kh' } if 0 == grep{ $_->{type} eq 'global_modifier' }@args;
	croak "global modifiers (kh or kl) must be the last element in a dice pool" unless $args[-1]->{type} eq 'global_modifier';
	return @args;
}

sub _identify_type{
	my $exp = shift;
	croak "_validate_type expects one argument" unless $exp;
	
	print "\nEvaluating [$exp]\n" if $debug;

	# we got a dice expression, complex at will
	
	# dice_exp 		1d6
	# res_mod 		kh kl dh dl
	# res_mod_val 	\d+
	# die_mod 		r x cs avg
	# comp_mod 		gt lt (null stands for eq)
	# die_mod_val 	\d+
	# res_sum		+3 -13
	
	if( $exp =~ /
					^
					(?<dice_exp>\d+d\d+)				# a mandatory dice expression as start 	1d6
					(									# an optional res_mod group				
						(?<res_mod>(?:kh|kl|dh|dl))			# with a res_mod  					kh|kl|dh|dl
						(?<res_mod_val>\d+)					# and with a mod_val				3
					)?
					(									# an optional die_mod
						(?<die_mod>(?:r|x|cs|avg))			# with a die_mod					r|x|cs|avg	
						(?<comp_mod>(?:gt|lt))?				# an optional comp_mod				gt|lt
						(?<die_mod_val>\d{0,})				# and an optional die_mod_val		3
					)?
					(									# an optional res_sum
						(?<res_sum>[+-]{1}\d+)				# with a res_mod 					+|-3
					)?
					
				/x
	){
		if ( $debug ){
			print "\toriginal           : [$exp]\n";
			print "\ttype               : [dice_expression]\n";
			print "\tdice expression    : [$+{dice_exp}]\n";
			print "\tresult modifier    : [$+{res_mod}]\n" if $+{res_mod};
			print "\tresult val modifier: [$+{res_mod_val}]\n" if $+{res_mod_val};
			print "\tdie modifier       : [$+{die_mod}]\n" if $+{die_mod};
			print "\tdie comp modifier  : [$+{comp_mod}]\n" if $+{comp_mod};
			print "\tdie val modifier   : [$+{die_mod_val}]\n" if $+{die_mod_val};
			print "\tresult sum         : [$+{res_sum}]\n" if $+{res_sum};
		}
		
		# save the hashref output ( $+{KEY} cannot be reused inside a later s/// )
		my $result = { 
					type 		=> 'dice_expression',
					original	=>	$exp,
					dice_exp	=>	$+{dice_exp},
					res_mod		=>	$+{res_mod},
					res_mod_val	=>	$+{res_mod_val},
					die_mod		=>	$+{die_mod},
					comp_mod	=>	$+{comp_mod},
					die_mod_val	=>	$+{die_mod_val},
					res_sum		=>	$+{res_sum},					
		};
		
		# remove everything matched from original expression..
		my $tobenull = $exp;
		print "Cleaning the expression to spot garbage:\n" if $debug;
		# 'type' key unuseful, dice_exp must be the first to be removed or a lone number can modify it
		foreach my $key ( qw( dice_exp res_mod res_mod_val die_mod comp_mod die_mod_val res_sum) ){
			print "\tremoving: $result->{$key}\n" if defined $result->{$key} and $debug;
			$tobenull =~ s/\Q$result->{$key}\E// if defined $result->{$key};
		}
		print "Left in the expression: [$tobenull]\n" if $debug;
		# ..to spot unwanted remaining crumbles
		croak "unexpected string [$tobenull] in expression [$exp]" if length $tobenull;
		
		_validate_expr( $result );
		return $result;
	}
	# we got a bare number (can be used in dice pool)
	elsif ( $exp =~ /^\d+$/ ){
		print "received a bare number [$exp] used in dice pools\n" if $debug;
		return { type => 'number', result => $exp };
	}
	# we got a global dice pool modifier
	elsif( $exp =~ /^kh|kl$/){
		print "received a global dice modifier [$exp] used in dice pools\n" if $debug;
		return { type => 'global_modifier', value => $exp };
	}
	else{
		croak "unrecognized expression [$exp]";
	}	
}


1; # End of Module


=head1 NAME

Games::Dice::Roller - a full featured dice roller system

=head1 VERSION

Version 0.01

=cut

=head1 SYNOPSIS

	use Games::Dice::Roller;

	my $dice = Games::Dice::Roller->new();

	# simple dice expressions
	my @simple = (qw( 3d6 4d8+4 1d100-5 ));

	# average results
	my @average = (qw(4d4avg 4d8avg+2 4d12avg-7));

	# reroll if equal (default), lesser than or greater than N
	my @reroll = (qw(6d4r1 5d6rlt3 5d6rgt4 6d4r1+10 6d4r1-5));

	# explode if equal (default), lesser than or greater than N 
	my @explode = (qw( 3d6x6 3d6xlt3 3d6xgt4 3d6x6+3 3d6x6-4 ));

	# just count succesful rolls
	my @succes = (qw( 3d6cs1 3d6cslt3 3d6csgt4 ));

	# keep and drop dice from final results
	my @keep_and_drop = (qw( 4d6kh3 4d6kh2 4d6kl2+3 4d6kl2-3 4d12dh1 4d12dl3 4d12dl3+3 4d12dl1-4 ));
	

	foreach my $dice_expression ( @simple , @average, @reroll, @explode, @succes, @keep_and_drop ){

		my ($res, $descr) = $dice->roll( $dice_expression );
		print "$res [$dice_expression] $descr\n";
	}



	# 10 [3d6] 5 2 3
	# 22 [4d8+4] 7 7 1 3 +4
	# 14 [1d100-5] 19 -5
	# 10 [4d4avg] 2.5 2.5 2.5 2.5
	# 20 [4d8avg+2] 4.5 4.5 4.5 4.5 +2
	# 19 [4d12avg-7] 6.5 6.5 6.5 6.5 -7
	# 18 [6d4r1] 4 (1r) 3 2 3 (1r) 2 4
	# 19 [5d6rlt3] 3 4 3 4 (2r) (2r) (2r) 5
	# 11 [5d6rgt4] 2 4 1 (5r) 2 (5r) 2
	# 25 [6d4r1+10] (1r) 2 (1r) 2 2 4 3 2 +10
	# 13 [6d4r1-5] (1r) (1r) 2 (1r) 2 4 4 (1r) 4 2 -5
	# 7 [3d6x6] 1 1 5
	# 17 [3d6xlt3] 6 5 1x 1x 1x 3
	# 11 [3d6xgt4] 4 3 4
	# 11 [3d6x6+3] 2 2 4 +3
	# 8 [3d6x6-4] 5 3 4 -4
	# 1 [3d6cs1] (5) (3) 1
	# 1 [3d6cslt3] 2 (6) (6)
	# 2 [3d6csgt4] 6 (3) 5
	# 14 [4d6kh3] (2) 6 4 4
	# 9 [4d6kh2] 3 6 (2) (2)
	# 8 [4d6kl2+3] (6) 4 1 (6) +3
	# 1 [4d6kl2-3] (5) 1 3 (3) -3
	# 13 [4d12dh1] 2 6 5 (6)
	# 12 [4d12dl3] (9) (10) (9) 12
	# 9 [4d12dl3+3] (1) 6 (3) (6) +3
	# 26 [4d12dl1-4] 9 (1) 9 12 -4

	

=head1 METHODS


=head2 new

The constructor accept only one option, an anonymous hash and the only valid key is C<sub_rand> holding as value an anonymous sub to be invoked instead of the core function L<rand|https://perldoc.perl.org/functions/rand>


=head2 roll

This method expects a single string to be passed as argument. This string can be a C<single dice expression> or a C<dice pool> (see below).

It returns the final result and a string representing the roll.


	my $result = $dice->roll('3d6+3');
	print "result of the dice roll was: $result"; 
	# result of the dice roll was: 16
	
	my ($res, $descr) = $dice->roll('3d6+3');
	print "$descr\nResult: $res";
	# 5 2 6 +3
	# Result: 16

In the descriptive string some die result can be modified by modifiers: dropped ones will be inside parens, rerolled dice result will be inside parens and with a C<r> following them and exploded dice results will be marked by a C<x>	

A third element is returned too: a hash reference intended to be used mainly internally and for debug purposes, with the internal carateristics of the dice expression. Dont rely on this because it can be changed or removed in future releases.

=head3 die modifiers

=head4 avg - average

No dice are rolled, but the die average will be used instead. For  C<1d6> the average will be C<3.5> so C<4d6avg> will always result in C<14>

=head4 r - reroll

Reroll dice equal, lesser than (C<lt>) or greater than (C<gt>) C<n> as in C<3d6r1 3d6rlt3 3d6rgt4> 
Each die rerolled will be not part of the final result and in the descriptive string will be inside parens and followed by C<r> as in C<(1r)> 

=head4 x - explode

Each die roll equal, lesser than (C<lt>) or greater than (C<gt>) C<n> (as in C<3d6x6 3d6xlt3 3d6xgt4>) will add another die of the same type.
An exploded die will be added to final result and will be marked with  C<x> as in C<6x> in the descriptive string. 

For example C<8d6xgt4> can lead to a result of C<42> and a description like: C<6x 4 6x 4 5x 3 5x 3 2 2 1 1>


=head4 cs - count successes

If a die roll is equal, lesser than (C<lt>) or greater than (C<gt>) C<n> (as in C<3d6cs1 3d6cslt3 3d6gt4>) then it will count as a success.
The final result will be the succes count.
In the decription string unsuccesfull rolls will be inside parens.




=head3 result modifiers

=head4 keep and drop

With the result modifiers C<kh kl dh dl> you can choose how many dice will be used to compute the final result, keeping or dropping highest or lowest C<n> dice.
For example C<4d6kh3> will roll C<4d6> but only best three ones will be used.
The descriptive string in this case will be always ordered in ascending or descending order, without representing the real occurence of numbers.


=head4 result sum

An optional sum C<n> can be added to the final result as positive or negative modifier. This must be the last element of the dice expression like in: C<3d8+4>
This option cannot be used with C<cs> 





=head3 dice pools


If to the C<roll> method is passed a string containing different things (separated by spaces) this string will be treated as a C<dice pool>

A C<dice pool> must contain at least two elements. It can contains one or more C<dice expression> (explained above), no or one and only one C<bare number> and no, one and only one C<global result modifier> ( C<kh> for keep highest or C<kl> for keep lowest).

All results of C<dice expressions> are computed and compared each other and with an eventual C<bare number> and the result of the C<dice pool> will be the highest (if no C<global result modifier> then C<kh> will be the default) or lowest one (if C<kl> is specified) roll among them.

For example: C<$dice-E<gt>roll('4d4+6 3d6+2 2d8+1 12')> can lead to the following results (default C<global result modifier> is C<kh>):

	# Result: 14
	# Description: 4d4+6 = 1 2 1 4 +6, ( 3d6+2 = 4 3 4 +2 = 13 ), ( 12 ), ( 2d8+1 = 1 8 +1 = 10 )

As you can see descriptions of discarded C<dice expression> or eventual C<bare numbers> (C<12> in the example) lower than the higher result are represented inside parens.
	
	
=head2 about rand 

Some ancient perl on some unfortunate OS has proven to have problem with the core C<rand> even if nowadays this is very rare to appear. In this case you can provide your own C<rand> function during the constructor, for example using L<Math::Random::MT> as in the following example:

	my $gen = Math::Random::MT->new();
	my $mt_dicer =  Games::Dice::Roller->new(
		sub_rand => sub{ 
				my $sides = shift; 
				return $gen->rand( $sides );			
		},
	);

See the thread at L<perlmonks|https://perlmonks.org/?node_id=11126201> where this argument was discussed.

=head1 DEBUG

This module can produce debug informations if C<DICE_ROLLER_DEBUG> environment variable is set to C<1>

Under debug rolling a dice expression will produce something like:

	Evaluating [12d6kh4+3]
			original           : [12d6kh4+3]
			type               : [dice_expression]
			dice expression    : [12d6]
			result modifier    : [kh]
			result val modifier: [4]
			result sum         : [+3]
	Cleaning the expression to spot garbage:
			removing: 12d6
			removing: kh
			removing: 4
			removing: +3
	Left in the expression: []
	Description: 6 6 5 5 (4) (4) (3) (3) (2) (2) (1) (1) +3
	Result     : 25



=head1 AUTHOR

LorenzoTa, C<< <LORENZO at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-games-dice-roller at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Games-Dice-Roller>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

The main support site for the present module is L<https://perlmonks.org> where I can be found as Discipulus

You can find documentation for this module with the perldoc command.

    perldoc Games::Dice::Roller

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Games-Dice-Roller>


=item * Search CPAN

L<https://metacpan.org/release/Games-Dice-Roller>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2021 LorenzoTa.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut
