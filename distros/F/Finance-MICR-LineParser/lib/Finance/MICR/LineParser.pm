package Finance::MICR::LineParser;
use strict;
use Carp;
use warnings;
our $VERSION = sprintf "%d.%02d", q$Revision: 1.7 $ =~ /(\d+)/g;

sub new {
	my ($class,$self) = (shift,shift);
	$self ||= {};
	$self->{string} or croak('missing string argument to constructor');
	
	$self->{transit_symbol}		||='T';
	$self->{on_us_symbol}		||='U';
	$self->{ammount_symbol}		||='X';
	$self->{dash_symbol}			||='D';
	
	$self->{max_clean_runs} ||= 6;	 	
	
	bless $self, $class;

	$self->{original_string} = $self->{string};

	until( $self->_match or $self->giveup) {
		$self->_clean_string; # returns 0 if it should not clean anymore
	}

	# $self->{return_my_symbols} ||=0; # later

	return $self;
}

sub tolerant {
	my $self = shift;
	(defined $self->{tolerant}) or ($self->{tolerant} = 1);	# could be 0	
	return $self->{tolerant};
}


sub _match {
	my $self = shift;
	if ($self->_business_check_match){ return 1;} # will not run if max_clean_runs HAS been reached
	if ($self->_personal_check_match){ return 1;} # will not run if max_clean_runs HAS been reached
	if ($self->_unknown_check_match ){ return 1;} # will not run if max_clean_runs has NOT been reached & tolerant is true
	return 0;
}


sub clean_runs {
	my $self = shift;
	$self->{_clean_runs} ||= 0;
	return $self->{_clean_runs};
}

sub max_clean_runs {
	my $self = shift;	
	return $self->{max_clean_runs};
}


sub _clean_string {
	my $self = shift;
	
	if( $self->clean_runs > $self->max_clean_runs ){
		return 0;
	} 

	if ($self->clean_runs == 0){	
		my ($u,$t,$a,$d) = ($self->{on_us_symbol}, $self->{transit_symbol}, $self->{ammount_symbol}, $self->{dash_symbol});		
		if ($t ne 'T'){
				$self->{string}=~s/$t/T/g;
		}
		if ($u ne 'U'){
				$self->{string}=~s/$u/U/g;
		}
		if ($a ne 'X'){
				$self->{string}=~s/$a/X/g;
		}
		if ($d ne 'D'){
				$self->{string}=~s/$d/D/g;
		}			
	}
	
	elsif ($self->clean_runs == 1){	
		$self->{string} =~s/\s+//g;		
	}

	elsif ($self->clean_runs == 2){	
		$self->{string} =~s/_|\-//g;		
	}

	elsif ($self->clean_runs == 3){	
		$self->{string} =~s/[^0123456789TUXD]//g;		
	}

	elsif ($self->clean_runs == 4){
		if( $self->{string}=~m/(T[0123456789TUXD]+U)/ ){ # business check # realize if there's a trailing X (ammount) this will fail
			$self->{string} = $1;
		}
		elsif ( $self->{string}=~m/(U[0123456789TUXD]+U[0123456789TUXD]*)/){
			$self->{string} = $1;
		}		
	}

	$self->{_clean_runs}++;
	return 1;
}


sub giveup {
	my $self = shift;
	$self->{_giveup} ||=0;
	return $self->{_giveup};	
}





# -------------------------------------------
# BEGIN MAIN MATCHERS
# ALL MAIN MATCHING IS DONE IN THESE TWO SUBS
# if they both fail continuosly, then we dont assume to 
# succeed

sub _business_check_match {
	my $self= shift;
	my $string = $self->{string};
	
	if($string =~/(U[\dD]+U)[\-_\s]*(T\d{9}T)[\-_\s]*([\dD ]+U[\-_\s]*[\dD ]*)/){
		$self->_set_check_type('business');	
		$self->{auxiliary_on_us} = $1; $self->{auxiliary_on_us}=~s/\s{2,}/ /g;
		$self->{transit} = $2; $self->{transit}=~s/\s{2,}/ /g;
		$self->{on_us} = $3; $self->{on_us}=~s/\s{2,}/ /g;
		return 1;		
	}
	return 0;
}

