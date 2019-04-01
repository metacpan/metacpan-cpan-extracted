#!/usr/bin/perl -w
use strict;
use File::Spec;
use FindBin;

our @related_accounts;
BEGIN {
  @related_accounts = qw( 
      DE18201100221234567895
      DE18201100221987654322
      DE49370110000000567855
      DE79100100101234567891
      DE82100100101234567893
  );
};

use Test::More tests => 1 + scalar @related_accounts *2;
use Test::MockObject;

use Finance::Bank::Postbank_de;

sub login {
  Finance::Bank::Postbank_de->new(
                  login => 'Petra.Pfiffig',
                  password => '12345678',
                  status => sub {
                              shift;
                              diag join " ",@_
                                if ($_[0] eq "HTTP Code") and ($_[1] != 200)
                                #or $_[0] ne "HTTP Code";
                            },
                );
};

sub save_content {
  my ($account,$name) = @_;
  local *F;
  my $filename = "$0-$name.html";
  open F, "> $filename"
    or diag "Couldn't dump current page to '$filename': $!";
  binmode F;
  print F $account->api->ua->content;
  close F;
  diag "Current page saved to '$filename'";
};


my $account = login();
my $status = $account->api->ua->status;

# Check that we got a wellformed page back
SKIP: {
  if ($status != 200) {
    diag $account->agent->res->as_string;
    skip "Didn't get a connection to ".&Finance::Bank::Postbank_de::LOGIN."(LWP: $status)",3;
  } elsif( $account->maintenance ) {
      skip "Banking is unavailable due to maintenance", 3 + @related_accounts*2;
  };

  my @fetched_accounts = sort $account->account_numbers;
  if (! is_deeply(\@fetched_accounts,\@related_accounts,"Retrieve account numbers")) {
    diag "Found $_" for @fetched_accounts;
    save_content($account,'accounts');
  };

  for (reverse @fetched_accounts) {
    sleep 1;
    isa_ok($account->get_account_statement(account_number => $_),'Finance::Bank::Postbank_de::Account', "Account $_")
        or save_content($account,'account-'.$_);
    #$account->agent(undef); # workaround for buggy Postbank site
  };
  for (sort @fetched_accounts) {
    sleep 1;
    isa_ok($account->get_account_statement(account_number => $_),'Finance::Bank::Postbank_de::Account', "Account $_")
        or save_content($account,'account-'.$_);
    #$account->agent(undef); # workaround for buggy Postbank site
  };

  #ok($account->close_session(),"Close session");
  #is($account->agent(),undef,"Agent was discarded");
};
