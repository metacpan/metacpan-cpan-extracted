package Finance::Bank::AllianceAndLeicester;

use strict;
use Carp;
use HTML::TokeParser;
use WWW::Mechanize;

our $VERSION = '1.03';

sub check_balance {

  # Get the inputs, and perform sanity checking.
  my ($class, %opts) = @_;
  croak 'Must provide a customer ID' unless exists $opts{customerid};
  croak 'Must provide memorable information' unless exists $opts{memorable};
  croak 'Must provide a unique phrase' unless exists $opts{phrase};
  croak 'Must provide a PIN code' unless exists $opts{pin};
  croak 'Customer ID should be 8 digits' unless $opts{customerid} =~ /^\d{8}$/;
  croak 'PIN code should be 5 digits' unless $opts{pin} =~ /^\d{5}$/;

  # Initialise the output array.
  my @accounts;

  # Submit the customer ID.
  my $agent = WWW::Mechanize->new();
  $agent->get('https://www.mybank.alliance-leicester.co.uk/index.asp');
  $agent->submit_form(fields    => {txtCustomerID => $opts{customerid}},
                      form_name => 'login');
  croak 'Login failed' unless $agent->success();

  # Submit the memorable information, if necessary.
  if ($agent->form_name('frmChangePIN')) {
    # We've got an extra step to perform.
    $agent->submit_form(fields    => {txtMemDetail => $opts{memorable}},
                        form_name => 'frmChangePIN');
    croak 'Failed to submit memorable data' unless $agent->success();
  }

  # Check we have got the correct unique phrase.
  my $content = $agent->content;
  my $stream = HTML::TokeParser->new(\$content) or die $!;
  for (my $a=0; $a < 5; $a++) {
    $stream->get_tag('span');
  }
  my $phrase = $stream->get_trimmed_text('/span');

  croak 'Unique phrase mismatch' unless (lc($phrase) eq lc($opts{phrase}));

  # Submit the PIN number.
  $agent->submit_form(fields    => {txtCustomerPIN => $opts{pin}},
                      form_name => 'frmPM4point1');
  croak 'Failed to submit PIN' unless $agent->success();

  # Check for login errors.
  $content = $agent->content;
  $stream = HTML::TokeParser->new(\$content) or die $!;
  while (my $token = $stream->get_tag('div')) {
    if ($token->[1]{'id'} && $token->[1]{'id'} eq 'error') {
      my $error = $stream->get_trimmed_text('/div');
      croak "Error during login: $error\n";
      last; # This is just silly.
    }
  }

  # Save this data to parse later.
  $content = $agent->{content};

  # We have the data we need, so let's log out.
  $agent->get('https://www.mybank.alliance-leicester.co.uk/' .
              'login/calls/logout.asp');

  # Begin parsing the HTML.
  $stream = HTML::TokeParser->new(\$content) or die $!;
  $stream->get_tag('tr');

  while (my $token = $stream->get_tag('tr')) {

    my($balance, $name, $overdraft, $account, $available_balance);

    # Get the account name and number.
    $token = $stream->get_tag('td');
    $name = $stream->get_trimmed_text('/td');
    $name =~ s/\s(\d+)$//;
    $account = $1;

    # Get the balance.
    $stream->get_tag('td');
    $balance = $stream->get_trimmed_text('/td');

    # Get the overdraft limit.
    $stream->get_tag('td');
    $overdraft = $stream->get_trimmed_text('/td');

    # Fix up the overdraft amount to zero, if there is no overdraft available.
    $overdraft = 0 if ($overdraft eq 'n/a');

    # Get the available balance.
    $stream->get_tag('td');
    $available_balance = $stream->get_trimmed_text('/td');

    # Strip pounds signs from balances.
    $balance   =~ s/^\x{00A3}//;
    $overdraft =~ s/^\x{00A3}//;
    $available_balance =~ s/^\x{00A3}//;

    # Strip Comma ',' from balances.
    $balance   =~ s/\,//g;
    $overdraft =~ s/\,//g;
    $available_balance =~ s/\,//g;

    # Add to list of accounts to return.
    push(@accounts, {balance           => $balance,
                     name              => $name,
                     overdraft         => $overdraft,
                     account           => $account,
                     available_balance => $available_balance});
  }

  return @accounts;
}

