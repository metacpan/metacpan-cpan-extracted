package Finance::Bank::Halifax::Sharedealing;

use strict;
use warnings;
use Carp;
use HTML::TokeParser;
use WWW::Mechanize;

=head1 NAME

Finance::Bank::Halifax::Sharedealing - access Halifax Sharedealing accounts from Perl.

=head1 VERSION

Version 0.03

=cut

our $VERSION = '0.03';

=head1 SYNOPSIS

    use Finance::Bank::Halifax::Sharedealing;

    # Set up the login details
    my $sd = Finance::Bank::Halifax::Sharedealing->new(
        username => 'myusername',
        password => 'mysecretpassword',
        security_mother_first_name => 'Alice',
        security_father_first_name => 'Bob',
        security_school_name => 'Somewheretown Primary School',
        security_birthplace => 'Somewheretown',
    );

    $sd->log_in();

    # Get the user's accounts and print a brief statement for each one.
    my %accounts = $sd->get_all_accounts();
    foreach my $account_id (keys(%accounts)) {
        $sd->set_account($account_id);
        print "Account: " . $accounts{$account_id} . "\n";
        print "Available to invest: " . $sd->get_available_cash() . "\n";

        my @portfolio = $sd->get_portfolio();
        if (@portfolio) {
            print "Share\tValuation\n";
            foreach my $share (@portfolio) {
                print $share->{'symbol'} . "\t";
                print $share->{'valuation'} . "\n";
            }
        }
        print "\n";
    }

    $sd->log_out();

=head1 DESCRIPTION

This module provides an interface to the Halifax online share dealing
service at L<https://www.halifaxsharedealing-online.co.uk/>. It requires
C<WWW::Mechanize>, C<HTML::TokeParser>, and either C<Crypt::SSLeay> or
C<IO::Socket::SSL>.

=head1 METHODS

=cut

# Global constants - these will only change if Halifax reorganise their
# share dealing site.

# URL of the login page
use constant LOGIN_PAGE => 'https://www.halifaxsharedealing-online.co.uk/_mem_bin/formslogin.asp';

# Text of the link to view your statements
use constant STATEMENTS_LINK_TEXT => 'My Statements';

# Name of the account select box on the statements page.
use constant ACCOUNT_SELECT_BOX_NAME => 'AccNavList';

# Name of the form that contains the 'Sign out' button.
use constant HEADER_FORM_NAME => 'frmHeaderButtons';


##################
# Public methods #
##################

=head2 new(username => $u, password => $p, security_mother_first_name => $m, security_father_first_name => $f, security_school_name => $s, security_birthplace => $b)

Returns a new Sharedealing object.

The required arguments are the user's login details as a list of key/value
pairs. Answers are required for all the possible security questions, as we
don't know in advance which one the site will ask us.

=cut

sub new {
  my ($class, %opts) = @_;

  croak 'Username not specified' if not exists $opts{username};
  croak 'Password not specified' if not exists $opts{password};
  croak "Security answer not specified: mother's first name"
    if not exists $opts{security_mother_first_name};
  croak "Security answer not specified: father's first name"
    if not exists $opts{security_father_first_name};
  croak 'Security answer not specified: name of first school'
    if not exists $opts{security_school_name};
  croak 'Security answer not specified: place/town of birth'
    if not exists $opts{security_birthplace};

  my $self = {
       agent => new WWW::Mechanize(autocheck => 1),
       username => $opts{username},
       password => $opts{password},
       security_mother_first_name => $opts{security_mother_first_name},
       security_father_first_name => $opts{security_father_first_name},
       security_school_name => $opts{security_school_name},
       security_birthplace => $opts{security_birthplace},
       _account => '',
     };

  bless $self, $class;
  return $self;
}


=head2 log_in()

Log in, using the security details that were passed to C<new()>. This will
set the currently-selected account to the user's default account.

Returns true if logging in was successful.

=cut

sub log_in {
  # ID attribute of the login form
  use constant LOGIN_FORM_ID => 'frmFormsLogin';

  my $self = shift;
  $self->{agent}->get(LOGIN_PAGE);
  $self->{agent}->form_id(LOGIN_FORM_ID);
  $self->{agent}->field('Username', $self->{username});
  $self->{agent}->field('password', $self->{password});

  # Find out what the security question is and select the appropriate answer
  my $stream = HTML::TokeParser->new(\$self->{agent}->{content});
  my $answer = '';
  while (my $tag = $stream->get_tag('strong')) {
    my $text = '';
    $text = $stream->get_trimmed_text('/strong');
    if ($text =~ /town of birth/) {
      $answer = $self->{security_birthplace};
    } elsif ($text =~ /Your father's first name/) {
      $answer = $self->{security_father_first_name};
    } elsif ($text =~ /Your mother's first name/) {
      $answer = $self->{security_mother_first_name};
    } elsif ($text =~ /The name of your first school/) {
      $answer = $self->{security_school_name};
    }
  }
  die 'Security question field not found' if !$answer;
  $self->{agent}->field('answer', $answer);

  # Now we've got the answer, submit the page.
  $self->{agent}->submit();

  # Set the currently-selected account to the default.
  $self->{_account} = $self->_get_account_from_url($self->{agent}->uri);
  return 1;
}