sub _personal_check_match {
	my $self= shift;
	my $string = $self->{string};
   
	#insist that a valid personal check have trailing digits after the U
	if ($string =~/(T\d{9}T)[\-_\s]*([\dD ]+U\s*[\dD ]+)/){
		$self->_set_check_type('personal');	
		$self->{transit} = $1; $self->{transit}=~s/\s{2,}/ /g;
		$self->{on_us} = $2; $self->{on_us}=~s/\s{2,}/ /g;
		return 1;	
	}
	return 0;
}

# aka hacky match
sub _unknown_check_match {
	my $self = shift; 

	# what conditions does this run on
	# first off, there can not be a match type already
	if($self->get_check_type) { return; }

	# second, we must have already exhausted the clean runs we can make 
	# otherwise , it will attempt to match an unclean string before
	# the other match methods get a chance to succeed.
	# clean_runs can be less then max_clean_runs, but only if a check type 
	# match was already established, thus, we would not get here at all
	($self->clean_runs > $self->max_clean_runs) or return;

	# third, tolerant flag must be set to true
	# also, _unknown_check_match() is a last resource, so set giveup flag if not tolerant.
	unless ($self->tolerant){ $self->{_giveup} = 1; return; }


		
	# reset the string
	$self->{string} = $self->{original_string};
	

			
		my ($u,$t,$a,$d) = ($self->{on_us_symbol}, $self->{transit_symbol}, $self->{ammount_symbol}, $self->{dash_symbol});		
		if ($t ne 'T'){
				$self->{string}=~s/$t/T/g;
		}
		if ($u ne 'U'){
				$self->{string}=~s/$u/U/g;
		}
		if ($a ne 'X'){
				$self->{string}=~s/$a/X/g;
		}
		if ($d ne 'D'){
				$self->{string}=~s/$d/D/g;
		}			
	
	
	
	my $match=0;
	my $string = $self->{string}; # TODO: MAKE SURE - is this *really* a copy of what is in self??????
	# because we are hacking away at it here.. 

	if ($string=~s/(U[\dD]+U)//) { #aux on us
		$self->{auxiliary_on_us} = $1;
		$match++;
	}

	if ($string=~s/(T\d{9}T)//){
		$self->{transit}= $1;
		$match++;
	}

	if ($string=~/[^U](\d{5,18}U[\dD]*)/ ) { # how many digits can this be? can the account number have dashes?
		$self->{on_us} = $1;
		$match++;
	}

	
	# we want to assert that if we resorted to *this* method of matching fields, this is was a crappy string 
	# to begin with.

	if( $match ){
		$self->_set_check_type('unknown');
		return 1; # return $match;
	}
	
	# _unknown_check_match() is a last resource, so set giveup flag since there was 
	# no match by this point
	$self->{_giveup} = 1;	
	return 0;
}







# END MAIN MATCHERS
# -------------------------------------------







# summary MICR string info

sub micr {
	my $self = shift;
	#$self->valid or return;

#	my $micr = $self->{string};

#	$micr=~s/\s|\-|_//g;
	my $micr;

	if ($self->is_business_check){
		$micr .= $self->auxiliary_on_us . $self->transit . $self->on_us;	
	}
	
	elsif ($self->is_personal_check){
		$micr .= $self->transit . $self->on_us;		
	}

	elsif ($self->is_unknown_check){ # assume / guess that it's a business check
		$micr .= $self->auxiliary_on_us ? $self->auxiliary_on_us : 'UxxxxxxU';
		$micr .= $self->transit ? $self->transit : 'TxxxxxxT';
		$micr .= $self->on_us ? $self->on_us :  'xxxxxxU';	
	}
	else {
		return;
	}

	return $micr;	
}

