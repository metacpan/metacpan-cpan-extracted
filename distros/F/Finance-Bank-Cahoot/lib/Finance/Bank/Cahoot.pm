# Copyright (c) 2008 Jon Connell.
# All Rights Reserved.
#
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.

package Finance::Bank::Cahoot;

use strict;
use warnings 'all';
use vars qw($VERSION @REQUIRED_SUBS);

$VERSION = '1.07';
@REQUIRED_SUBS = qw(account place date maiden username password);

use Carp qw(croak);
use Time::Local qw(timegm);
use Encode;
use English '-no_match_vars';
use HTML::TableExtract;
use WWW::Mechanize;

use Finance::Bank::Cahoot::Statement;
use Finance::Bank::Cahoot::DirectDebit;

sub new
{
  my ($class, %opts) = @_;

  croak 'Must provide a credentials handler' if not exists $opts{credentials};

  my $self = { _mech        => new WWW::Mechanize(autocheck => 1),
	       _credentials => $opts{credentials},
	       _connected   => 0,
	     };
  $self->{_mech}->agent_alias('Mac Safari');

  bless $self, $class;
  $self->_set_credentials(%opts);
  return $self;
}

sub _set_credentials
{
  my ($self, %opts) = @_;

  croak 'Must provide either a premade credentials object or a class name together with options'
      if not exists $opts{credentials};

  if (ref $opts{credentials}) {
    croak 'Not a valid credentials object'
      if not $self->_isa_credentials($opts{credentials});

    croak 'Can\'t accept credential options if supplying a premade credentials object'
	if exists $opts{credentials_options};

    $self->{_credentials} = $opts{credentials};
  } else {
    croak 'Must provide credential options unless suppying a premade credentials object'
	if not exists $opts{credentials_options};

    $self->{_credentials} =
      $self->_new_credentials($opts{credentials}, $opts{credentials_options});
  }
  return $self;
}

sub _new_credentials
{
  my ($self, $class, $options) = @_;

  croak 'Invalid class name'
    if $class !~ /^(?:\w|::)+$/;

  my $full_class = 'Finance::Bank::Cahoot::CredentialsProvider::'.$class;

  eval "local \$SIG{'__DIE__'}; local \$SIG{'__WARN__'}; require $full_class;";  ## no critic
  croak 'Not a valid credentials class - not found' if $EVAL_ERROR;

  my $credentials;
  {
    local $Carp::CarpLevel = $Carp::CarpLevel + 1;   ## no critic
    $credentials = $full_class->new(credentials => [@REQUIRED_SUBS],
				    options => $options);
  }
  croak 'Not a valid credentials class - incomplete' if not $self->_isa_credentials($credentials);
  return $credentials;
}

sub _isa_credentials
{
  my ($self, $credentials) = @_;

  foreach my $sub (@REQUIRED_SUBS) {
    return unless defined eval {
      local $SIG{'__DIE__'};       ## no critic
      local $SIG{'__WARN__'};      ## no critic
      $credentials->can($sub);
    };
  }

  return 1;
}

