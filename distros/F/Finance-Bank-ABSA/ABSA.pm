package Finance::Bank::ABSA;
use strict;
use Carp;
our $VERSION = '0.03';
use WWW::Mechanize;
use HTML::TokeParser;

sub check_ABSA_balance {
    my ($class, %opts) = @_;
    my @accounts;
    croak "Must provide a security code" unless exists $opts{seccode};
    croak "Must provide a banking id" unless exists $opts{bankingid};
    croak "Must provide a password" unless exists $opts{mypassword};

    my $self = bless { %opts }, $class;

    my $agent = WWW::Mechanize->new();
    $agent->get("https://vs1.absa.co.za/ibs/UserAuthentication.do");

    # Filling in the login form.
    $agent->form("theForm");
    $agent->field("AccessAccount", $opts{bankingid});
    $agent->field("PIN", $opts{seccode});
    $agent->click("button_processAuthenticate");
    die unless ($agent->success);

    my @secletter = split(//, $opts{mypassword}); # put p/word into an array
    $agent->form("AuthPasswordForm");

    # Now comes to trickery to only provide the requested chars of password
    # Need to determine which of the input fields are class jc-pwdDgt
    # as input fields with class jc-pwdDgtDis aren't required for login
    # This is in order to not need to provide the whole password over the Net!
    my $testpwdDgt = HTML::TokeParser->new(\$agent->content) or die "$!";
    $testpwdDgt->get_tag("form");

    # Go to first input field in form.
    my $pwdToken = $testpwdDgt->get_tag("input");
    while ( $pwdToken->[1]{name} =~ /pwdDgt(\d+)/ )  # Step through all pwdDgt fields only
                                                     # Setting $1 to the pwdDgt number
    {
      if ( $pwdToken->[1]{class} eq "jc-pwdDgt" ) {   # AHA - they want this char!
        $agent->field($pwdToken->[1]{name}, @secletter[$1]);
      }
      $pwdToken = $testpwdDgt->get_tag("input");
    } 

    $agent->click("button_processAuthPassword");
    die unless ($agent->success);

    # Now we have the data, we need to parse it.  This is fragile.
    my $content = $agent->{content};
    my ($split1, $split2)  = split /\<h4\>Balance Enquiries/, $content;
    my ($content, $split2) = split /Click on the account number for a statement/, $split2;

    my $stream = HTML::TokeParser->new(\$content) or die "$!";
    $stream->get_tag("table");
    $stream->get_tag("tr");
    $stream->get_tag("tr");
    $stream->get_tag("tr");

    while (my $token = $stream->get_tag("tr")) {
       $token = $stream->get_tag("td");
       if ($token->[1]{width} eq "5") {
         $stream->get_tag("td");
         my $accountname = $stream->get_trimmed_text("/td");
         $stream->get_tag("td");
         my $accountnumber = $stream->get_trimmed_text("/td");
         $stream->get_tag("td");
         my $accountbalance = $stream->get_trimmed_text("/td");
         my @strarray = split(//, $accountbalance);
         $stream->get_tag("td");
         my $accountavailable = $stream->get_trimmed_text("/td");

         # Octal 240 is used from HTML3.2 spec to replace &nbsp;
         # See Entities.pm under your perl vendor tree
         # I choose to replace it here to easily/correctly cater for later formatting.
         $accountbalance   =~ s/[, ]/./g;
         $accountbalance   =~ s/\240//g;
         $accountavailable =~ s/[, ]/./g;
         $accountavailable =~ s/\240//g;
         $accountname      =~ s/\240//g;

          push @accounts, {
              balance    => $accountbalance,
              name       => $accountname,
              available  => $accountavailable,
              account    => $accountnumber
          };
       }
    }
    return @accounts;
}

1;
__END__

=head1 NAME

Finance::Bank::ABSA - Check your ABSA bank accounts from Perl

=head1 SYNOPSIS

  use Finance::Bank::ABSA;
  my @ABSAaccounts = Finance::Bank::ABSA->check_ABSA_balance(
      bankingid  => "xxxxxxxxx",
      mypassword => "xxxxxxx",
      seccode    => "xxxxxx"
  );

  foreach (@ABSAaccounts) {
      printf "  %-21s : %-18s : ZAR %12.2f : ZAR %12.2f\n",
        $_->{name}, $_->{account}, $_->{balance}, $_->{available};
  }

=head1 DESCRIPTION

This module provides a rudimentary interface to the South African
ABSA online banking system at C<https://vs1.absa.co.za/ibs/UserAuthentication.do>
which is where C<http://www.absadirect.co.za> redirects to.

=head1 DEPENDENCIES

You will need either C<Crypt::SSLeay> or C<IO::Socket::SSL> installed
for HTTPS support to work with LWP.  This module also depends on
C<WWW::Mechanize> and C<HTML::TokeParser> for screen-scraping.

=head1 CLASS METHODS

    check_ABSA_balance(bankingid => $u, mypassword => $p, seccode => $s)

Return an array of account hashes, one for each of your bank accounts.

=head1 ACCOUNT HASH KEYS

    $ac->name
    $ac->account
    $ac->balance
    $ac->available

Returns the account name, account number, real balance and available
balance which includes overdraft/creditlines.

=head1 WARNING

This warning is from Simon Cozens' C<Finance::Bank::LloydsTSB>, and seems
just as apt here.

This is code for B<online banking>, and that means B<your money>, and
that means B<BE CAREFUL>. You are encouraged, nay, expected, to audit
the source of this module yourself to reassure yourself that I am not
doing anything untoward with your banking data. This software is useful
to me, but is provided under B<NO GUARANTEE>, explicit or implied.

=head1 THANKS

Chris Ball for C<Finance::Bank::HSBC>, upon which a lot of this code is
based. Also to Simon Cozens for C<Finance::Bank::LloydsTSB>, upon which
most of C<Finance::Bank::HSBC> is based, Andy Lester (and Skud, by continuation)
for WWW::Mechanize, Gisle Aas for HTML::TokeParser.

=head1 AUTHOR

Leon Cowle C<leon@leolizma.com>

=cut