sub micr_pretty {
	my $self = shift;
	my $micr = $self->micr or return;
	$micr=~s/ /_/g;
	for( $micr ) {
    s/([^[:^alpha:]xuUD])([\dxuDU]+\1)/_$1$2_/g;
    s/(?<=([^\dxuUD_]))?([\dxuDU]+)([^\dxuDU_])/
        $2 . $3 . ( $1 eq $3 ? '' : '_' )
    /ge;
    s/_(_|$)/$1/g;
	}
	
	$micr=~s/^_+|_{2,}|_+$//g;
	return $micr;
}


sub original_string {
	my $self-> shift;
	return $self->{orginal_string};
}

sub is_business_check {
	my $self = shift;
	$self->{is_business_check} ||=0;
	return $self->{is_business_check};
}
sub is_personal_check{
	my $self = shift;
	$self->{is_personal_check} ||=0;
	return $self->{is_personal_check};
}	

sub is_unknown_check {
	my $self = shift;
	$self->{is_unknown_check} ||=0;
	return $self->{is_unknown_check};
}

sub get_check_type {
	my $self = shift;	
	!$self->is_business_check or return 'b';	
	!$self->is_personal_check or return 'p';
	!$self->is_unknown_check or return 'u';
	return;
}

sub _set_check_type {
	my $self = shift;
	my $type = shift; $type or croak('missing arg to _set_check_type()');
	$type=~/^b|^p|^u/i or croak("type:[$type] unrecognized type, use (u)nknown, (b)usiness, or (p)ersonal"); 
	
	$self->{is_business_check} = ($type=~/^b/i or 0);
	$self->{is_personal_check} = ($type=~/^p/i or 0);
	$self->{is_unknown_check} = ($type=~/^u/i or 0);
	return 1;
}




# main MICR METHODS 
# the five major fields

sub auxiliary_on_us {
	my $self = shift;
	defined $self->{auxiliary_on_us} or return;
	return $self->{auxiliary_on_us};
}

sub on_us {
	my $self = shift;
	defined $self->{on_us} or return;
	return $self->{on_us};
}




# ----------------------------------
# transit and subfields

sub transit {
	my $self = shift;
	defined $self->{transit} or return;
	if (defined $self->{check_digit}){ return $self->{transit}; }	

	my $transit = $self->{transit};	
	#$transit=~s/T//g;	
	$transit=~/T(\d{1})(\d{4})(\d{4})T$/ or die("transit() returns messed up:[$transit], should begin with the transit symbol, have 9 digits, and end in the transit symbol.");
	
	$self->{check_digit} = $1;
	$self->{bank_number} = $2;
	$self->{routing_number} = $3;
		
	return $self->{transit};
}

sub check_digit {
	my $self = shift;	
	$self->transit or return;	
	return $self->{check_digit};		
}


sub bank_number {
	my $self = shift;
	$self->transit or return;
	return $self->{bank_number};
}

sub routing_number {
	my $self = shift;
	$self->transit or return;	
	return $self->{routing_number};	
}


# end transit and subfields



# TODO: this is not fully functional
sub epc {
	my $self = shift;
	defined $self->{epc} or return;
	return $self->{epc};
}

# TODO: this is not fully functional
sub ammount {
	my $self = shift;
	defined $self->{ammount} or return;
	return $self->{ammount};
}






sub account_number {
	my $self = shift;
	if (defined $self->{account_number}){ return $self->{account_number}; }

	$self->on_us or return; # if not defined, we cant extract bank number 
	
	if ( $self->on_us=~/([\dD ]{5,19})U/ ){
		$self->{account_number} = $1;
		return $self->{account_number};
	}	
	return;
}