sub login
{
  my ($self) = @_;

  return if $self->{_connected};

  $self->_get('https://securebank.cahoot.com/AquariusSecurity/bks/web/en/core_banking/log_in/frameset_top_log_in.jsp');
  my %fields = (inputuserid => $self->{_credentials}->username());
  my $content = $self->{_mech}->content;
  foreach my $input ($self->{_mech}->find_all_inputs()) {
     my $name = $input->name();
     next if not defined $name;
     next if defined $fields{$name};
     $fields{$name} = $self->{_credentials}->place() if $content =~ /address or place:/i;
     $fields{$name} = $self->{_credentials}->date() if $content =~ /memorable year:/i;
     $fields{$name} = $self->{_credentials}->maiden() if $content =~ /maiden name:/i;
  }
  $self->_submit_form(fields => \%fields);

  my %chars;
  my $label;
  # Expect:
  #   <label for="passwordChar1">... select character #d ...</label>
  HTML::Parser->new(unbroken_text => 1,
		    report_tags   => [qw(label)],
		    start_h       => [ sub {
					 return if not defined $_[0]->{for};
					 return if $_[0]->{for} !~ /passwordChar(\d+)/;
					 $label = $1 if defined $1;
				       }, 'attr' ],
		    end_h         => [ sub {
					 $label = undef;
				       } ],
		    text_h        => [ sub {
					 return if not defined $label;
					 $_[0] =~ /select character.*?(\d+)/;
					 $chars{$label} = $1 if defined $1;
				       }, 'dtext' ])->parse($self->{_mech}->content());

  {
    # We submit a form, modifying hidden fields - WWW::Mechanize does not like
    # this (see FAQ).
    local $^W = 0; ## no critic
    $self->_submit_form(fields => { passwordChar1Hidden => $self->{_credentials}->password($chars{1}),
				    passwordChar2Hidden => $self->{_credentials}->password($chars{2}),
				    passwordChar1 => q{*},
				    passwordChar2 => q{*} });
  }
  $self->{_connected} = 1;
  return $self;
}

sub _test_content_for_error
{
  my ($self) = @_;
  
  croak 'Login failed'
    if $self->{_mech}->content =~ m{We cannot recognise those details};
  croak 'General system error returned from Cahoot server'
    if $self->{_mech}->content =~ m{/AquariusSecurity/web/en/GeneralSystemError.html};
    return;
}

sub _get
{
  my ($self, $url) = @_;
  
  $self->{_mech}->get($url);
  $self->_test_content_for_error;
  return;
}

sub _submit_form
{
  my ($self, @args) = @_;
  
  $self->{_mech}->submit_form(@args);
  $self->_test_content_for_error;
  return;
}

sub _get_frames
{
  my ($self) = @_;

  foreach my $link ($self->{_mech}->find_all_links(tag => 'frame')) {
    $self->_get($link->url());
  }
  return;
}

sub _trim
{
  my ($str) = @_;
  return if not defined $str;
  $str =~ s/[\x80-\xff]//gs;
  $str =~ s/\r//gs;
  $str =~ s/\s+/ /gs;
  $str =~ s/^\s+//gs;
  $str =~ s/\s+$//gs;
  return $str;
}

sub _trim_table
{
  my ($table) = @_;
  my @new;
  ROW: foreach my $row (@{$table}) {
    foreach my $col (@{$row}) {
      next ROW if not defined $col;
      $col = _trim $col;
    }
    push @new, $row;
  }
  return \@new;
}

sub set_account
{
  my ($self, $account) = @_;

  croak 'set_account called with no account number' if not defined $account;
  return if defined $self->{_current_account} and $self->{_current_account} eq $account;
  $self->login();
  $self->{_accounts} = $self->accounts if not defined $self->{_accounts};
  my $account_index;
  foreach my $account_details (@{$self->{_accounts}}) {
    $account_index = $account_details->{account_index} if $account_details->{account} eq $account or $account_details->{name} eq $account;
  }
  croak 'set_account called with invalid account details' if not defined $account_index;
  $self->_get('/servlet/com.aquariussecurity.accounts.servlet.PersonalHomepageSelectionServlet?productType=MTA&Index='.$account_index.'&origin=init');
  $self->_get_frames();
  $self->{_current_account} = $account;
  delete $self->{_statements} if defined $self->{_statements};
  return $self;
}

sub statement
{
  my ($self, $account) = @_;

  $self->login();
  $self->set_account($account) if defined $account;
  croak 'No account currently selected' if not defined $self->{_current_account};

  $self->_get('/servlet/com.aquariussecurity.accounts.servlet.CurrentAccountStatementEntryServlet?print=yes');
  my $te = HTML::TableExtract->new(headers => [qw(Date Transaction Withdrawn Paid Balance)]);
  $te->parse($self->{_mech}->content);
  my @table = $te->first_table_found->rows;
  return Finance::Bank::Cahoot::Statement->new(_trim_table \@table);
}

