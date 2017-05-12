package Math::Financial;

# Copyright 1999 Eric Fixler <fix@fixler.com>
# All rights reserved. This program is free software; 
# you can redistribute it and/or modify it under the same terms as Perl itself. 

# $Id: Financial.pm,v 1.5 1999/09/15 19:08:41 fix Exp $
# $Source: /www/cgi/lib/Math/RCS/Financial.pm,v $

=pod 

=head1 NAME

Math::Financial - Calculates figures relating to loans and annuities.

=head1 SYNOPSIS

$calc = new Math::Financial(fv =E<gt> 100000, pv =E<gt> 1000);
$calc-E<gt>set->(pmt => 500, ir => 8);

$calc->compound_interest(find =E<gt> 'fv');

=head1 DESCRIPTION

This package contains solves mathematical problems relating to loans and annuities.

The attributes that are used in the equations may be set on a per-object basis, allowing
you to run a set of different calculations using the same numbers, or they may be fed
directly to the methods.

The attribute types, accessed through the C<get> and C<set> methods are

=over4

=item pv	=E<gt> 	Present Value

=item fv	=E<gt> 	Future Value

=item ir	=E<gt>  Yearly Interest Rate (in percent)

=item pmt	=E<gt>	Payment Amount

=item np	=E<gt>	Number of Payments/Loan Term

=item tpy	=E<gt>	Terms Per Year (defaults to 12)

=item pd	=E<gt>	Payments made so far (used only for loan/annuity balances)

=back

Attributes are case-insensitive.  The documentation for the individual methods
indicates which attributes must be set for those methods.

Calculations are based B<either> on the attributes set with the C<new> or C<set>
methods, B<or> with arguments fed directly to the methods.  This seemed like the
least confusing way to make the interface flexible for people who are using the
module in different ways. 

Also, performing a calculation
does B<not> update the attribute of the solution.  In other words, if 
you solve an equation that returns fv, the solution is returned but the 
internal fv field is unaffected. 

Any attempted calculation which cannot be completed -- due to either missing or
invalid attributes -- will return C<undef>. 

I am interested to hear from people using this module -- let me know what
you think about the interface and how it can be improved. 

=head1 METHODS

=cut

sub BEGIN {
		*{__PACKAGE__.'::loan_payment'} = \&monthly_payment;
		use strict;
		use POSIX qw(:ctype_h);
		use vars qw(@ISA $VERSION @EXPORT @EXPORT_OK %EXPORT_TAGS 
					@ATTRIBUTES $DEFAULT_OBJECT $re_object);
		$VERSION = 0.76;
		use constant	PV	=>	0;
		use constant	FV	=> 	1;
		use constant	NP	=>	2;
		use constant	PMT	=>	3;
		use constant	IR	=> 	4;
		use constant	TPY	=> 	5; # TERMS PER YEAR
		use constant	PD	=> 	6;
		@ATTRIBUTES	= qw(PV FV NP PMT IR TPY PD);
		$re_object = '(?i)[a-z][\w]*?::[\w]';
		@ISA = qw(Exporter);
		@EXPORT= ();
		@EXPORT_OK = qw(loan_term loan_payment compound_interest funding_annuity
						loan_balance loan_size simple_interest);
		%EXPORT_TAGS = ( procedural => \@EXPORT_OK,
						 standard	=> \@EXPORT_OK);
}


sub new {
=pod

=head2 new

C<$calc = new Math::Financial();

C<$calc = new Math::Financial(pv =E<gt> 10000, ir =E<gt> 5, np => 12)>

Object constructor.  See above for a description of the available attributes.
You do not I<have> to set attributes here, you can also do so using C<set>,
or feed attributes directly to the methods.  

There are no default values for any of the attributes except C<TPY> (Terms Per Year),
which is 12 by default, and C<PD> which defaults to zero.

If you don't want to use the object-oriented interface, see the L<EXPORTS> section
below.

=cut
	my $class = ref($_[0]) || ($_[0] =~ /(.*?::.*)/)[0];
	my $parent = ref($class) ? $_[0] : [undef,undef,undef,undef,undef,12,0] ;
	if ($class) { shift(@_); } else { $class = __PACKAGE__ ; };
	my $params = { 	pv	=>	$parent->[PV],
					fv	=>	$parent->[FV],
					ir	=>	$parent->[IR],
					np	=>	$parent->[NP],
					pmt	=>	$parent->[PMT],
					tpy	=> 	$parent->[TPY],
					pd	=>  $parent->[PD],
					@_ };
	my $self = [];
	bless($self,$class);
	$self->set(%$params);
	return $self;			
}