sub check_number {
	my $self = shift;
	if( defined $self->{check_number}){ return $self->{check_number}; } 
	# a lot of this is sort of redundant, but i put it here for reasoning for a viewer
	
	# check number may be on the on us or in the aux on us
	
	if ($self->is_business_check){
			$self->{check_number} = $self->auxiliary_on_us;
			$self->{check_number}=~s/U//g;
			#$self->{check_number}=~s/^0+//;
			return $self->{check_number};
	}
	elsif ($self->is_personal_check){
			if ($self->on_us=~/U\s*(\d+)/ ){
				$self->{check_number} = $1;
				#$self->{check_number}=~s/^0+//;
				return $self->{check_number};
			}
			else {
				return; # personal check with no check number
			}	
	}

	
	if ($self->is_unknown_check){
	
		# at this point the string is not a valid() MICR check string .. the 
		# procedures are sameish.. but we made sure type is unknown
		if ($self->auxiliary_on_us){
				$self->{check_number} = $self->auxiliary_on_us;
				$self->{check_number}=~s/U//g;
				#$self->{check_number}=~s/^0+//;
				return $self->{check_number};	
		}

		elsif ($self->on_us){
			if ($self->on_us=~/U([\d]+)/ ){
				$self->{check_number} = $1;
				#$self->{check_number}=~s/^0+//;
				return $self->{check_number};
			}	
		}
	}	
	
	return;
}





sub valid {
	my $self = shift;
	if ($self->is_personal_check or $self->is_business_check){
		return 1;
	}
	return 0;
}


sub status {
	my $self = shift;
	no warnings;

	
	my $out = sprintf "original string [%s]\n",$self->{original_string};
	$out.= sprintf "runs: [%s]\n",			$self->clean_runs;	
	$out.= sprintf "string: [%s]\n",			$self->{string};	
	$out.= sprintf"giveup: [%s]\n",			$self->giveup;
	$out.= sprintf"transit: [%s]\n",		$self->transit;	
	$out.= sprintf"on_us: [%s]\n",			$self->on_us;
	$out.= sprintf"account #: [%s]\n",		$self->account_number ;
	$out.= sprintf"check #: [%s]\n",		$self->check_number;
	$out.= sprintf"is personal: [%s]\n",	$self->is_personal_check;
	$out.= sprintf"is business: [%s]\n",	$self->is_business_check;
	$out.= sprintf"bank_number: [%s]\n",	$self->bank_number;
	$out.= sprintf"routing number: [%s]\n",	$self->routing_number;
	$out.= sprintf"epc: [%s]\n",	$self->epc;
	$out.= sprintf"check_digit: [%s]\n",	$self->check_digit;
	$out.= sprintf"is valid: [%s]\n",	$self->valid;
	$out.= sprintf"check type: [%s]\n",	$self->get_check_type;
	$out.= sprintf"micr: [%s]\n",	$self->micr;
	$out.= sprintf"micr_pretty: [%s]\n",	$self->micr_pretty;
		
		
	return $out;
}




1;
__END__

=pod

=head1 NAME

Finance::MICR::LineParser - validate and parse a check MICR string

=head1 SYNOPSIS

	use Finance::MICR::LineParser;
	
	my $micr = Finance::MICR::LineParser->new({ string => $string });	

	print "Is this a MICR code? ". $micr->valid;

Imagine you scanned in a check using a standard scanner. And used some OCR sofware to try to
extract the text from it. It could have a miriad problems, garble, etc - but it's what we have
to work with. So.. let's create a small cli script that takes potentially garble and tells us
if a MICR code is there and something about it.

