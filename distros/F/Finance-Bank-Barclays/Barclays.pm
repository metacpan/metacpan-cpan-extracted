package Finance::Bank::Barclays;
use strict;
use warnings;
use Carp;
our $VERSION='0.12';
use LWP::UserAgent;
use WWW::Mechanize;

# hackery for https proxy support
my $https_proxy=$ENV{https_proxy};
delete $ENV{https_proxy} if($https_proxy);

our $agent = WWW::Mechanize->new(env_proxy=>1);

$agent->env_proxy;     # Load proxy settings (but not the https proxy)
$ENV{https_proxy}=$https_proxy if($https_proxy);

sub check_balance {
	my ($class,%opts)=@_;
	croak "Must provide a membership number" unless exists $opts{memnumber};
	croak "Must provide a passcode" unless exists $opts{passcode};
	croak "Must provide a surname" unless exists $opts{surname};
	croak "Must provide a password/memorable word" unless exists $opts{password};

	my $self=bless { %opts }, $class;

	$agent->quiet(0);
	$agent->get("https://ibank.barclays.co.uk");
	croak "index page not found (".$agent->status().")" unless ($agent->status()==200);
	while(!$agent->follow_link( url_regex => qr/LoginMember.do$/i, text_regex => qr/Log-in/i)) {
		$agent->follow_link(url_regex => qr/Welcome.do$/i ) or croak("couldn't find login link");
	}
	$agent->form(1);
	$agent->field("surname",$opts{surname});
	my $mno=$opts{memnumber};
	if($mno =~ m/^20(\d{10})$/ ) { $mno=$1; }
	$agent->field("membershipNo",$mno); # ignore leading "20"
	$agent->click("Next");
	#print "first: ".$agent->status()."\n";

	# There's a redirect to a 'new version' in there right now
	if(defined($agent->find_link(tag=>"meta",n=>0))) {
		$agent->follow_link(tag=>"meta",n=>0);
	}

	$agent->form(1);
	$agent->field("passCode",$opts{passcode});

	my $content=$agent->content();
	my $letter1=0; my $letter2=0;
	if($content =~ m/letter (\d) of your memorable word.*letter (\d) of your memorable word/si) {
		$letter1=$1;
		$letter2=$2;
	} else {
		croak "couldn't identify which letters to use";
	}
	$agent->field("firstMDC",substr($opts{password},$letter1-1,1));
	$agent->field("secondMDC",substr($opts{password},$letter2-1,1));
	$agent->click("Log-in");

	# parse the "at a glance" page for account balances
	my @page=split(/\n/,$agent->content);
	my $line="";
	my @sortcodes=();
	my @acnumbers=();
	my @balances=();
	foreach $line (@page) {
		if($line =~ m/\s*(\d\d-\d\d-\d\d)\s+(\d+)/) {
			push @sortcodes, $1;
			push @acnumbers, $2;
		} elsif($line =~ m/\<b\>\s*(-?&\#163;[0-9,.]+)\s*\</) {
			$b=$1; $b =~ s/&#163;//; $b =~ s/,//g;
			push @balances, $b;
		}
	}

	croak "sortcodes and balances don't match (".($#sortcodes+1)."/".($#balances+1).")" unless ($#sortcodes == $#balances);

    # try harder to find the real data (Barclays sometimes hide it
	# behind a front screen)

	if($#sortcodes==-1) {
		if($agent->content() =~ m/input.*checkbox.*confirmation/is) {
			$agent->field("confirmation","true"); # ack, checkbox
		}
		$agent->click("Next") or croak "couldn't click while hunting";
		@page=split(/\n/,$agent->content);
		$line="";
		@sortcodes=();
		@acnumbers=();
		@balances=();
		foreach $line (@page) {
			if($line =~ m/\s*(\d\d-\d\d-\d\d)\s+(\d+)/) {
				push @sortcodes, $1;
				push @acnumbers, $2;
			} elsif($line =~ m/\<b\>\s*(-?&\#163;[0-9,.]+)\s*\</) {
				$b=$1; $b =~ s/&#163;//; $b =~ s/,//g;
				push @balances, $b;
			}
		}

		croak "sortcodes and balances don't match (".($#sortcodes+1)."/".($#balances+1).")" unless ($#sortcodes == $#balances);

	}

	my @accounts;
	for(my $i=0; $i<=$#sortcodes; $i++) {
		push @accounts, (bless {
				balance => $balances[$i],
				sort_code => $sortcodes[$i],
				account_no => $acnumbers[$i],
				}, "Finance::Bank::Barclays::Account");
	}
	return @accounts;
}

package Finance::Bank::Barclays::Account;

# magic
no strict;
sub AUTOLOAD { my $self=shift; $AUTOLOAD =~ s/.*:://; $self->{$AUTOLOAD} }


1;
__END__
# Below is stub documentation for your module. You better edit it!

=head1 NAME

Finance::Bank::Barclays - Check your Barclays bank accounts from Perl

=head1 SYNOPSIS

  use Finance::Bank::Barclays;
  my @accounts = Finance::Bank::Barclays->check_balance(
	  memnumber => "xxxxxxxxxxxx",
	  passcode => "12345",
	  surname => "Smith",
	  password => "xxxxxxxx"
  );

  foreach (@accounts) {
	  printf "%8s %8s : GBP %8.2f\n",
	  $_->{sort_code}, $_->{account_no}, $_->{balance};
  }

=head1 DESCRIPTION

This module provides a rudimentary interface to the Barclays Online
Banking service at C<https://ibank.barclays.co.uk>. You will need either
C<Crypt::SSLeay> or C<IO::Socket::SSL> installed for HTTPS support to
work. C<WWW::Mechanize> is required.

=head1 CLASS METHODS

  check_balance(memnumber => $u, passcode => $p, surname => $s,
    password => $w)

Return an array of account objects, one for each of your bank accounts.

=head1 OBJECT METHODS

  $ac->sort_code
  $ac->account_no

Return the account sort code (in the format XX-YY-ZZ) and the account
number.

  $ac->balance

Return the account balance as a signed floating point value.

=head1 WARNING

This warning is from Simon Cozens' C<Finance::Bank::LloydsTSB>, and seems
just as apt here.

This is code for B<online banking>, and that means B<your money>, and
that means B<BE CAREFUL>. You are encouraged, nay, expected, to audit
the source of this module yourself to reassure yourself that I am not
doing anything untoward with your banking data. This software is useful
to me, but is provided under B<NO GUARANTEE>, explicit or implied.

=head1 THANKS

Simon Cozens for C<Finance::Bank::LloydsTSB> and Perl hand-holding.
Chris Ball for C<Finance::Bank::HSBC>.

=head1 AUTHOR

Dave Holland C<dave@biff.org.uk>

=cut

# vi::ts=4:sw=4:ai:cindent