1;

__END__

=head1 NAME

Finance::Bank::AllianceAndLeicester - Check your Alliance & Leicester bank
accounts from Perl

=head1 SYNOPSIS

  use Finance::Bank::AllianceAndLeicester;
  my @accounts = Finance::Bank::AllianceAndLeicester->check_balance(
      customerid  => '01234567',
      pin         => '12345',
      memorable   => 'mybirthplace',
      phrase      => 'my unique phrase'
  );

  foreach (@accounts) {
      printf("%8s(%20s):  GBP %8.2f " .
             "(Overdraft: GBP %8.2f Available: GBP %8.2f)\n",
             $_->{account}, $_->{name},
             $_->{balance}, $_->{overdraft}, $_->{available_balance});
  }

=head1 DESCRIPTION

This module provides a rudimentary interface to the Alliance & Leicester
online banking system at L<https://www.mybank.alliance-leicester.co.uk/>.

=head1 DEPENDENCIES

You will need either L<Crypt::SSLeay> or L<IO::Socket::SSL> installed
for HTTPS support to work with LWP.  This module also depends on
L<WWW::Mechanize> and L<HTML::TokeParser> for screen-scraping.

=head1 CLASS METHODS

=over

=item B<check_balance>

  check_balance ( customerid => $c,
                  pin        => $p,
                  memorable  => $m,
                  phrase     => $s )

Return an array of account hashes, one for each of your bank accounts.

=item customerid

The Customer ID is the 8-digit number supplied with your account.

=item pin

Your 5-digit PIN number.

=item memorable

This is your memorable information, such as your birth place.
This is asked for when you first login to your bank account.

=item phrase

Your unique phrase. This is used to make sure we are connecting to
the Alliance & Leicester website and that the connection has not been hijacked.

This is created when you first sign up for online access to your account, and
can be changed on the Alliance & Leicester internet banking website.

=back

=head1 ACCOUNT HASH KEYS

  $ac->account
  $ac->name
  $ac->balance
  $ac->overdraft
  $ac->available_balance

Return the account number, account name (e.g. 'PlusSaver'), account
balance, account overdraft limit and available balance as a signed floating
point value.

=head1 WARNING

This warning is from Simon Cozens' L<Finance::Bank::LloydsTSB>, and seems
just as apt here.

This is code for B<online banking>, and that means B<your money>, and
that means B<BE CAREFUL>. You are encouraged, nay, expected, to audit
the source of this module yourself to reassure yourself that I am not
doing anything untoward with your banking data. This software is useful
to me, but is provided under B<NO GUARANTEE>, explicit or implied.

=head1 THANKS

Simon Cozens for L<Finance::Bank::LloydsTSB> and Chris Ball for
Finance::Bank::HSBC, upon which most of this code is based.
Andy Lester (and Skud, by continuation) for L<WWW::Mechanize>, Gisle Aas for
L<HTML::TokeParser>.

=head1 CHANGELOG

=over

=item Version 1.03 - 08/06/2009 - Simon Dawson L<tehsi@cpan.org>

* Rewrote to work with most-recent Alliance & Leicester website.

=item Version 1.02 - 10/10/2006 - Ian Bissett L<ian@tekuiti.co.uk>

* Reduced PERL version in Makefile.PL to 5.006001 which should solve some
installation issues.

=item Version 1.01 - 04/10/2006 - Ian Bissett L<ian@tekuiti.co.uk>

* Strip commas (',') from balances.

=back

=head1 AUTHOR

Originally written by Ian Bissett L<ian.bissett@tekuiti.co.uk>;
currently maintained by Simon Dawson L<tehsi@cpan.org>.

=cut