micrline.pl:

	#!/usr/bin/perl -w
	use strict;
	use Finance::MICR::LineParser;

	my $string = $ARGV[0];
	$string or die('missing arg'); 

	my $micr = new Finance::MICR::LineParser({ string => $string });

	if ($micr->valid){
		print "A valid MICR line is present: ".$micr->micr."\n";
		print "The type of check is: ".$micr->get_check_type."\n";
		print "The routing number is: ".$micr->routing_number."\n";
		print "The check number is: ".$micr->check_number."\n";
		print "Status: ".$micr->status;
		
	}

	elsif ($micr->is_unknown_check){
		print "I don't see a full valid MICR line here, but this is what I can match up "
		."if this is a business check: ". $micr->micr."\n";
		print "Status: ".$micr->status;		
	}

	else {
		print "This is garble to me.\n";
		print "Status: ".$micr->status;	
	}
	

Now in your terminal:

   # perl ./micrline.pl U2323424U_T234244T_2342424U
	

=head1 DESCRIPTION

Parse a MICR Line code into parts. Additionally tell us if a string garble contains a MICR code.
If you have a string and want to parse it as a check's MICR line, this is useful.

I am presently using this module to let the office scan in documents and using gocr, I get a string
out of the scanned check image. Then with this module I parse the MICR line- if one is there.
I name the documents for archiving after the MICR code.

