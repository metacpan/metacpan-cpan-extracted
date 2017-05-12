package Math::Palindrome;

#Yes, i'd like a dush good pratices
use strict;
use warnings;
#And I so like fucking everything
use Carp 'croak';
#Let's help you work more easy, if you can't you may not be here, get out

BEGIN {
    use Exporter;
    use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
    $VERSION     = '0.021';
    @ISA         = qw(Exporter);
    #Give a hoot don't pollute, do not export more than needed by default
    @EXPORT      = qw();
    @EXPORT_OK   = qw(is_palindrome
						next_palindrome 
						previous_palindrome
						increasing_sequence
						decreasing_sequence
						palindrome_after
						palindrome_before);
    %EXPORT_TAGS = (all => [ @EXPORT_OK ]);
}

###########################################################################################
# This cannot be export

# How many digits exist here 
sub _digits_size {return length shift}

#Working with just one digits
#If want a previous value
sub _previous_one_digits {
	my $n = shift;
	$n != 0 ? (return ($n - 1)) : croak "Just work with natural numbers!\n";	
}
#If want a next value 
sub _next_one_digits {
	my $n = shift;
	$n != 9 ? (return ($n + 1)) : (return 11);
}
#Finish, maybe one day I'll optimise 

#Now other stance, working with odd digits 
#for next 
sub _next_odd_digits {
	my $n = shift;
	my $r;
	
	my $n_1 = substr $n, 0, (length $n)/2; #first half part, without middle num(if exist)
	my $n_2 = substr $n, -((length $n)/2); #second half part, without middle num(if exist)
	my $n_3 = substr $n, 0, -((length $n)/2); #first half part, with middle num(if exist)
	
	if ($n == 999){$r = 1001}
	elsif ($n_1 <= reverse $n_2){
		$n_3++;
		$r = $n_3 . (reverse substr $n_3, 0, ((length $n_3)-1));
		
	}
	else{$r = $n_3 . (reverse substr $n_3, 0, ((length$n_3)-1))}
	
	return $r;
}
#for previous 
sub _previous_odd_digits {
	my $n = shift;
	my $r ;
	
	my $n_1 = substr $n, 0, (length $n)/2; #first half part, without middle num(if exist)
	my $n_2 = substr $n, -((length $n)/2); #second half part, without middle num(if exist)
	my $n_3 = substr $n, 0, -((length $n)/2); #first half part, with middle num(if exist)
	
	if ($n <= 101){$r = 99}
	elsif ($n_1 >= reverse $n_2){
		$n_3--;
		$r = $n_3 . (reverse substr $n_3, 0, ((length $n_3)-1));
		
	}
	else{$r = $n_3 . (reverse substr $n_3, 0, ((length$n_3)-1))}
	
	return $r;
}

#Finally, working with even number
#for next 
sub _next_even_digits {
	my $n = shift;
	my $r;
	
	my $n_1 = substr $n, 0, -((length $n)/2);#first half part
	my $n_2 = substr $n, ((length $n)/2); #second half part
	
	if ($n == 99){$r = 101}
	elsif ($n_1 <= reverse$n_2){
		$n_1++;
		$r = $n_1 . reverse $n_1;
	}
	else{$r = $n_1 . reverse $n_1}
	
	return $r;
}
#for previous 
sub _previous_even_digits {
	my $n = shift;
	my $r;
	
	my $n_1 = substr $n, 0, -((length $n)/2);#first half part
	my $n_2 = substr $n, ((length $n)/2); #second half part
	
	if ($n <= 11){$r = 9}
	elsif ($n_1 >= reverse $n_2){
		$n_1--;
		$r = $n_1 . reverse $n_1;
	}
	else{$r = $n_1 . reverse $n_1}
	
	return $r;
}
#End, without these part, nothing may work
##############################################################

##############################################################
#Now, all export functions
#confirm if the number is palindrome 
sub is_palindrome {($_[0] == reverse $_[0]) ? return 1 : return 0}
#require the next palindrome 
sub next_palindrome {
	my $num = shift;
	my $size = _digits_size($num);
	if ($size == 1){return _next_one_digits($num)}
	elsif ($size % 2 != 0){return _next_odd_digits($num)}
	else{return _next_even_digits($num)}
}
#require the previous palindrome 
sub previous_palindrome {
	my $num = shift;
	my $size = _digits_size($num);
	if ($size == 1){return _previous_one_digits($num)}
	elsif ($size % 2 != 0){return _previous_odd_digits($num)}
	else{return _previous_even_digits($num)}
}
#require a crescent sequence
sub increasing_sequence {
	my $len = $_[0];
	my $ini = $_[1] || 0;
	my @r;
	for (1..$len){
		$r[$_ - 1] = $ini = next_palindrome($ini)
	}
	return @r;
}
#require a decrescent sequence
sub decreasing_sequence {
	my $len = $_[0];
	my $ini = $_[1] || 100;
	my @r;
	for (1..$len){
		$r[$_ -1] = $ini = previous_palindrome($ini)
	}
	return @r;
}
#making more easy for the all asshole
#require just last number of the decreasing sequence
sub palindrome_before {
	my $len = $_[0];
	my $ini = $_[1] || 100;
	my $r;
	for (1..$len){
		$r = $ini = previous_palindrome($ini)
	}
	return $r;
}
#require just last number of the increasing sequence
sub palindrome_after {
	my $len = $_[0];
	my $ini = $_[1] || 0;
	my $r;
	for (1..$len){
		$r = $ini = next_palindrome($ini)
	}
	return $r;
}
#Everything is dust in the wind
#####################################################################