sub _get_attribute_key {
	 # if fed a list, will return a list
	 my ($self,@args) = _get_self(@_);
	 return undef unless scalar(@args);
	 my @keys = ();
	 foreach (@args) {
	 	if (isdigit($_)) { push(@keys,$_); next; };
	 	my $attrib = quotemeta($_);
	 	for (my $j = 0; $j <= $#ATTRIBUTES; $j++) {
	 	 	if ($ATTRIBUTES[$j] =~ /$attrib/i) { push(@keys,$j); next; };
	 	};
	 	push(@keys,undef); #unfound key
	 }
	 if (not($#args)) {
	 	return $keys[0];
	 } else {
	 	return wantarray ? @keys : \@keys;
	 };
};

sub set {
=pod

=head2 set

C<$calc-E<gt>set(fv =E<gt> 100000, pmt =E<gt> 500)>

You can set any of the stored attributes using this method, which is is also
called by <new>.  Returns the number of attributes set.

=cut
	 my ($self,@args) = _get_self(@_);
	 my $params = { @args };
	 my ($field,$val,$key); my $count = 0;
	 while (($field, $val) = each(%$params)) {
	 	$key = $self->_get_attribute_key($field);
	 	if (defined($key)) { $self->[$key] = $val; $count++; }
	 }
	 return $count;
}

sub get {
=pod

=head2 get

C<$calc-E<gt>get(field => 'ir')>

C<$calc-E<gt>get('ir','pmt','pv')>

C<$calc-E<gt>get([qw(ir pmt pv)])>

You can get one or several attributes using this method.  In the multiple
attribute formats, it accepts either a list or a list reference as input.

In single attribute context, returns a scalar.  In multiple attribute context,
it returns a list or a reference to a list, depending on the calling context.

=cut
	 my ($self,@args) = _get_self(@_);
	 ($args[0] =~ /field/io) and shift(@args);
	 my @gets = ();
	 foreach my $field (@args) {
	 	if 		(ref($field) eq 'ARRAY') { push(@gets,map({ $self->get($_) } @$field)) ; next; } 
	 	else	{ 	my $key = $self->_get_attribute_key($field);
	 			 	push(@gets, defined($key) ? $self->[$key] : $key); next; }
	 }
	 if ($#gets) {
	 	return wantarray ? @gets : \@gets;
	 } else { return $gets[0]; };
}


sub compound_interest {
=pod

=head2 compound_interest

C<$calc-E<gt>compound_interest>

C<$calc-E<gt>compound_interest-E<gt>('fv')>

C<$calc-E<gt>compound_interest-E<gt>(find =E<gt> 'fv')>

Calculates compund interest for an annuity.  With any 3 of pv, fv, np, and ir,
you can always solve the fourth. 

Without arguments, the method will attempt to figure out what you'd like to solve
based on what attributes of the object are defined.  Usually, you'll probably want to 
explicitly request what attribute you'd like returned, which you can do using
the second or third method. 

=cut
	my ($self,@args) = _get_self(@_);
	(scalar(@args) == 1) and unshift(@args,'find');
	if (scalar(@args) > 2) { 
		my $temp = __PACKAGE__->new(@args[2..$#args]);
		return $temp->compound_interest(@args[0..1]);
	}; 
	my $solve_for = $self->_get_attribute_key($args[1]); 
	my (@numbers,$result);
	if (not(defined($solve_for))) {
		if 		(@numbers = $self->_verify_fields(IR,PV,NP)) {  $solve_for = FV; }
		elsif	(@numbers = $self->_verify_fields(IR,FV,NP)) {  $solve_for = PV; }
		elsif	(@numbers = $self->_verify_fields(IR,PV,FV)) {  $solve_for = NP; }
		elsif	(@numbers = $self->_verify_fields(PV,FV,NP)) {  $solve_for = IR; }
		else { return undef; };
	} else { 
		my @combos = ();
		$combos[FV] = [IR,PV,NP]; $combos[PV] = [IR,FV,NP]; $combos[NP] = [IR,PV,FV];
		$combos[IR] = [PV,FV,NP];
		$set = $combos[$solve_for];
		@numbers = $self->_verify_fields(@$set) or return undef;
	}
	eval {if ($solve_for == FV) {
		$ir = ($numbers[0]/100) / $self->[TPY];
		($pv,$np) = @numbers[1,2];
		$result = abs($pv) * ( ($ir + 1) ** $np);
	} elsif ($solve_for == PV) {
		 $ir = ($numbers[0]/100) / $self->[TPY];
		 ($fv,$np) = @numbers[1,2];
		 $result = abs($fv) * ( ($ir + 1) ** (0 - $np) );
	} elsif ($solve_for == NP) {
		$ir = $numbers[0]/100/$self->[TPY];
		($pv,$fv) = @numbers[1,2];
		my $num = log(abs($fv)/$pv);
		my $den = log( 1 + $ir); 
		$result = $num / $den;
	} elsif ($solve_for == IR) {
		($pv,$fv,$np) = @numbers;
		$ir = (( abs($fv)/abs($pv) ) ** (1 / $np) ) - 1;
		$result = $ir * 100 * $self->[TPY];
	};};
	
	return ($@) ? undef : $result;
}

sub funding_annuity {
=pod 

=head2 funding_annuity

C<$calc-E<gt>funding_annuity>

C<$calc-E<gt>funding_annuity-E<gt>(pmt =E<gt> 2000, ir =E<gt> 6.50, np =E<gt> 40, tpy => 4)>

C<funding_annuity> calculates how much money ( C<fv> ) you will have at the end of C<np> periods
if you deposit C<pmt> into the account each period and the account earns C<ir> interest per year.

You may want to set the C<tpy> attribute here to something other than 12, since, while loans
usually compound monthly, annuities rarely do.

=cut

my ($self,@args) = _get_self(@_);
	if (scalar(@args)) { 
		my $temp = __PACKAGE__->new(@args);
		return $temp->funding_annuity();
	}; 
	my @numbers = $self->_verify_fields(IR,PMT,NP);
	return undef unless scalar(@numbers);
	my ($result); #solving for fv here
	my ($pmt,$np) = @numbers[1,2];
	my $ir = $numbers[0]/100/$self->[TPY];
	eval { $result = ($pmt * ( ((1 + $ir) ** $np) - 1))/$ir; };
	return $@ ? undef : $result;
 }


sub loan_balance {
=pod 

=head2 loan_balance

C<$calc-E<gt>loan_balance>

C<$calc-E<gt>loan_balance-E<gt>(pmt =E<gt> 2000, ir =E<gt> 6.50, np =E<gt> 360, pd =E<gt> 12)>

C<loan_balance> calculates the balance on a loan that is being made in C<np> equal payments,
given that C<pd> payments have already been made. You can also use this method to determine
the amount of money left in an annuity that you are drawing down.

=cut
my ($self,@args) = _get_self(@_);
if (scalar(@args)) { 
		my $temp = __PACKAGE__->new(@args);
		return $temp->loan_balance();
	}; 
	my @numbers = $self->_verify_fields(IR,PMT,NP);
	return undef unless scalar(@numbers);
	my ($pmt,$np) = @numbers[1,2];
	my $ir = $numbers[0]/100/$self->[TPY]; my ($result);
	eval { 	my $a = (1 + $ir) ** ($self->[PD] - $np);
			$result = $pmt/$ir * (1 - $a)  ; };
	return $@ ? undef : $result;
}

sub monthly_payment {
=pod

=head2 loan_payment

C<$calc-E<gt>loan_payment>

Return the payment amount, per period, of a loan.  This is also known as amortizing.  
The ir, np, and pv fields must be set.

=cut
	my ($self,@args) = _get_self(@_);
	if (scalar(@args)) { 
		my $temp = __PACKAGE__->new(@args);
		return $temp->monthly_payment();
	}; 
	my @numbers = $self->_verify_fields(IR,PV,NP);
	return undef unless scalar(@numbers);
	my ($result,$ir);
	my ($pv,$np) =  @numbers[1,2];
	$ir = ($numbers[0]/100) / $self->[TPY];
	my $a = (1 + $ir) ** (0 - $np);
	my $denominator = 1 - $a;
	my $numerator 	= $pv * $ir;
	$result = eval { $numerator / $denominator };
	return $@ ? undef : $result;
}


sub loan_size {
=pod 

=head2 loan_size

C<$calc-E<gt>loan_term>

C<$calc-E<gt>loan_size-E<gt>(pmt =E<gt> 2000, ir =E<gt> 6.50, np =E<gt> 360)>

C<loan_size> calculates the size of loan you can get based on the monthly payment
you can afford.

=cut

my ($self,@args) = _get_self(@_);
	if (scalar(@args)) { 
		my $temp = __PACKAGE__->new(@args);
		return $temp->loan_size();
	}; 
	my @numbers = $self->_verify_fields(IR,PMT,NP);
	return undef unless scalar(@numbers);
	my ($result);
	my ($pmt,$np) = @numbers[1,2];
	my $ir = $numbers[0]/100/$self->[TPY];
	eval { $result = ($pmt * (1 - ((1 + $ir) ** (0 - $np))))/$ir; };
	return $@ ? undef : $result;
};

sub loan_term { 
=pod

=head2 loan_term

C<$calc-E<gt>loan_term>

Return the number of payments (term) of a loan given the interest rate
C<ir>, payment amount C<pmt> and loan amount C<pv>.   The ir, pmt, and pv fields must be set.

=cut
	my ($self,@args) = _get_self(@_);
	if (scalar(@args)) { 
		my $temp = __PACKAGE__->new(@args);
		return $temp->loan_term();
	}; 
	my @numbers = $self->_verify_fields(IR,PMT,PV);
	return undef unless scalar(@numbers);
	my ($pmt, $pv) =  @numbers[1,2];
	$pv = abs($pv);
	my $ir = $numbers[0]/100/$self->[TPY];
	my ($result);
	$result = eval {
		my $numerator = log($pmt/($pmt - ($ir * $pv)));
		my $denominator = log(1 + $ir);
		return $numerator / $denominator;
		};
	return $@ ? undef : $result;
}


sub simple_interest {
=pod

=head2 simple_interest

C<$calc-E<gt>simple_interest>

C<$calc-E<gt>simple_interest-E<gt>('ir')>

C<$calc-E<gt>simple_interest-E<gt>(find =E<gt> 'ir')>

This works just like compound interest, but there is no consideration of C<np>.  
With any 2 of pv, fv, and ir, you can always solve for the third. 

Without arguments, the method will attempt to figure out what you'd like to solve
based on what attributes of the object have been defined.  Usually, you'll probably want to 
explicitly request what attribute you'd like returned, which you can do using
the second or third method. 

=cut
	my ($self,@args) = _get_self(@_);
	(scalar(@args) == 1) and unshift(@args,'find');
	if (scalar(@args) > 2) { 
		my $temp = __PACKAGE__->new(@args[2..$#args]);
		return $temp->simple_interest(@args[0..1]);
	}; 
	my $solve_for = $self->_get_attribute_key($args[1]); 
	my (@numbers,$ir,$pv,$pmt,$result);
	if (not(defined($solve_for))) {
		if 		(@numbers = $self->_verify_fields(IR,PV)) 		{  $solve_for = PMT; }
		elsif	(@numbers = $self->_verify_fields(IR,PMT)) 		{  $solve_for = PV; }
		elsif	(@numbers = $self->_verify_fields(PMT,PV)) 		{  $solve_for = IR; }
		else { return undef; };
	} else { 
		my @combos = ();
		$combos[PV] = [IR,PMT]; $combos[IR] = [PMT,PV]; $combos[PMT] = [IR,PV];
		$set = $combos[$solve_for];
		@numbers = $self->_verify_fields(@$set) or return undef;
	}
	# equations go here
	if ($solve_for == PMT) {
		$result =  $numbers[1] * ($numbers[0]/100); 
	} elsif  ($solve_for == PV) { 
		eval { $result =  $numbers[1]/($numbers[0]/100); }; 
	} elsif ($solve_for == IR) { 
		eval { $result = ($numbers[0]/$numbers[1]) * 100; };
	}
	return ($@) ? undef : $result;
}

sub _get_self { 
	my $self = (ref($_[0]) !~ /$re_object/o) ?  $DEFAULT_OBJECT ||= new __PACKAGE__ : shift(@_) ;
	return($self,@_);
}

sub _verify_fields {
	my ($self,@args) = _get_self(@_);
	my @defined = grep(/[0-9]/, @$self[@args]);
	return (scalar(@defined) == scalar(@args)) ? @defined : ();
}


1;

__END__

=pod

=head1 REQUIRES

POSIX -- c_type functions

(c_types might work under Windows.  I really don't know.  I'd appreciate it if someome
would let me know.  If they don't, in a future release, 
I'll provide a runtime replacement for the POSIX functions so it'll work on Win releases.  )

=head1 EXPORTS

By default, nothing.

If you'd like to use a procedural interface, you can C<use Math::Financial qw(:standard)>.

Then you can call the methods as function, without an object reference, like

C<$term = loan_term(ir =E<gt> 6.5, pmt =E<gt> 1000, pv =E<gt> 200000);>

All of the methods are exported in this fashion, except for C<set> and C<get>; this
just seemed too confusing.

You can still use the facility of C<set> and C<get> with the procedural interface (i.e., you
can set the attributes and them use them for many different calculations), but you
must call them as C<Math::Financial::set> and C<Math::Financial::get>.

=head1	AUTHOR

Eric Fixler <fix@fixler.com>, 1999

=head1 TODO

Add more equations!  Send me equations and I'll put them in.


=head1 ACKNOWLEDGEMENTS

Larry Freeman, whose Financial Formulas Page 
C<http://ourworld.compuserve.com/homepages/Larry_Freeman/finance.htm> 
was essential for this project.

=cut

#$Log: Financial.pm,v $
#Revision 1.5  1999/09/15 19:08:41  fix
#Added :standard EXPORT group.  Added a few lines of documentation.
#
#Revision 1.4  1999/09/15 18:49:01  fix
#Changed some syntax so it'll work with perl 5.004.
#Fixed an error in the loan_term method
#