Obviously with scanning, the MICR symbols don't have unicode equivalents- so various companies have
switched the symbols for alpha counterparts. This module accepts the symbols being more then one character.
This is beacuse gocr can't group something like '||"' into one character. You may have trained your ocr
software to replace those with something like Tt (transit, which looks like |:) 
and UUu (on us, which looks like ||"). This module can be told on instantiation, that the symbols are
something other then the defaults. 
For example, I trained my gocr to change ||" to CCc and |: to Aa - so I start an object instance like so:

	my $micr = new Finance::MICR::LineParser({ 
		string => $string_from_gocr,
		on_us_symbol => 'CCc',
		transit_symbol => 'Aa',
		dash_symbol => 'DDd',
		ammount_symbol => 'XxX',
	});

By default, these are changed to : 

=over 4

=item *

Transit Symbol: T

=item *

Ammount Symbol: X

=item *

On-Us Symbol: U

=item *

Dash Symbol: D

=back	

That is, when you query methods such as $micr->on_us, the return on_us value therein is U and not
CCc.

As of this time, if you want to change the symbols back to something else, it's up to you to handle
the output.

=head1 METHODS

=head2 new()

Argument is anon hash. croaks if no arg provided.
Right now takes a string and tries to find MICR parts..

	my $m = new Finance::MICR::LineParser ({ string => 'U2323424U_T234244T_2342424U' });

Constructor Arguments:

	string: the string you have that you think *is*, or may *contain* a micr string.
	
=head2 valid()

Ask if the MICR code is valid
Returns true or undef
Valid means the string argument was matched as a business check MICR or a personal
check MICR. That is, the fields are there and in the *right order*.
NOTE that if your code is deemed invalid, you *may* still get field values.
But your string as a whole should be considered invalid. 
You should always use valid() before taking the output as gospel.

=head2 status()

Returns a summary string including original string argument to constructor,
"clean_run" pass count for the string, string after those clean runs, if
the module gave up, etc. Useful for logging and find out if you have any 
problems. 

Typical usage:

	$micr->valid or print STDERR $micr->status;

=head2 is_business_check()

Returns true or false. Presently a business check has the fields;

	AUXILIARY_ON_US TRANSIT ON_US

In that order. Furthermore, the check number is extracted from AUXILIARY_ON_US

=head2 is_personal_check()

Returns true or false. Presently a business check has the fields;

	TRANSIT ON_US

In that order. Furthermore the check number is extracted from ON_US, digits after
the on us symbol.

=head2 is_unknown_check()

Means that we have matched one or more main fields (aux on us, on us, transit) but
some are missing or in unexpected order.
This should be taken *very* seriously. It means any strings that return
is_unknown_check() *must* be checked for correctness.

=head2 get_check_type()

Returns (u)nknown, (b)usiness, (p)ersonal, or undef.

=head2 clean_runs()

How many times the string has been been "cleaned". This does not tell you that the
string is a valid MICR code. Just how many times it was cleaned. The higher the 
number, the more you should inspect the output by a human being.

=head2 original_string() 

String passed to constructor.

=head2 micr()

MICR string without spaces of extraneous garble.
If you passed a MICR string *with* garble, this is different from the original_string()
Returns undef if the string is invalid. 
NOTE: a string which is not valid() will not return a micr() code.

=head2 micr_pretty()

Returns the micr() code somewhat formatted for human eyes. That is..
If your original string argument to the constructror is 

=over 4

3 12 U0000011135U T052000113T 984U0837166   _ 23 1

=back
	
Then this returns somethign like

=over 4

U0000011135U_T052000113T_984U0837166

=back

NOTE: a string which is not valid() will not return a micr_pretty() code.

=head2 giveup()

Returns true or false. Think of this also as 'gave up'.
NOTE: A string that ended up not valid() could still return 0 here. This
is because by default, Finance::MICR::LineParser attempts to match at least
one of the main MICR fields before giving up.


=head1 MICR SPECIFIC METHODS

There are five major fields on a MICR line.
Two of the five major fields (transit and "on us") are broken into multiple fields-
here called "sub fields".
First are the five major fields...

=head2 auxiliary_on_us()

contains check number if present; bracketed by 'on us' symbols
returns undef if not found.

=head2 epc()

one character located to the left of the transit field if present
returns undef if not found.
This needs work.

=head2 transit()

Always 9 digits including check digit. Opens and closes with a transit symbol.
(Some papers refer to this field as having 11 chars because they are counting
the open and close symbols as characters.)
returns undef if not found.

=head2 on_us()

variable length 19 digits max
between transit and amount fields (to the right of transit.)
returns undef if not found.

=head2 ammount()

10 digits zero filled; bracketed by two amount symbols
returns undef if not found.
This needs work.

=head1 TRANSIT SUB FIELD METHODS

Transit has 9 digits. It is croken into multiple fields:

=head2 routing_number()

return routing number. (digits 1-4)
returns undef if not found.

=head2 bank_number()

return bank number (digits 5-8)
returns undef if not found.

=head2 check_digit()

return check digit (one digit)
returns undef if not found

=head1 ON US SUB FIELD METHODS

=head2 check_number()

returns check number, Located in various places in the on us field.
returns undef if not found

=head2 tpc()

max 6 characters; Located to right of account number
returns undef if not found
TODO: This needs some thought, on a personal check this would be the check
number, what gives?

=head2 account_number()

Variable length; always followed by the On Us symbol
returns undef if not found

=cut



=head1 BUGS

Please report bugs to developer.

Notice: this module is under development. It is being used for production, but it *is* under development.

Please notify with hany questions or concerns. I've seen very little on MICR and open source out there. 
If you have any recommendations, please don't hessitate on letting me know how to make this module better.

This module helps me a lot, and I am hoping it may be of use to others and they may contribute criticism,
patches, suggestions, etc.

=head1 TODO

Not yet implemented:

If you want to get *your* symbols output back, here's an example:

	my $micr = new Finance::MICR::LineParser({ 
		string => $string_from_gocr,
		on_us_symbol => 'CCc',
		transit_symbol => 'Aa',
		dash_symbol => 'DDd',
		ammount_symbol => 'XxX',
		return_my_symbols=>1,
	});


=head1 BUGS

Address bug reports and comments to AUTHOR 

=cut

=head1 SEE ALSO

http://en.wikipedia.org/wiki/Magnetic_ink_character_recognition

=head1 AUTHOR

Leo Charre leocharre at cpan dot org

=head1 COPYRIGHT

Copyright (c) 2009 Leo Charre. All rights reserved.

=head1 LICENSE

This package is free software; you can redistribute it and/or modify it under the same terms as Perl itself, i.e., under the terms of the "Artistic License" or the "GNU General Public License".

=head1 DISCLAIMER

This package is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

See the "GNU General Public License" for more details.

=cut