# Now the boring part, the documentation.


=head1 NAME

Math::Palindrome - Tool to manipulate palindromes numbers.

=head1 SYNOPSIS

  use Math::Palindrome qw/is_palindrome
						next_palindrome 
						previous_palindrome
						increasing_sequence
						decreasing_sequence
						palindrome_after
						palindrome_before/;
  
  my $n = 42; #We sujest never use '05', just '5'
  
  is_palindrome($n) ? print "TRUE" :print "FALSE"; # false!
  
  print next_palindrome($n); # 44
  
  print previous_palindrome($n); # 33
  
  #to increasing_sequence and decreasing_sequence insert 
  # the size of sequence
  my @sequence_01 = increasing_sequence(5, $n); # 44 55 66 77 88
  #or
  my @sequence_01 = increasing_sequence(5); # 1 2 3 4 5
  # default is 0 
  my @sequence_02 = decreasing_sequence(5, $n); # 33 22 11 9 8
  #or 
  my @sequence_02 = decreasing_sequence(5); # 99 88 77 66 55
  #default is 100
  
  my $last = palindrome_after(5, $n); # 88
  # is the same $last = increasing_sequence(5, $n); 
  # this is valid too
  my $last = palindrome_after(5); # 5
  
  my $first = palindrome_before(5, $n); # 8
  # is the same $first = decreasing_sequence(5, $n); 
  # this is valid too  
  my $first = palindrome_before(5); # 55


=head1 DESCRIPTION

This module is a alternative agains Math::NumSeq::Palindromes.
Can use this to find and confirm palindrome numbers.
In my tests it's work correctly with small and large numbers.
The most largest numbers was 9,99999 * 10^19. But, I think that its involved a memory capacity.
In this module, I used a deterministc method, maybe you can think that is a heuristic, but not.
I'm ready for fix a report bugs.

=head2 is_palindrome

 Usage     : is_palindrome($n)
 Purpose   : verify if the number is palindrome or not
 Returns   : return 1 if true or 0 if false
 Comment   : is the same:
  ($n == reverse $n) ? return 1 : return 0
=cut

=head2 next_palindrome

 Usage     : next_palindrome($n);
 Purpose   : return the next palindrome number after $n

=cut

=head2 previous_palindrome

 Usage     : previous_palindrome($n);
 Purpose   : return the previous palindrome number before $n

=cut

=head2 increasing_sequence

 Usage     : increasing_sequence($size, $first_value);
 Purpose   : return the crescent sequence of palindrome number after $n
 Argument  : $size is the number of palindromes that you want
           : $first_value is the number where it start to work, default it is 0 and never return the $first_value 
 Throws    : Don't return $first_value even it's palindrome
 Comment   : Use with array.


=cut

=head2 decreasing_sequence

 Usage     : decreasing_sequence($size, $first_value);
 Purpose   : return the decrescent sequence of palindrome number beforer $n
 Argument  : $size is the number of palindromes that you want
           : $first_value is the number where it start to work, default it is 100 and never return the $first_value 
 Throws    : Don't return $first_value even it's palindrome
 Comment   : Use with array;


=cut

=head2 palindrome_after

 Usage     : palindrome_after($size, $first_value);
 Purpose   : return the last number of crescent sequence of palindrome number beforer $n
 Argument  : $size is the number of palindromes that you want
           : $first_value is the number where it start to work, default it is 100 and never return the $first_value 
 Throws    : Don't return $first_value even it's palindrome
 Comment   : Is like:
  $n = increasing_sequence($s, $p);

 
=cut

=head2 palindrome_before

 Usage     : palindrome_before($size, $first_value);
 Purpose   : return the last number of decrescent sequence of palindrome number beforer $n
 Argument  : $size is the number of palindromes that you want
           : $first_value is the number where it start to work, default it is 0 and never return the $first_value 
 Throws    : Don't return $first_value even it's palindrome
 Comment   : Is like:
  $n = decreasing_sequence($s, $p);

=cut


=head1 THANKS
Bruno Buss and all community of rio.pm.org


=head1 AUTHOR

    Aureliano C. P. Guedes
    CPAN ID: acpguedes
    guedes.aureliano@gmail.com

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.


=head1 SEE ALSO

perl(1).

=cut

#################### main pod documentation end ###################

'Warning! The consumption of alcohol may cause you to think you have mystical kung-fu powers.';
