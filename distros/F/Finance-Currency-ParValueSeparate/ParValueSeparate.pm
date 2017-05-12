package Finance::Currency::ParValueSeparate;
use Carp;
use strict;
our $VERSION = sprintf "%d.%02d", q$Revision: 1.3 $ =~ /: (\d+)\.(\d+)/;
use Data::Dumper;

sub new {
	my $class = shift;
	my %opt = @_;
	my $concrete = $class;
	my $amount = [];

	# called base class
	if ( $class eq 'Finance::Currency::ParValueSeparate' ){
	
		# which subclass we wanner using?
		if ( defined $opt{'currency'} ){
			$concrete = "Finance::Currency::ParValueSeparate::".$opt{'currency'};
		}else{
			$concrete = "Finance::Currency::ParValueSeparate::" . shift @_;
			$amount = ( ref $_[0] eq 'ARRAY' ) ? $_[0] : [ @_ ];
		}
		
		# try to require the subclass
		eval "require $concrete;";
		die "subclass: $concrete could not required!" if $@;

	# called subclass
	}else{
		$amount = ( ref $_[0] eq 'ARRAY' ) ? $_[0] : [ @_ ];
	}
	
	my $self = bless {}, $concrete;
	$self->amount( $amount );
	$self->with_dollar( $self->dollar );
	$self->with_cent( $self->cent );

	return $self;
}

sub _amount_format {
	my $self = shift;
	my $amount = shift;
	return sprintf( '%.2f', $amount );
}

sub amount {
	my $self = shift;
	my $amount_ref = ( ref $_[0] eq 'ARRAY' ) ? $_[0] : [ @_ ];
	$self->{_AMOUNT} = [ map { $self->_amount_format( $_ ) } @$amount_ref ]
		if scalar @$amount_ref;
	return wantarray ? @{$self->{_AMOUNT}} : $self->{_AMOUNT};
}

sub with_dollar {
	my $self = shift;
	my $with_dollar = ( ref $_[0] eq 'ARRAY' ) ? $_[0] : [ @_ ];
	if ( @_ ){
		my $valid_dollar;
		map { $valid_dollar->{$_}++; } $self->dollar;
		$self->{_with_dollar} = [ grep { $valid_dollar->{$_} } @$with_dollar ];

		map { delete $valid_dollar->{$_} } @$with_dollar;
		$self->{_without_dollar} = [ keys %$valid_dollar ];
	}
	return wantarray ? @{$self->{_with_dollar}} : $self->{_with_dollar};
}
sub without_dollar {
	my $self = shift;
	my $without_dollar = ( ref $_[0] eq 'ARRAY' ) ? $_[0] : [ @_ ];
	if ( @_ ){
		my $valid_dollar;
		map { $valid_dollar->{$_}++; } $self->dollar;
		$self->{_without_dollar} = [ grep { $valid_dollar->{$_} } @$without_dollar ];

		map { delete $valid_dollar->{$_} } @$without_dollar;
		$self->{_with_dollar} = [ keys %$valid_dollar ];
	}
	return wantarray ? @{$self->{_without_dollar}} : $self->{_without_dollar};
}

sub with_cent {
	my $self = shift;
	my $with_cent = ( ref $_[0] eq 'ARRAY' ) ? $_[0] : [ @_ ];
	if ( @_ ){
		my $valid_cent;
		map { $valid_cent->{$_}++; } $self->cent;
		$self->{_with_cent} = [ grep { $valid_cent->{$_} } @$with_cent ];

		map { delete $valid_cent->{$_} } @$with_cent;
		$self->{_without_cent} = [ keys %$valid_cent ];
	}
	return wantarray ? @{$self->{_with_cent}} : $self->{_with_cent};
}
sub without_cent {
	my $self = shift;
	my $without_cent = ( ref $_[0] eq 'ARRAY' ) ? $_[0] : [ @_ ];
	if ( @_ ){
		my $valid_cent;
		map { $valid_cent->{$_}++; } $self->cent;
		$self->{_without_cent} = [ grep { $valid_cent->{$_} } @$without_cent ];

		map { delete $valid_cent->{$_} } @$without_cent;
		$self->{_with_cent} = [ keys %$valid_cent ];
	}
	return wantarray ? @{$self->{_without_cent}} : $self->{_without_cent};
}

sub only_dollar {
	my $self = shift;
	my $flag = shift;
	if ( defined $flag ){
		$self->{_only_dollar} = ( $flag ) ? 1 : 0;
	}
	return $self->{_only_dollar};
}

sub parse {
	my $self = shift;
	$self->amount(@_);
	delete $self->{_DOLLAR};
	delete $self->{_CENT};

	map {
		my $dollar = int $_;
		my ( $cent ) = ( $_ =~ /\.(.*)$/ );

		foreach my $parvalue ( sort { $b<=>$a } $self->with_dollar ){
			my $number = ( $dollar - $dollar % $parvalue ) / $parvalue;
			$dollar -= $number * $parvalue;
			$self->{_DOLLAR}{$parvalue} += $number;
		} 
		
		next if $self->only_dollar;
		
		foreach my $parvalue ( sort { $b<=>$a } $self->with_cent ){
			my $number = ( $cent - $cent % $parvalue ) / $parvalue;
			$cent -= $number * $parvalue;
			$self->{_CENT}{$parvalue} += $number;
		}
		
	} $self->amount;
}