=head2 log_out()

Log out by clicking the 'Sign Out' button.

Returns true if logging out was successful.

=cut

sub log_out {
  # The 'Sign off' URL, where the sign off/out button sends you.
  use constant SIGN_OFF_URL => 'https://www.halifaxsharedealing-online.co.uk/_mem_bin/SignOff.asp';

  my $self = shift;

  my $form = $self->{agent}->get(SIGN_OFF_URL);
  return 1;
}


=head2 get_all_accounts()

Get all the accounts that can be managed from this user's login.

Returns a hash with account IDs (e.g. "D12345678") as the keys, and account 
names (e.g. "MR J SMITH, Halifax ShareBuilder 01") as the values.

=cut

sub get_all_accounts {
  my $self = shift;
  my %accounts;

  # Go to the statements page, which has a select box with all the
  # accounts in it.
  $self->{agent}->follow_link(text => STATEMENTS_LINK_TEXT);

  # Find the select box and extract the account details.
  my $stream = HTML::TokeParser->new(\$self->{agent}->{content});

  while (my $token = $stream->get_token) {
    my $ttype = shift @{ $token };

    # Is this a start tag?
    if($ttype eq 'S') {
      my ($tag, $attr, $attrseq, $rawtxt) = @{ $token };

      # Is it the account selection box?
      if($tag eq 'select' && $attr->{name} eq ACCOUNT_SELECT_BOX_NAME) {
        # Found the select box.
        # Now go through each option until we reach the ending select tag.
        until ($ttype eq 'E' && $tag eq 'select') {
          $token = $stream->get_token;
          ($ttype, $tag, $attr, $attrseq, $rawtxt) = @{ $token };
          # if we find an opening 'option' tag AND it has a non-blank value
          # (so we skip the 'Show me a different account' option).
          if($ttype eq 'S' && $tag eq 'option' && $attr->{value}) {
            # parse for account ID and account name, then add them to %accounts
            my $account_code = $self->_get_account_from_url($attr->{value});
            my $account_name = $stream->get_trimmed_text('/option');
            $accounts{$account_code} = $account_name;
          }
        }
      }
    }
  }
  return %accounts;
}


=head2 set_account($account)

Set or change the account we're using.

C<$account>: the account ID of the account to switch to.

Returns true if the account was successfully set, otherwise false.

=cut

sub set_account {
  my ($self, $account) = @_;

  my $base_url = $self->_get_url_without_account_code($self->{agent}->uri);

  if ($base_url) {
    $self->{agent}->get($base_url . $account);
    $self->{_account} = $account;
    return 1;
  }
  warn "Couldn't set the account ID to $account\n";
  return 0;
}


=head2 get_account()

Get the ID of the account we're currently using.