# convert a date of the form DD/MM/YY (assuming YY is in the 21st century) into a timestamp
sub _date2time
{
  my ($d, $m, $y) = split /\D+/, shift;
  return timegm 0, 0, 0, $d, $m-1, $y+100;   ## no critic (ProhibitMagicNumbers)
}

sub statements
{
  my ($self, $account) = @_;

  $self->login();
  $self->set_account($account) if defined $account;
  croak 'No account currently selected' if not defined $self->{_current_account};

  $self->_get('/servlet/com.aquariussecurity.accounts.servlet.CurrentAccountStatementEntryServlet');
  $self->{_mech}->content =~ m/name="statementPeriods"(.*?)<\/select>/gsi;
  croak 'Statement extraction parsing failed' if not defined $1;
  my $select = $1;
  my @dates = ($select =~ m/<option value="(.+?)"/gsi);
  my @statements;
  foreach my $date (@dates) {
    $date =~ m/(\S+)\s*-\s*(\S+)/gsi;
    push @statements, { description => $date,
			start => _date2time($1),
			end => _date2time($2)
		      };
  }
  $self->{_statements} = \@statements;
  return \@statements;
}

sub set_statement
{
  my ($self, $statement) = @_;

  croak 'No statement selected for set_statement()' if not defined $statement;
  $self->login;
  croak 'No account currently selected' if not defined $self->{_current_account};
  $self->statements if not defined $self->{_statements};

  TRY: while (1) {
    foreach my $s (@{$self->{_statements}}) {
      last TRY if $s->{description} eq $statement;
    }
    croak 'Invalid statement: '.$statement;
  }
  $self->_get('/servlet/com.aquariussecurity.accounts.servlet.CurrentAccountStatementEntryServlet');
  $self->{_mech}->select('statementPeriods', $statement);
  $self->_submit_form();
  return $self;
}

sub debits
{
  my ($self, $account) = @_;

  $self->login();
  $self->set_account($account) if defined $account;
  croak 'No account currently selected' if not defined $self->{_current_account};

  $self->_get('/AquariusSecurity/web/en/core_banking/current_account/direct_debits/frameset_view_direct_debits.html');
  $self->_get_frames();
  $self->_get('/servlet/com.aquariussecurity.orders.servlet.DirectDebitListEntryServlet');

  my $te = HTML::TableExtract->new(headers => ['Payable to', 'Reference is']);
  $te->parse(decode_utf8 $self->{_mech}->content);
  my $table = _trim_table([$te->first_table_found->rows]);
  my @debits;
  foreach my $row (@{$table}) {
    push @debits, Finance::Bank::Cahoot::DirectDebit->new($row);
  }
  while ($self->{_mech}->content =~ /origin=forward/) {
    $self->{_mech}->follow_link(url_regex => qr/origin=forward/);
    $self->_test_content_for_error;
    my $te = HTML::TableExtract->new(headers => ['Payable to', 'Reference is']);
    $te->parse(decode_utf8 $self->{_mech}->content);
    my $table = _trim_table([$te->first_table_found->rows]);
    foreach my $row (@{$table}) {
      push @debits, Finance::Bank::Cahoot::DirectDebit->new($row);
    }
  }
  return \@debits;
}

sub snapshot
{
  my ($self, $account) = @_;

  $self->login();
  $self->set_account($account) if defined $account;
  croak 'No account currently selected' if not defined $self->{_current_account};

  $self->_get('/servlet/com.aquariussecurity.accounts.servlet.CurrentAccountStatusServlet?origin=print');
  my $te = HTML::TableExtract->new(headers => ['Date', 'Transaction Details', 'Withdrawn', 'Paid In']);
  $te->parse($self->{_mech}->content);
  my @table = $te->first_table_found->rows;
  return Finance::Bank::Cahoot::Statement->new(_trim_table \@table);
}

