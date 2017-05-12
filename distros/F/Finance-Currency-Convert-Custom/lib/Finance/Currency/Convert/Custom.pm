package Finance::Currency::Convert::Custom;

use strict;

use base qw(Finance::Currency::Convert);
use LWP::UserAgent;
our $VERSION = '1.00';


sub updateRates() {
	my $self = shift;
	my $sub_ref = shift;
	
	my @CurrencyList = @_;
	
	unless(ref $sub_ref eq 'CODE'){
		#case of not defined own sub and sent countries list as params :)
		unless(ref $sub_ref){
			push @CurrencyList, $sub_ref;
		}
		$sub_ref = sub{my ($cur_from, $cur_to) = @_; return $self->currency_finyahoo($cur_from, $cur_to);}
	}
	
	
	foreach my $source (@CurrencyList) {
		foreach my $target (sort keys %{ $self->{CurrencyRates}}) {
			$self->setRate($source, $target, &{$sub_ref}($source, $target));
		}
	}
	foreach my $source (sort keys %{ $self->{CurrencyRates}}) {
		foreach my $target (@CurrencyList) {
			$self->setRate($source, $target, &{$sub_ref}($source, $target));
		}
	}
}

sub updateRate() {
	my $self = shift;
	my $sub_ref = shift;
	my $source = shift;
	my $target = shift;
	unless(ref $sub_ref eq 'CODE'){
			#case of not defined own sub and sent countries list as params :)
			unless(ref $sub_ref){
				$target = $source;
				$source = $sub_ref;
			}
			$sub_ref = sub{my ($cur_from, $cur_to) = @_; return $self->currency_finyahoo($cur_from, $cur_to);}
	}
	
	$self->setRate($source, $target, &{$sub_ref}($source, $target));
}







sub currency_finyahoo() {

	my $self = shift;
	#$self->{UserAgent}
	my ($cur_from, $cur_to) = @_;
	my $browser = LWP::UserAgent->new;
	my $response = $browser->get( "http://finance.yahoo.com/d/quotes.csv?e=.csv&f=sl1d1t1&s=".$cur_from.$cur_to."=X" );
	my $data = $response->content();
	my @arr = split /,/,$data; 
	return $arr[1];
}




1;

__END__


=head1 NAME

Finance::Currency::Convert::Custom - Update for C<Finance::Currency::Convert> with ability of own rates updating on the fly.

=head1 SYNOPSIS

  use Finance::Currency::Convert::Custom;
  use LWP::UserAgent;
  my @currencies = ('EUR','GBP','AUD','CAD','BRL','DKK','HKD','KRW','NOK','SEK','CHF','TWD');
  my $converter = new Finance::Currency::Convert::Custom;
  foreach my $currency (@currencies){	
  	#also, updateRates has same call, you should add ref to your sub as first param - others like in Finance::Currency::Convert
  	#also, if ref to sub is not defined then own internal example is used
	  $converter->updateRate(\&own_fetch_rate,$currency, "USD");
	  my $rate = $converter->convert(1, $currency, "USD"); 	  	  
  }
  
  sub own_fetch_rate{
  	my ($cur_from, $cur_to) = @_;
	my $browser = LWP::UserAgent->new;
	my $response = $browser->get( "http://finance.yahoo.com/d/quotes.csv?e=.csv&f=sl1d1t1&s=".$cur_from.$cur_to."=X" );
	my $data = $response->content();
	my @arr = split /,/,$data; 
	return $arr[1];
  }
  
  

=head1 DESCRIPTION

C<Finance::Currency::Convert::Custom> should be useful for people, who needs to have own rates or have own methods for fetching them, 
but who likes C<Finance::Currency::Convert>. Its needed because of Finance::Currency::Convert strong dependency of Finance::Quote. 
The last module fails a lot last time.


=head1 SEE ALSO

Finance::Currency::Convert::Custom

=head1 AUTHOR

Dmitry Nikolayev <dmitry@cpan.org>, http://makeperl.com

=head1 THANKS

Thanks to Freecause, http://freecause.com for giving opportunity to make same for company and community ;)


=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by Dmitry Nikolayev

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