sub dollar_parvalues {
	my $self = shift;
	return sort { $b <=> $a } keys %{$self->{_DOLLAR}};
}
sub number_of_dollar {
	my $self = shift;
	my $parvalue = shift;
	return $self->{_DOLLAR}{$parvalue};
}

sub cent_parvalues {
	my $self = shift;
	return sort { $b <=> $a } keys %{$self->{_CENT}};
}
sub number_of_cent {
	my $self = shift;
	my $parvalue = shift;
	return $self->{_CENT}{$parvalue};
}


# subclass override them
sub currency_name {
	croak 'base class has no currency_name, use subclass';	
}
sub dollar {
	croak 'base class has no dollar denomination informations, use subclass';	
}
sub cent {
	croak 'base class has no cent denomination informations, use subclass';	
}

1;
__END__

=head1 NAME

Finance::Currency::ParValueSeparate - give least number of every parvalue within a certain amount

=head1 SYNOPSIS

 # create new object to resolve RMB 317 needs which least number of parvalue
 use Finance::Currency::ParValueSeparate;
 my $pvs = new Finance::Currency::ParValueSeparate( RMB => 317 );
 $pvs->parse;

 # list all parvalue which we need and how many we need
 map { print "parvalue \$$_: ", $pvs->number_of_dollar($_), "\n" } $pvs->dollar_parvalues;

more flexible usage see the method part below.

=head1 DESCRIPTION

When we offer salaies to employees with cash, we should prepare some different parvalue of money. For example, we pay $327 to a guy, we should prepare three $100 parvalue and one $20 parvalue and one $5 parvalue and two $2 parvalue. Of course it's easy for a man to decide how many and which parvalue we need to pay, and in my later project, the customer often parepare salaies for a group of employees, so many person's salaies we should compute then let perl take it over, and further more, the customer only want know totally how many every parvalue he should prepare to pay the group. Here this module comes.

=head1 METHODS

=item new() 

 my $pvs = new Finance::Currency::ParValueSeparate( currency => 'RMB' );

only giving the currency type, here is RMB, so inside the module, it will return a Finance::Currency::ParValueSeparate::RMB object. here no amount given, so the amount is 0.

 my $pvs = new Finance::Currency::ParValueSeparate( RMB => 317.34 );

here we also giving the currency type and the amount to be parse.

 my $pvs = new Finance::Currency::ParValueSeparate( RMB => ['317.34','512.14'] );

the amount could be an array, so later we can know the totally how many different parvalue we need for all items in the amount array after parsed.

 use Finance::Currency::ParValueSeparate::RMB;
 my $pvs = new Finance::Currency::ParValueSeparate::RMB(); # amount is 0
 my $pvs = new Finance::Currency::ParValueSeparate::RMB( 317.34 );
 my $pvs = new Finance::Currency::ParValueSeparate::RMB( 317.34, 512.14 );
 my $pvs = new Finance::Currency::ParValueSeparate::RMB( ['317.34','512.14'] );

of course, we can directly use the subclass. here we already know which currency we use, so just tell it the amount we need to parse.

=item amount()

 # set the amount
 $pvs->amount( 852.50 );
 $pvs->amount( 852.50, 512.14 );

 # get the amount
 my $amount = $pvs->amount; # return array ref for amount list
 my @amount = $pvs->amount; # return array for amount list

the amount value will format as %.2f.

=item with_dollar(), without_dollar()

may be we has no $20 and $5 to prepare, so we should figure that, let parser skip that parvalues. so you can using:

 $pvs->without_dollar(qw(20 5));
 $pvs->without_dollar([20, 5]);

vice verser, if we only have $20 and $10 parvalue, we shoulg using:

 $pvs->with_dollar(qw( 20 10 ));
 $pvs->with_dollar([20, 10]);

if no array passed, just return present value. when set with_dollar([...]) you can call without_dollar() for return the skipped parvalues, and vice verser.

you should either use with_dollar(...) or without_dollar(...), if you invoke them multi-times, only the last setting call takes the final effect, all before setting will seems nothing.

=item with_cent(), without_cent()

same as above, but here we specified the cent(or penny, anyway, the float part of an amount) parvalue to with or without.

 $pvs->with_cent(qw( 45 25 ));
 $pvs->without_cent(qw( 5 1 ));

=item only_dollar()

sometimes we only need parse the dollar part, and ignore the float part.

 $pvs->only_dollar(1); # ignore cent part to parse
 $pvs->only_dollar(0); # within cent part to parse
 $pvs->only_dollar(); # return boolen

=item parse()

 $pvs->parse(); # using $pvs->amount to parse
 $pvs->parse( 314.34 ); # just parse this amount
 $pvs->parse( @amount_list );

=item dollar_parvalues(), cent_parvalues()

 my @parvalues = $pvs->dollar_parvalues();
 my @parvalues = $pvs->cent_parvalues();

return a list for which parvalue we need prepare

=item number_of_dollar(), number_of_cent()

 my $number = $pvs->number_of_dollar(50);
 my $number = $pvs->number_of_cent(25);

return how many the certain parvalue we need prepare

=head1 AUTHOR

Chun Sheng <me@chunzi.org>

=head1 COPYRIGHT

Copyright (c) 2000-2002 Matthew P. Sisk. All rights reserved. All wrongs revenged. This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