sub accounts
{
  my ($self) = @_;
  $self->login();
  $self->_get('/AquariusSecurity/web/en/core_banking/personal_homepage/frameset_personal_homepage.html');
  $self->_get_frames;
  my $content = $self->{_mech}->content();
  my @account_details = ($content =~ m/(PersonalHomepageSelectionServlet.*?"go\s+to\s+.*?")/gsi);
  my @accounts;
  foreach my $account (@account_details) {
    $account =~ m/(available\s+balance|payment\s+this\s+month):.*?([\-0-9\.]+).*(current\s+balance|payment\s+this\s+month):.*?([\-0-9\.]+).*?productType=MTA&Index=(\d+).*?="go\s+to\s+(.*?)\s+(\d+)"/gsi;
    push @accounts, { name => _trim($6),
                      account => $7,
                      account_index => $5,
                      balance => $4,
                      available => $2 };
  }
  $self->{_accounts} = \@accounts;
  return \@accounts;
}

1;
__END__

=for stopwords online HTTPS login Login Connell Belka

=head1 NAME

Finance::Bank::Cahoot - Check your Cahoot bank accounts from Perl

=head1 DESCRIPTION

This module provides a rudimentary interface to the Cahoot online
banking system at C<https://www.cahoot.com/>. You will need
either C<Crypt::SSLeay> or C<IO::Socket::SSL> installed for HTTPS
support to work with WWW::Mechanize.

=head1 SYNOPSIS

  my $cahoot = Finance::Bank::Cahoot->new(credentials => 'Constant',
                                          credentials_options => {
                                             account => '12345678',
                                             password => 'verysecret',
					     place => 'London',
					     date => '01/01/1906',
					     username => 'dummy',
					     maiden => 'Smith' } );

  my $accounts = $cahoot->accounts;
  $cahoot->set_account($accounts->[0]->{account});
  my $snapshot = $cahoot->snapshot;
  foreach my $row (@$snapshot) {
    print join ',', @$row; print "\n";
  }

=head1 METHODS

=over 4 

=item B<new>

Create a new instance of a connection to the Cahoot server. 

C<new> can be called in two different ways. It can take a single parameter,
C<credentials>, which will accept an already created credentials object, of type 
C<Finance::Bank::Cahoot::CredentialsProvider::*>. Alternatively, it can take two
parameters, C<credentials> and C<credentials_options>. In this case 
C<credentials> is the name of a credentials class to create an instance of, and
C<credentials_options> is a hash of the options to pass-through to the
constructor of the chosen class.

If the second form of C<new> is being used, and the chosen class is I<not> one
of the ones supplied as standard then it will need to be C<required> first.

If any errors occur then C<new> will C<croak>.

  my $cahoot = Finance::Bank::Cahoot->new(credentials => 'Constant',
                                          credentials_options => {
                                             account => '12345678',
                                             password => 'verysecret',
					     place => 'London',
					     date => '01/01/1906',
					     username => 'dummy',
					     maiden => 'Smith' } );

  # Or create the credentials object ourselves
  my $credentials = Finance::Bank::Cahoot::CredentialsProvider::Constant->new(
     account => '12345678', password => 'verysecret', place => 'London',
     date => '01/01/1906', username => 'dummy', maiden => 'Smith' } );
  my $cahoot = Finance::Bank::Cahoot->new(credentials => $credentials);

=item B<login>

Login to the Cahoot server using the credentials supplied to C<new>. This method
is implicit for all data access methods, so typically does not need to be called
explicitly. The method takes no arguments and will only call one of memorable
place, date or mother's maiden name as expected by the Cahoot portal.

=item B<accounts>

Returns a list reference containing a summary of any accounts available from
the supplied credentials. If a login has yet to occur C<accounts> will
automatically do this.

  my $accounts = $cahoot->accounts;

Each item in the list is a hash reference that holds summary information for a
single account, and contains this data:

=over 4

=item B<name> - the text name of the account

=item B<account> - the account number

=item B<balance> - the current balance of the account

=item B<available> - the currently available funds (including any overdrafts)

=back


=item B<set_account>

