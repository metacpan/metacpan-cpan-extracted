package Finance::YahooJPN::QuoteDetail;

use 5.008003;
use strict;
use warnings;
use Carp;
use HTML::TableExtract;
use LWP::UserAgent;
require Exporter;

our $VERSION = '0.01'; # 2004-04-12 

sub new(){
	my ($class,$option) = @_;
	my $self = {};
	bless $self,$class;

        foreach my $key (keys %{$option}) {
		my $lowercase = $key;
		$lowercase =~ tr/A-Z/a-z/;
		unless ($lowercase eq 'symbol' or $lowercase eq 'proxy' or $lowercase eq 'market') {
			croak "Invalid attribute name: $key";
		}
		$$self{$lowercase} = $$option{$key};
	}

	unless ($$self{'symbol'} =~ /^\d{4}$/ || $$self{'symbol'} =~ /^\d{4}\.[a-zA-Z]$/) {
		croak "The 'symbol' attribute must not be omitted .A stock symbol should be given with four numbers. (ex. `6758' or '6758.t' )";
	}

	if($$self{symbol} =~ /^(\d{4})\.([a-zA-Z])$/) {
		$$self{'symbol'} = $1;
		$$self{'market'} = $2;
	}elsif($$self{symbol} =~ /^(\d{4})$/){
	        unless($$self{'market'} && $$self{'market'} =~ /^[a-zA-Z]$/){
			croak "The 'market' attribute must not be omitted ";
		}
	}

	$$self{'url'}    = 'http://quote.yahoo.co.jp/q?s='.$$self{'symbol'}.'&d='.$$self{'market'};

	return $self;
}

sub check(){
	my $self = shift;

	print "proxy is ";
	print $$self{'proxy'};
	print "\n";

	print "symbol is ";
	print $$self{'symbol'};
	print "\n";

	print "url is ";
	print $$self{'url'};
	print "\n";

}

sub quote(){
	my $self = shift;
	my $html_string = $self->_access_to_yahoo;
        $$self{'string_ref'} = $self->_extract_data_from_table();

	$self->_set_last_trade();
	$self->_set_high_price();
	$self->_set_low_price();
	$self->_set_prev_close();
	$self->_set_volume();
	$self->_set_change();

}

sub quick_quote(){
	my $self = shift;
	my $html_string = $self->_access_to_yahoo;
        $$self{'string_ref'} = $self->_extract_data_from_table();
}

sub _access_to_yahoo(){
	my $self = shift;

	#Create a user agent object
	my $ua = LWP::UserAgent->new(env_proxy => 1,
					keep_alive => 1,
					timeout => 30,
			                    );
	$ua->proxy(['http'], $$self{'proxy'}) if $$self{'proxy'};

	$ua->agent("MyApp/0.1");

	my $req = HTTP::Request->new(GET=>$$self{'url'});
	
	$req->content_type('application/x-www-form-urlencoded');
	$req->content('');
	
	# Pass request to the user agent and get a response back
	my $res = $ua->request($req);
	
	if ($res->is_success) {
		$$self{'_html_string'} = $res->content;
		return 1;
	} else {
		$$self{'error_msg'} = "Cannot access to Yahoo!";
		return 0;
	}
}

sub _extract_data_from_table(){
	my $self = shift;

	my $te     = new HTML::TableExtract;
	my $string = "";
	my $ts     = "";
	my $line = "";

	$te->parse($$self{'_html_string'});
	
	# Examine all matching tables
	foreach $ts ($te->table_states) {
	
		if( $ts->depth eq "1" && $ts->count eq "3"  ||
		    $ts->depth eq "0" && $ts->count eq "5" ){

			foreach my $row ($ts->rows) {
				$string = join(' ', @$row);
				$string =~ s/\n//g;
				$string =~ s/\r//g;
				$line .= $string;
			}
		}
	}
	$$self{'_string'} = $line;
	return \$line;
}

sub get_symbol_name(){
	my ($self) = @_;
	return $$self{'symbol_name'} if $$self{'symbol_name'};
	$self->_set_symbol_name();
	return $$self{'symbol_name'};
}

sub _set_symbol_name(){
	my ($self) = @_;
	$$self{'_string'} =~ m/^.([^\x20]+)/o;
	my $name = $1;
	$name =~ s/\(/ \(/;
	$name =~ s/\)/\) /;
	$$self{'symbol_name'} = $name;
}

sub get_last_trade_price(){
	my ($self) = @_;
	return $$self{'last_trade_price'} if $$self{'last_trade_price'};
	$$self{'_string'} =~ m/(\xbc\xe8\xb0\xfa\xc3\xcd)(\d+:\d+) ([\d\,]+)/o; 
	$self->_set_last_trade();
	return $3;
}

