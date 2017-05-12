package Finance::Bank::US::INGDirect;

use strict;

use Carp 'croak';
use LWP::UserAgent;
use HTTP::Cookies;
use HTML::TableExtract;
use Date::Parse;
use Data::Dumper;

=pod

=head1 NAME

Finance::Bank::US::INGDirect - Check balances and transactions for US INGDirect accounts

=head1 VERSION

Version 0.08

=cut

our $VERSION = '0.08';

=head1 SYNOPSIS

  use Finance::Bank::US::INGDirect;
  use Finance::OFX::Parse::Simple;

  my $ing = Finance::Bank::US::INGDirect->new(
      saver_id => '...',
      customer => '########',
      questions => {
          # Your questions may differ; examine the form to find them
          'AnswerQ1.4' => '...', # In what year was your mother born?
          'AnswerQ1.5' => '...', # In what year was your father born?
          'AnswerQ1.8' => '...', # What is the name of your hometown newspaper?
      },
      pin => '########',
  );

  my $parser = Finance::OFX::Parse::Simple->new;
  my @txs = @{$parser->parse_scalar($ing->recent_transactions)};
  my %accounts = $ing->accounts;

  for (@txs) {
      print "Account: $_->{account_id}\n";
      printf "%s %-50s %8.2f\n", $_->{date}, $_->{name}, $_->{amount} for @{$_->{transactions}};
      print "\n";
  }

=head1 DESCRIPTION

This module provides methods to access data from US INGdirect accounts,
including account balances and recent transactions in OFX format (see
Finance::OFX and related modules). It also provides a method to transfer
money from one account to another on a given date.

=cut

my $base = 'https://secure.ingdirect.com/myaccount';

=pod

=head1 METHODS

=head2 new( saver_id => '...', customer => '...', questions => {...}, pin => '...' )

Return an object that can be used to retrieve account balances and statements.
See SYNOPSIS for examples of challenge questions.

=cut

sub new {
    my ($class, %opts) = @_;
    my $self = bless \%opts, $class;

    $self->{ua} ||= LWP::UserAgent->new(cookie_jar => HTTP::Cookies->new);

    _login($self);
    $self;
}