Select an account for data retrieval using an 8-digit account number. If a login has
yet to occur or a list of accounts has yet to be retrieved, C<set_account> will
automatically do this and cache the results.

  my @accounts = $cahoot->accounts;
  $cahoot->set_account($accounts->[0]->{account});

  # Or without first loading a list of accounts
  $cahoot->set_account('12345678);

=item B<statements>

Returns a list reference containing a summary of all statements available for an
account. When called with the optional parameter containing an 8-digit
account number, C<statements> will automatically login (if required) and select
that account.

If no account has been selected and no account is supplied by the caller,
C<statements> will C<croak>.

Each item in the returned list is a hash reference that holds summary information
for a single statement, and contains this data:

=over 4

=item B<description> - a text description of the date of the statement, typically in the form C<DD/MM/YY - DD/MM/YY>

=item B<start> - the date of the start of the statement as a time as returned by the C<time> function.

=item B<end> - the date of the end of the statement as a time as returned by the C<time> function.

=back

=item B<set_statement>

Select a statement for data retrieval using a statement description previously
returned from C<statements>. The text description of the statement must be supplied
as a parameter to the method and an account must have been selected using
C<set_account>. If no account has been selected or no statement name is supplied
by the caller, C<statement> will C<croak>.

  $cahoot->set_account('12345678);
  my $statements = $cahoot->statements;
  $cahoot->set_statement($statements->[0]->{description});

=item B<debits>

Return a list of direct debits currently active on the account. An optional
account parameter may be supplied as an 8-digit account number. If no account
has previously been selected or no account number is supplied, C<debits> will
C<croak>. The return value is a reference to a list of
C<Finance::Bank::Cahoot::DirectDebit> objects. Each entry in the list is a
single direct debit.

  $cahoot->set_account('12345678');
  my $debits = $cahoot->debits;
  foreach my $debit (@$debits) {
    print $debit->payee, q{,},
          $debit->reference, q{,},
          $debit->amount || 0, q{,},
          $debit->date || 0, q{,},
          $debit->frequency || 0, qq{\n};
  }

=item B<snapshot>

Return a table of transactions from the account snapshot. An optional account
parameter may be supplied as an 8-digit account number. If no account has
previously been selected or no account number is supplied, C<snapshot>
will C<croak>. The return value is a reference to a list of list references.
Each entry in the top-level list is a row in the statement and the rows
are data from the account in the order date, description, amount withdrawn,
amount paid in.

  $cahoot->set_account('12345678');
  my $snapshot = $cahoot->snapshot;
  foreach my $row (@$snapshot) {
    print join ',', @$row; print "\n";
  }

=item B<statement>

Return a table of transactions from a selected statement. An optional account
parameter may be supplied as an 8-digit account number. If no account has
previously been selected or no account number is supplied, C<statement>
will C<croak>. The return value is a reference to a list of
C<Finance::Bank::Cahoot::Statement::Entry> objects. Each entry in list is a
row in the statement.

  $cahoot->set_account('12345678');
  my $statement = $cahoot->statement;
  foreach my $transaction (@$statement) {
    print $transaction->date, q{,},
          $transaction->details, q{,},
          $transaction->credit || 0, q{,},
          $transaction->debit || 0, q{,},
          $transaction->balance || 0, qq{\n};
  }

=back

=head1 WARNING

This warning is from Simon Cozens' C<Finance::Bank::LloydsTSB>, and seems
just as apt here.

This is code for B<online banking>, and that means B<your money>, and
that means B<BE CAREFUL>. You are encouraged, nay, expected, to audit
the source of this module yourself to reassure yourself that I am not
doing anything untoward with your banking data. This software is useful
to me, but is provided under B<NO GUARANTEE>, explicit or implied.

=head1 NOTES

This has only been tested on my own accounts. I imagine it should work on any
account types, but I can't guarantee this.

=head1 AUTHOR

Jon Connell <jon@figsandfudge.com>

=head1 LICENSE AND COPYRIGHT

This module borrows heavily from Finance::Bank::Natwest by Jody Belka.

Copyright 2008 by Jon Connell
Copyright 2003 by Jody Belka

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
