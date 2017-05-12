package Finance::Bank::Wachovia::DataObtainer::WWW::Parser;
use strict;
use warnings;

sub get_credit_account_current_balance {
	get_account_available_balance( @_ );
}

sub get_credit_account_available_credit {
	$_[-1] =~ /<!-- start description insertion -->Available Credit<!-- end description insertion -->/g;
	my($avail) = $_[-1] =~ /\G.*?<!-- start amount insertion -->\$([\d,.-]+)<!-- end amount insertion -->/s;
	$avail =~ s/,//g;
	return $avail; 
}

sub get_credit_account_limit {
	$_[-1] =~ /<!-- start description insertion -->Credit Limit<!-- end description insertion -->/g;
	my($limit) = $_[-1] =~ /\G.*?<!-- start amount insertion -->\$([\d,.-]+)<!-- end amount insertion -->/s;
	$limit =~ s/,//g;
	return $limit; 
}

sub get_account_numbers {
	my $content = $_[-1];
	my @nums;
	while( $content =~ m/<!-- begin data row -->/g ){
		my($num) = $content =~ /\G.*?HREF="javascript\:sendForm\('(\d+)','Account(?:Detail|Summary)'\)">.*?<\/A>/s;
		push @nums, $num;
	}
	return @nums;
}

sub get_account_available_balance {
	my $account_num = $_[-1];
	my $content = $_[-2];
	while($content =~ m/<!-- begin data row -->/g){
		my($num) = $content =~ /\G.*?HREF="javascript\:sendForm\('(\d+)','Account(?:Detail|Summary)'\)">.*?<\/A>/s;
		my $bal;
		($bal) = $content =~ /\G.*?\$(\-?[\d,.-]+)/s;
		$bal =~ s/,//g;
		if( $num eq $account_num ){
			return $bal;
		}
	}
}

sub get_account_posted_balance {
	my $content = $_[-1];
	my $bal;
	($bal) = $content =~ m|Posted Balance: &nbsp;&nbsp;&nbsp;</B><!-- start balance insertion -->\$([\d,.-]+)|g;
	$bal =~ s/,//g;
	return $bal;
}

sub get_account_name {
	my $account_num = $_[-1];
	my $content = $_[-2];
	while($content =~ m/<!-- begin data row -->/g){
		my($num,$name) = $content =~ /\G.*?HREF="javascript\:sendForm\('(\d+)','Account(?:Detail|Summary)'\)">(.*?)<\/A>/s;
		my $bal;
		($bal) = $content =~ /\G.*?\$(\-?[\d,.-]+)/s;
		$bal =~ s/,//g;
		if( $num eq $account_num ){
			return lc $name;
		}
	}
}

sub get_account_type {
	my $content = $_[-1];
	my $type;
	($type) = $content =~ m/<!--  start account type insertion -->(.+?)<!--  end account type insertion -->/g;	
	return lc $type;
}

sub get_account_transactions {
	my $content = $_[-1];
	my @all_trans;
	while( $content =~ m/^var tblRow\d+ = new Array (.+?);$/mg ){
		my %trans;
		@trans{
			qw(
				date
				action
				description
				withdrawal_amount
				deposit_amount
				balance
				seq_no
				trans_code
				check_num
			)
		} = eval $1;
		# this loop just gets rid of some dollar signs and commas that we don't need
		for(qw/withdrawal_amount deposit_amount balance/){
			next unless $trans{$_};
			$trans{$_} =~ s/\$|,//g;
			$trans{$_} =~ s/&nbsp;//g;
		}
		push @all_trans, \%trans;
	}
	return \@all_trans;
}

1;