sub _login {
    my ($self) = @_;

    my $response = $self->{ua}->get("$base/INGDirect/login.vm");

    $response = $self->{ua}->post("$base/INGDirect/login.vm", [
        publicUserId => $self->{saver_id},
    ]);
    $response->is_redirect && $response->header('location') =~ /security_questions.vm/
        or croak "Initial login failed.";

    $response = $self->{ua}->get("$base/INGDirect/security_questions.vm");
    $response->is_success or croak "Retrieving challenge questions failed.";

    my @questions = map { s/^.*(AnswerQ.*)span".*$/$1/; $_ }
        grep /AnswerQ/,
        split('\n', $response->content);
    croak "Didn't understand questions." if @questions != 2;

    $response = $self->{ua}->post("$base/INGDirect/security_questions.vm", [
        TLSearchNum => $self->{customer},
        'customerAuthenticationResponse.questionAnswer[0].answerText' => $self->{questions}{$questions[0]},
        'customerAuthenticationResponse.questionAnswer[1].answerText' => $self->{questions}{$questions[1]},
        '_customerAuthenticationResponse.device[0].bind' => 'false',
    ]);
    $response->is_redirect && $response->header('location') =~ /login_pinpad.vm/
        or croak "Submitting challenge responses failed.";

    $response = $self->{ua}->get("$base/INGDirect/login_pinpad.vm");
    $response->is_success or croak "Loading PIN form failed.";

    my @keypad = map { s/^.*mouseUpKb\("([A-Z])".*$/$1/; $_ }
        grep /pinKeyboard[A-Z]number/,
        split('\n', $response->content);

    unshift(@keypad, pop @keypad);

    $response = $self->{ua}->post("$base/INGDirect/login_pinpad.vm", [
        'customerAuthenticationResponse.PIN' => join '', map { $keypad[$_] } split//, $self->{pin},
    ]);
    $response->is_redirect && $response->header('location') =~ /postlogin/
        or croak "Submitting PIN failed.";

    $response = $self->{ua}->get("$base/INGDirect/postlogin");
    # XXX This is how it behaves in my browser, but not with
    # LWP::UserAgent, so we can apparently just skip this step...
    #$response->is_redirect && $response->header('location') =~ /account_summary.vm/
    #    or croak "Post login redirect failed.";

    #$response = $self->{ua}->get("$base/INGDirect/account_summary.vm");
    # XXX ...and the postlogin screen has the account summary.
    $response->is_success or croak "Account summary fetch failed.";
    $self->{_account_screen} = $response->content;
}

=pod

=head2 accounts( )

Retrieve a list of accounts:

  ( '####' => [ number => '####', type => 'Orange Savings', nickname => '...',
                available => ###.##, balance => ###.## ],
    ...
  )

=cut

sub accounts {
    my ($self) = @_;

    my $te = HTML::TableExtract->new( 
        attribs => { cellpadding => 0, cellspacing => 0 } 
    );
    my $account_screen = $self->{_account_screen};
    $account_screen =~ s/&nbsp;/ /g; # &nbsp; makes TableExtract unhappy
    $te->parse($account_screen);

    my %accounts;
    my $seen_header = 0;

    $te->tables or croak "Can't extract accounts table.";

    foreach my $row (($te->tables)[0]->rows) {
      if ($row->[0] =~ /Account Type/) {
        $seen_header++;
        next;
      }
      next unless $seen_header;

      foreach (@$row) {
        s/^\s*//;  s/\s*$//; s/[\n\r]/ /g; s/\s+/ /g;
      }

      my %account;
      ($account{type}, $account{nickname}) = split / - /, shift @$row;
      ($account{number},
       $account{balance},
       $account{available}) = map { s/^.+:\s+//; s/,//g; $_ ; } @$row;
      next unless $account{type}; # don't include total row
      $accounts{$account{number}} = \%account
        if $account{number};
    }

    %accounts;
}

=pod

=head2 recent_transactions( $account, $days )

Retrieve a list of transactions in OFX format for the given account
(default: all accounts) for the past number of days (default: 30).

=cut

sub recent_transactions {
    my ($self, $account, $days) = @_;

    $account ||= 'ALL';
    $days ||= 30;

    my $response = $self->{ua}->post("$base/download.qfx", [
        type => 'OFX',
        TIMEFRAME => 'STANDARD',
        account => $account,
        FREQ => $days,
    ]);
    $response->is_success or croak "OFX download failed.";

    $response->content;
}

=pod

=head2 transactions( $account, $from, $to )

Retrieve a list of transactions in OFX format for the given account
(default: all accounts) in the given time frame (default: pretty far in the
past to pretty far in the future).

=cut

sub transactions {
    my ($self, $account, $from, $to) = @_;

    $account ||= 'ALL';
    $from ||= '2000-01-01';
    $to ||= '2038-01-01';

    my @from = strptime($from);
    my @to = strptime($to);

    $from[4]++;
    $to[4]++;
    $from[5] += 1900;
    $to[5] += 1900;

    my $response = $self->{ua}->post("$base/download.qfx", [
        type => 'OFX',
        TIMEFRAME => 'VARIABLE',
        account => $account,
        startDate => sprintf("%02d/%02d/%d", @from[4,3,5]),
        endDate   => sprintf("%02d/%02d/%d", @to[4,3,5]),
    ]);
    $response->is_success or croak "OFX download failed.";

    $response->content;
}

=pod

=head2 transfer( $from, $to, $amount, $when )

Transfer money from one account number to another on the given date
(default: immediately). Returns the confirmation number. Use at your
own risk.

=cut

sub transfer {
    my ($self, $from, $to, $amount, $when) = @_;
    my $type = $when ? 'SCHEDULED' : 'NOW';

    if($when) {
        my @when = strptime($when);
        $when[4]++;
        $when[5] += 1900;
        $when = sprintf("%02d/%02d/%d", @when[4,3,5]);
    }

    my $response = $self->{ua}->get("$base/INGDirect/money_transfer.vm");
    my ($page_token) = map { s/^.*value="(.*?)".*$/$1/; $_ }
        grep /<input.*name="pageToken"/,
        split('\n', $response->content);

    $response = $self->{ua}->post("$base/INGDirect/deposit_transfer_input.vm", [
        pageToken => $page_token,
        action => 'continue',
        amount => $amount,
        sourceAccountNumber => $from,
        destinationAccountNumber => $to,
        depositTransferType => $type,
        $when ? (scheduleDate => $when) : (),
    ]);
    $response->is_redirect or croak "Transfer setup failed.";

    $response = $self->{ua}->get("$base/INGDirect/deposit_transfer_validate.vm");
    ($page_token) = map { s/^.*value="(.*?)".*$/$1/; $_ }
        grep /<input.*name="pageToken"/,
        split('\n', $response->content);

    $response = $self->{ua}->post("$base/INGDirect/deposit_transfer_validate.vm", [
        pageToken => $page_token,
        action => 'submit',
    ]);
    $response->is_redirect or croak "Transfer validation failed. Check your account!";

    $response = $self->{ua}->get("$base/INGDirect/deposit_transfer_confirmation.vm");
    $response->is_success or croak "Transfer confirmation failed. Check your account!";
    my ($confirmation) = map { s/^.*Number">(\d+)<.*$/$1/; $_ }
        grep /<span.*id="confirmationNumber">/,
        split('\n', $response->content);

    $confirmation;
}

1;

=pod

=head1 AUTHOR

This version by Steven N. Severinghaus <sns-perl@severinghaus.org>
with contributions by Robert Spier.

=head1 COPYRIGHT

Copyright (c) 2011 Steven N. Severinghaus. All rights reserved. This
program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=head1 SEE ALSO

Finance::Bank::INGDirect, Finance::OFX::Parse::Simple

=cut