Returns the account ID of the currently-selected account (or an empty string
if there isn't a selected account yet).

=cut

sub get_account {
  my $self = shift;

  return $self->{_account};
}


=head2 get_portfolio()

Get a portfolio statement for the currently-selected account.

Returns an array. Each element of the array is a hash with the keys:

 symbol: the ticker symbol of the stock.
 exchange: the exchange on which the stock is listed.
 quantity: the number of shares owned.
 avg_cost: the average cost per share (in pence).
 latest_price: the latest quoted price per share (in pence).
 change: result of subtracting avg_cost from latest_price (in pence)
 book_cost: total cost of the holding (in pounds)
 valuation: value of the holding at the latest market price (in pounds).
 profit_loss_absolute: the profit or loss on the holding in pounds.
 profit_loss_percent: the profit or loss on the holding in percent.

All hash values are the raw contents of the data cell - you should not assume
that any of them will be valid numbers.

=cut

sub get_portfolio {
  my $self = shift;

  $self->{agent}->follow_link(text => STATEMENTS_LINK_TEXT);

  my @portfolio;
  my $stream = HTML::TokeParser->new(\$self->{agent}->{content});

  # Find the portfolio table
  my $table;
  my ($ttype, $tag, $attr, $attr_seq, $text);
  do {
    $table = $stream->get_tag('table');
    ($tag, $attr, $attr_seq, $text) = @{ $table } if $table;
  } until (!$table || ($attr->{class} && $attr->{class} eq 'DataTable'));

  # Couldn't find the table, so just return. Don't give an error,
  # because we might just be looking at an account with no holdings.
  if (!$table) {
    return @portfolio;
  }

  # Until we get to the end of the table:
  do {
    my $token = $stream->get_token;
    ($ttype, $tag, $attr, $attr_seq, $text) = @{ $token };

    # Process each row we find
    if ($ttype eq 'S' && $tag eq 'tr') {
      my @row_contents;
      # Until we get to the end of the row:
      do {
        $token = $stream->get_token;
        ($ttype, $tag, $attr, $attr_seq, $text) = @{ $token };
        # Get the contents of each cell, but ignore header cells.
        if ($ttype eq 'S' && $tag eq 'td' && $attr->{class} && $attr->{class} ne 'DataTableCollHeader') {
          my $cell_contents = $stream->get_trimmed_text('/td');
          push(@row_contents, $cell_contents);
        }
      } until (!$tag || ($ttype eq 'E' && ($tag eq 'table' || $tag eq 'tr')));
      # Add the contents of the row we've just processed to the output array.
      if (@row_contents >= 10) {
        my $new_row = {
          'symbol' => $row_contents[0],
          'exchange' => $row_contents[1],
          'quantity' => $row_contents[2],
          'avg_cost' => $row_contents[3],
          'latest_price' => $row_contents[4],
          'change' => $row_contents[5],
          'book_cost' => $row_contents[6],
          'valuation' => $row_contents[7],
          'profit_loss_absolute' => $row_contents[8],
          'profit_loss_percent' => $row_contents[9],
        };
        push(@portfolio, $new_row);
      }
    }
  } until (!$tag || ($ttype eq 'E' && $tag eq 'table'));

  return @portfolio;
}


=head2 get_available_cash()

Get the uninvested cash balance for the currently-selected account.

Returns the uninvested cash balance as a (ISO-8859-1) string, with currency
symbol.

=cut

sub get_available_cash {
  my $self = shift;
  my $cash;

  $self->{agent}->follow_link(text => STATEMENTS_LINK_TEXT);

  my $stream = HTML::TokeParser->new(\$self->{agent}->{content});

  while (my $td = $stream->get_tag('td')) {
    my ($tag, $attr, $attr_seq, $text) = @{ $td };
    # Look in the account summary area.
    if($attr->{class} && $attr->{class} eq 'summaryBoxesText') {
      # Are we at the "Available to invest" line?
      my $text = $stream->get_trimmed_text('/td');
      if ($text && ($text =~ /Available to invest/ || $text =~ /Cash in account/)) {
        # If so, get what's in the next <td class="summaryBoxesValues">
        my $cash_td;
        my ($c_tag, $c_attr, $c_attr_seq, $c_text);
        do {
          $cash_td = $stream->get_tag('td');
          if ($cash_td) {
            ($c_tag, $c_attr, $c_attr_seq, $c_text) = @{ $cash_td };
          }
        } until (!$cash_td || $c_attr->{class} eq 'summaryBoxesValues');
        $cash = $stream->get_trimmed_text('/td') if $cash_td;
      }
    }
  }
  return $cash;
}

###################
# Private methods #
###################

# _get_url_without_account_code()
#
# Given a URL from the share dealing site (after logging in), return it
# without the account code on the end.
#
# Arguments:
# $url: the URL from which to remove the account code.
#
# Returns the URL without the account code, or false if the account code
# was not found.
sub _get_url_without_account_code {
  my ($self, $url) = @_;
  my $base = '';

  $url =~ /^(.*PortCode=)\w+/i;
  $base = $1;

  return $base;
}

# _get_account_from_url()
#
# Given a URL from the share dealing site (after logging in), return the
# account code from it. Returns an empty string if no account code could
# be found.
#
# Arguments:
# $url: the URL from which to extract the account code.
#
# Returns the account code, or false if the account code was not found in
# the URL.
sub _get_account_from_url {
  my ($self, $url) = @_;
  my $account = '';

  $url =~ /PortCode=(\w+)/i;
  $account = $1;

  return $account;
}


=head1 WARNING

Taken from Simon Cozens' C<Finance::Bank::LloydsTSB>, because it's just
as relevant here:

This is code for B<online banking>, and that means B<your money>, and
that means B<BE CAREFUL>. You are encouraged, nay, expected, to audit
the source of this module yourself to reassure yourself that I am not
doing anything untoward with your banking data. This software is useful
to me, but is provided under B<NO GUARANTEE>, explicit or implied.

=head1 AUTHOR

Rayner Lucas, C<< <cpan at magic-cookie.co.uk> >>

=head1 BUGS

Please report any bugs or feature requests to 
C<bug-finance-bank-halifax-sharedealing at rt.cpan.org>, or through the web 
interface at 
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Finance-Bank-Halifax-Sharedealing>.  
I will be notified, and then you'll automatically be notified of progress 
on your bug as I make changes.  


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Finance::Bank::Halifax::Sharedealing


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Finance-Bank-Halifax-Sharedealing>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Finance-Bank-Halifax-Sharedealing>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Finance-Bank-Halifax-Sharedealing>

=item * Search CPAN

L<http://search.cpan.org/dist/Finance-Bank-Halifax-Sharedealing/>

=back


=head1 ACKNOWLEDGEMENTS

Thanks to the CPAN authors whose modules made this one possible, and to
Simon Cozens for C<Finance::Bank::LloydsTSB>.

=head1 LICENSE AND COPYRIGHT

Copyright 2011 Rayner Lucas.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut


1; # End of Finance::Bank::Halifax::Sharedealing