sub get_last_trade_time(){
	my ($self) = @_;
	return $$self{'last_trade_time'} if $$self{'last_trade_time'};
	$$self{'_string'} =~ m/(\xbc\xe8\xb0\xfa\xc3\xcd)(\d+:\d+) ([\d\,]+)/o; 
	$self->_set_last_trade();
	return $2;
}

sub _set_last_trade(){
	my ($self) = @_;
	$$self{'_string'} =~ m/(\xbc\xe8\xb0\xfa\xc3\xcd)(\d+:\d+) ([\d\,]+)/o; 
	$$self{'last_trade_time'} = $2;
	$$self{'last_trade_price'} = $3;
}

sub get_high_price(){
	my ($self) = @_;
	return $$self{'high_price'} if $$self{'high_price'};
	$self->_set_high_price();
	return $2;
}

sub _set_high_price(){
	my ($self) = @_;
	$$self{'_string'} =~ m/(\xb9\xe2\xc3\xcd)([\s\d\,]+)/o; 
	$$self{'high_price'} = $2;
}

sub get_low_price(){
	my ($self) = @_;
	return $$self{'low_price'} if $$self{'low_price'};
	$self->_set_low_price();
	return $2;
}

sub _set_low_price(){
	my ($self) = @_;
	$$self{'_string'} =~ m/(\xb0\xc2\xc3\xcd)([\d\,]+)/o; 
	$$self{'low_price'} = $2;
}

sub get_prev_close(){
	my ($self) = @_;
	return $$self{'prev_close'} if $$self{'prev_close'};
	$self->_set_prev_close();
	return $2;
}

sub _set_prev_close(){
	my ($self) = @_;
	$$self{'_string'} =~ m/(\xbd\xaa\xc3\xcd)([\d\,]+)/o; 
	$$self{'prev_close'} = $2;
}

sub get_volume(){
	my ($self) = @_;
	return $$self{'volume'} if scalar($$self{'volume'}) || scalar($$self{'volume'}) eq "0";
	$self->_set_volume();
	return $2;
}

sub _set_volume(){
	my ($self) = @_;
	$$self{'_string'} =~ m/(\xbd\xd0\xcd\xe8\xb9\xe2)([\d\,]+)/o; 
	unless($2){
		$$self{'volume'} = "0";
	}else{
		$$self{'volume'} = $2;
	}
}

sub get_change(){
	my ($self) = @_;
	return $$self{'change'} if scalar($$self{'change'}) || scalar($$self{'change'}) eq "0";
	$self->_set_change();
	return $2;
}

sub _set_change(){
	my ($self) = @_;
	$$self{'_string'} =~ m/(\xc1\xb0\xc6\xfc\xc8\xe6)([\+\-][\d\,]+)/o; 
	unless($2){
		$$self{'change'} = "0";
	}else{
		$$self{'change'} = $2;
	}
}

1;

__END__

=head1 NAME

Finance::YahooJPN::QuoteDetail - fetch detail quotes of Japanese stock markets.

=head1 SYNOPSIS

use Finance::YahooJPN::QuoteDetail;

$qd = Finance::YahooJPN::QuoteDetail->new({'symbol'=>$symbol.$market});

$qd = Finance::YahooJPN::QuoteDetail->new({'symbol'=>$symbol,market=>$market});

$qd = Finance::YahooJPN::QuoteDetail->new({'symbol'=>$symbol.$market,'proxy'=>$proxy});

$qd = Finance::YahooJPN::QuoteDetail->new({'symbol'=>$symbol,'proxy'=>$proxy,'market'=>$market})
	
$qd->quote();

$qd->get_symbol_name();
 * you can use this method only if your computer use Japange Character. 

$qd->get_last_trade_price();

$qd->get_high_price();
 
$qd->get_low_price();

$qd->get_prev_close();

$qd->get_volume();

$qd->get_change();

=head1 AUTHOR

QuoteDetail was written by Takashi Saeki F<E<lt>tsaeki@yf7.so-net.ne.jpE<gt>>

=head1 COPYRIGHT AND LICENSE

Copyright (C)2004 Takashi Saeki. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.3 or,
at your option, any later version of Perl 5 you may have available.

=head1 SAMPLE

  $qd = Finance::YahooJPN::QuoteDetail->new({'symbol'=>6758,'market'=>"t"});
  $qd->quote;
  $qd->get_last_trade_price();

  # quote method sets all value into hash, so it's a little slow.

  $qd = Finance::YahooJPN::QuoteDetail->new({'symbol'=>6758,'market'=>"t"});
  $qd->quick_quote;
  $qd->get_last_trade_price();

  # quick_quote method set no value into hash.If you call get_xxxx,method sets one value into hash,and return it.

=head1 ABSTRACT
  This module provides you functions to fetch detail quotes
  of Japanese stock markets from Yahoo-Japan-Finance.

=cut

