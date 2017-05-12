#!/usr/bin/perl -w
use strict;
use File::Spec;
use FindBin;

use vars qw(@related_accounts);
BEGIN {
  @related_accounts = qw( 
                          3299999999
                           799999919
                          9999999995
                          9999999998
                          9999999999
                          );
};

use Test::More tests => 5 + scalar @related_accounts *2;
use Test::MockObject;

BEGIN { use_ok("Finance::Bank::Postbank_de"); };

sub login {
  Finance::Bank::Postbank_de->new(
                  login => '9999999999',
                  password => '11111',
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
  print F $account->agent->content;
  close F;
  diag "Current page saved to '$filename'";
};

# Check that we have SSL installed :
SKIP: {
  skip "Need SSL capability to access the website",3 + + scalar @related_accounts *2
    unless LWP::Protocol::implementor('https');

  my $account = login;

  # Get the login page:
  my $status = $account->get_login_page(&Finance::Bank::Postbank_de::LOGIN);

  # Check that we got a wellformed page back
  SKIP: {
    unless ($status == 200) {
      diag $account->agent->res->as_string;
      skip "Didn't get a connection to ".&Finance::Bank::Postbank_de::LOGIN."(LWP: $status)",3;
    };
    skip "Banking is unavailable due to maintenance", 3 + @related_accounts*2
      if $account->maintenance;
    $account->agent(undef);

    my @fetched_accounts = sort $account->account_numbers;
    if (! is_deeply(\@fetched_accounts,\@related_accounts,"Retrieve account numbers")) {
	diag "Found $_" for @fetched_accounts;
	save_content($account,'accounts');
    };

    for (reverse @fetched_accounts) {
      isa_ok($account->get_account_statement(account_number => $_),'Finance::Bank::Postbank_de::Account', "Account $_")
          or save_content($account,'account-'.$_);
      $account->agent(undef); # workaround for buggy Postbank site
    };
    for (sort @fetched_accounts) {
      isa_ok($account->get_account_statement(account_number => $_),'Finance::Bank::Postbank_de::Account', "Account $_")
          or save_content($account,'account-'.$_);
      $account->agent(undef); # workaround for buggy Postbank site
    };

    ok($account->close_session(),"Close session");
    is($account->agent(),undef,"Agent was discarded");
  };
};

# Now also test for cases where we only have a single giro account :
# We "simply" fake the whole way that account_numbers uses to get
# at the actual account numbers for a login
{
  my $girofile = File::Spec->catfile($FindBin::Bin,'giroselection.html');
  local *F;
  open F, "<$girofile"
    or die "Couldn't open file '$girofile' : $!";
  undef $/;
  my $content = <F>;
  close F;

  my $account = Finance::Bank::Postbank_de->new(
                  login => '9999999999',
                  password => '11111',
                  status => sub {
                              shift;
                              diag join " ",@_
                                if ($_[0] eq "HTTP Code") and ($_[1] != 200)
                                #or $_[0] ne "HTTP Code";
                            },
                );

  no warnings 'once';
  no warnings 'redefine';
  local *Finance::Bank::Postbank_de::select_function = sub {};
  my $f = HTML::Form->parse($content,'https://banking.postbank.de');
  my $agent = Test::MockObject->new()
              ->set_always(current_form     => $f)
              ->set_always(form_name        => $f)
              ->set_always(form_with_fields => $f)
              ->set_always(content          => $content);
  $account->agent($agent);
  is_deeply([$account->account_numbers],["999999999"],"Single account number works");
};
