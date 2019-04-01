package Finance::Bank::Postbank_de;

use 5.006; # we use lexical filehandles now
use strict;
use warnings;
use Carp;
use Moo 2;

use Time::Local;
use POSIX 'strftime';

use Finance::Bank::Postbank_de::Account;
use Finance::Bank::Postbank_de::APIv1;
use Encode qw(decode);
use Mozilla::CA;

#use IO::Socket::SSL qw(SSL_VERIFY_PEER SSL_VERIFY_NONE);

our $VERSION = '0.57';

has 'login' => (
    is => 'ro',
);

has 'password' => (
    is => 'ro',
);

has 'urls' => (
    is => 'ro',
    default => sub { {} },
);

has 'logger' => (
    is => 'ro',
    default => sub { {} },
);

has 'past_days' => (
    is => 'ro',
    default => sub { {} },
);

has 'api' => (
    is => 'rw',
    default => sub {
        my $api = Finance::Bank::Postbank_de::APIv1->new();
        $api->configure_ua();
        $api
    },
);

has 'session' => (
    is => 'rw',
);

has '_account_numbers' => (
    is => 'rw',
);

our %functions;
BEGIN {
  %functions = (
    quit		=> [ text_regex => qr'\bBanking\s+beenden\b' ],
    accountstatement	=> [ text_regex => qr'\bUms.*?tze\b' ],
  );
};

around BUILDARGS => sub {
    my ($orig,$class,%args) = @_;

    croak "Login/Account number must be specified"
      unless $args{login};
    croak "Password/PIN must be specified"
      unless $args{password};
    if( exists $args{ status }) {
        $args{ logger } = delete $args{ status };
    };

    $orig->($class, %args);
};

sub log { $_[0]->logger->(@_); };
sub log_httpresult { $_[0]->log("HTTP Code",$_[0]->agent->status,$_[0]->agent->res->headers->as_string . $_[0]->agent->content) };

sub new_session {
  my ($self) = @_;

  $self->close_session()
    if ($self->session);
  my $pb;
  my $ok = eval {
    $pb = $self->api->login( $self->login, $self->password );
    1
  };
  if( ! $ok ) {
    #warn sprintf "Got HTTP error %d, message %s", $self->api->ua->status, $self->api->ua->message;
    #croak $@;
  } else {
    $self->session( $pb );
  }
};

sub is_security_advice {
  my ($self) = @_;
  #$self->agent->content() =~ /\bZum\s+Finanzstatus\b/;
};

sub is_nutzungshinweis {
  my ($self) = @_;
  #$self->agent->content() =~ /\bAus Sicherheitsgr.*?nden haben wir einige\b/;
};


sub skip_security_advice {
  my ($self) = @_;
  #$self->log('Skipping security advice page');
  #$self->agent->follow_link(text_regex => qr/\bZum\s+Finanzstatus\b/);
  # $self->agent->content() =~ /Sicherheitshinweis/;
};

sub skip_nutzungshinweis {
  my ($self) = @_;
  #$self->log('Skipping nutzungshinweis page');
  #$self->agent->follow_link(text_regex => qr/\bZur\s+Konten.bersicht\b/);
  # $self->agent->content() =~ /Sicherheitshinweis/;
};

sub error_page {
  # Check if an error page is shown
  my ($self) = @_;
  $self->api->ua->status != 200
  #return unless $self->agent;
  #
  #$self->agent->content =~ m!<p\s+class="form-error">!sm
  #    or
  #$self->agent->content =~ m!<p\s+class="field-error">!sm
  #    or $self->maintenance;
};

sub error_message {
  my ($self) = @_;
  #return unless $self->agent;
  #die "No error condition detected in:\n" . $self->agent->content
  #  unless $self->error_page;
  #if(
  #$self->agent->content =~ m!<p\s+class="form-error">\s*<strong>\s*(.*?)\s*</strong>\s*</p>!sm
  #  or
  #$self->agent->content =~ m!<p\s+class="field-error">\s*(.*?)\s*</p>!sm
  #  ) { return $1 }
  #  #or croak "No error message found in:\n" . $self->agent->content;
  return ''
};

sub maintenance {
  my ($self) = @_;
  #return unless $self->agent;
  ##$self->error_page and
  #$self->agent->content =~ m!Sehr geehrter <span lang="en">Online-Banking</span>\s+Nutzer,\s+wegen einer hohen Auslastung kommt es derzeit im Online-Banking zu\s*l&auml;ngeren Wartezeiten.!sm
  #or $self->agent->content =~ m!&nbsp;Wartung\b!
  #or $self->agent->content =~ m!<p class="important">\s*<strong>\s*Diese Funktion steht auf Grund einer technischen St.*?rung derzeit leider nicht zur Verf.*?gung.*?</strong>\s*</p>!sm # Testumgebung...
  ()
};

sub access_denied {
  my ($self) = @_;
  $self->api->ua->status == 401
  #if ($self->error_page) {
  #  my $message = $self->error_message;
  #
  #  return (
  #       $message =~ m!^Die Kontonummer ist nicht für das Internet Online-Banking freigeschaltet. Bitte verwenden Sie zur Freischaltung den Link "Online-Banking freischalten"\.<br />\s*$!sm
  #    or $message =~ m!^Sie haben zu viele Zeichen in das Feld eingegeben.<br />\s*$!sm
  #    or $message =~ m!^Die eingegebene Postbank Girokontonummer ist zu lang. Bitte überprüfen Sie Ihre Eingabe.$!sm
  #    or $message =~ m!^Die Anmeldung ist fehlgeschlagen. Bitte vergewissern Sie sich der Richtigkeit Ihrer Eingaben und f.*?hren Sie den Anmeldevorgang erneut durch.\s*$!sm
  #  )
  #} else {
  #  return;
  #};
};

sub session_timed_out {
  my ($self) = @_;
  #$self->agent->content =~ /Die Sitzungsdaten sind ung&uuml;ltig, bitte f&uuml;hren Sie einen erneuten Login durch.\s+\(27000\)/;
  ()
};

sub select_function {
    my ($self,$function) = @_;
    if (! $self->session) {
        $self->new_session;
    };
    croak "Unknown account function '$function'"
        unless exists $functions{$function};
    my $method = $functions{ $function };

    my $res = $self->session->navigate($method);
    $res    
};

sub close_session {
    my ($self) = @_;
    $self->session(undef);
    $self->api(undef);
    1
};

sub finanzstatus {
    my( $self ) = @_;
    $self->new_session unless $self->session;
    my $finanzstatus = $self->session->navigate(
        class => 'Finance::Bank::Postbank_de::APIv1::Finanzstatus',
        path => ['banking_v1' => 'financialstatus']
    );
}

sub _build_account_numbers {
  my ($self,%args) = @_;
  
  my $finanzstatus = $self->finanzstatus;
  (my $bp) = $finanzstatus->get_businesspartners; # always take the first...
  my %numbers;
  # this currently includes the credit card numbers ...
  for my $acc ( $bp->get_accounts() ) {
      $numbers{ $acc->iban } = $acc if (!$acc->is_depot and !$acc->is_mortgage);
  };

  return $self->_account_numbers( \%numbers );
}

sub account_numbers {
  my ($self,%args) = @_;

  my $n = $self->_account_numbers || $self->_build_account_numbers;
  
  sort keys %{ $n };
};

sub get_account_statement {
  my ($self,%args) = @_;

  #my $past_days = $args{past_days} || $self->{past_days};
  #if($past_days) {
  #  my ($day, $month, $year) = split/\./, $agent->current_form->value('umsatzanzeigeGiro:salesForm:umsatzFilterOptionenAufklappbarSuchfeldPanel:accordion:vonBisDatum:datumForm:bisGruppe:bisDatum');
  #  my $end_epoch = timegm(0, 0, 0, $day, $month-1, $year);
  #  my $from_date = strftime '%d.%m.%Y', localtime($end_epoch-($past_days-1)*60*60*24);
  #  $agent->current_form->value('umsatzanzeigeGiro:salesForm:umsatzFilterOptionenAufklappbarSuchfeldPanel:accordion:vonBisDatum:datumForm:vonGruppe:vonDatum' => $from_date);
  #};

  my $accounts = $self->_account_numbers || $self->_build_account_numbers;

  if( ! $args{ account_number }) {
    # Hopefully we only got one account (?!)
    ($args{ account_number }) = keys %$accounts;
  };

  my $account = $accounts->{ $args{ account_number }};

  #if (exists $args{account_number}) {
  #  $self->log("Getting account statement for $args{account_number}");
  #  # Load the account numbers if not already loaded
  #  $self->account_numbers;
  #  if(! exists $self->{account_numbers}->{$args{account_number}}) {
  #      croak "Unknown account number '$args{account_number}'";
  #  };
  #  my $index = $self->{account_numbers}->{$args{account_number}};
  #  $agent->current_form->param( 'selectForm:kontoauswahl' => $index );
  #} else {
  #  my @accounts = $agent->current_form->value('selectForm:kontoauswahl');
  #  $self->log("Getting account statement via default (@accounts)");
  #};
  my $content = $account->transactions_csv();
  if( $args{ file }) {
      open my $fh, '>', $args{ file }
          or croak "Couldn't create '$args{ file }': $!";
      binmode $fh, ':encoding(UTF-8)';
      print $fh $content;
  };
  #if ($agent->status == 200) {
    my $result = $content;
    # Result is in UTF-8
    return Finance::Bank::Postbank_de::Account->parse_statement(content => $result);
};

sub unread_messages {
    my( $self )= @_;
    $self->finanzstatus->available_messages
}

1;
__END__

=encoding ISO8859-1

=head1 NAME

Finance::Bank::Postbank_de - Check your Postbank.de bank account from Perl

=head1 SYNOPSIS

=for example begin

  use strict;
  require Crypt::SSLeay; # It's a prerequisite
  use Finance::Bank::Postbank_de;
  my $account = Finance::Bank::Postbank_de->new(
                login => 'Petra.Pfiffig',
                password => '123456789',
                status => sub { shift;
                                print join(" ", @_),"\n"
                                  if ($_[0] eq "HTTP Code")
                                      and ($_[1] != 200)
                                  or ($_[0] ne "HTTP Code");

                              },
              );
  # Retrieve account data :
  my $retrieved_statement = $account->get_account_statement();
  print "Statement date : ",$retrieved_statement->balance->[0],"\n";
  print "Balance : ",$retrieved_statement->balance->[1]," EUR\n";

  # Output CSV for the transactions
  for my $row ($retrieved_statement->transactions) {
    print join( ";", map { $row->{$_} } (qw( tradedate valuedate type comment receiver sender amount ))),"\n";
  };

  $account->close_session;
  # See Finance::Bank::Postbank_de::Account for
  # a simpler example

=for example end

=for example_testing
  isa_ok($account,"Finance::Bank::Postbank_de");
  isa_ok($retrieved_statement,"Finance::Bank::Postbank_de::Account");
  $::_STDOUT_ =~ s!^Statement date : \d{8}\n!!m;
  $::_STDOUT_ =~ s!^Skipping security advice page\n!!m;
  my $expected = <<EOX;
New Finance::Bank::Postbank_de created
Connecting to https://banking.postbank.de/app/welcome.do
Activating (?-xism:^Kontoums.*?tze\$)
Getting account statement via default (9999999999)
Downloading text version
Statement date : ????????
Balance : 5314.05 EUR
.berweisung;111111/1000000000/37050198 FINANZKASSE 3991234 STEUERNUMMER 00703434;Finanzkasse K.ln-S.d;PETRA PFIFFIG;-328.75
.berweisung;111111/3299999999/20010020 .BERTRAG AUF SPARCARD 3299999999;Petra Pfiffig;PETRA PFIFFIG;-228.61
Gutschrift;BEZ.GE PERS.NR. 70600170/01 ARBEITGEBER U. CO;PETRA PFIFFIG;Petra Pfiffig;2780.70
.berweisung;DA 1000001;Verlagshaus Scribere GmbH;PETRA PFIFFIG;-31.50
Scheckeinreichung;EINGANG VORBEHALTEN GUTBUCHUNG 12345;PETRA PFIFFIG;Ein Fremder;1830.00
Lastschrift;MIETE 600+250 EUR OBJ22/328 SCHULSTR.7, 12345 MEINHEIM;Eigenheim KG;PETRA PFIFFIG;-850.00
Inh. Scheck;;2000123456789;PETRA PFIFFIG;-75.00
Lastschrift;TEILNEHMERNR 1234567 RUNDFUNK 0103-1203;GEZ;PETRA PFIFFIG;-84.75
Lastschrift;RECHNUNG 03121999;Telefon AG Köln;PETRA PFIFFIG;-125.80
Lastschrift;STROMKOSTEN KD.NR.1462347 JAHRESABRECHNUNG;Stadtwerke Musterstadt;PETRA PFIFFIG;-580.06
Gutschrift;KINDERGELD KINDERGELD-NR. 1462347;PETRA PFIFFIG;Arbeitsamt Bonn;154.00
Closing session
Activating (?-xism:^Banking beenden\$)
EOX
  for ($::_STDOUT_,$expected) {
    s!\r\n!\n!gsm;
    s![\x80-\xff]!.!gsm;
    # Strip out all date references ...
    s/^\d{8};\d{8};//gm;
  };
  my @got = split /\n/, $::_STDOUT_;
  my @expected = split /\n/, $expected;
  is_deeply(\@got,\@expected,'Retrieving an account statement works')
    or do {
      diag "--- Got";
      diag $::_STDOUT_;
      diag "--- Expected";
      diag $expected;
    };

=head1 DESCRIPTION

This module provides a rudimentary interface to the Postbank online banking system at
https://meine.postbank.de/.

The interface was cooked up by me without taking a look at the other Finance::Bank
modules. If you have any proposals for a change, they are welcome !

=head1 WARNING

This is code for online banking, and that means your money, and that means BE CAREFUL. You are encouraged, nay, expected, to audit the source of this module yourself to reassure yourself that I am not doing anything untoward with your banking data. This software is useful to me, but is provided under NO GUARANTEE, explicit or implied.

=head1 WARNUNG

Dieser Code beschaeftigt sich mit Online Banking, das heisst, hier geht es um Dein Geld und das bedeutet SEI VORSICHTIG ! Ich gehe
davon aus, dass Du den Quellcode persoenlich anschaust, um Dich zu vergewissern, dass ich nichts unrechtes mit Deinen Bankdaten
anfange. Diese Software finde ich persoenlich nuetzlich, aber ich stelle sie OHNE JEDE GARANTIE zur Verfuegung, weder eine
ausdrueckliche noch eine implizierte Garantie.

=head1 METHODS

=head2 new

Creates a new object. It takes three named parameters :

=over 4

=item login => 'Petra.Pfiffig'

This is your Postbank ID account name.

=item password => '123456789'

This is your PIN / password.

=item status => sub {}

This is an optional
parameter where you can specify a callback that will receive the messages the object
Finance::Bank::Postbank produces per session.

=back

=head2 $account->new_session

Closes the current session and logs in to the website using
the credentials given at construction time.

=head2 $account->close_session

Closes the session and invalidates it on the server.

=head2 $account->agent

Returns the C<WWW::Mechanize> object. You can retrieve the
content of the current page from there.

=head2 C<< $session->account_numbers >>

Returns the account numbers. Only numeric account numbers
are returned - the credit card account numbers are not
returned.

=head2 $account->select_function STRING

Selects a function. The currently supported functions are

	accountstatement
	quit

=head2 $account->get_account_statement

Navigates to the print version of the account statement. The content can currently
be retrieved from the agent, but this will most likely change, as the print version
of the account statement is not a navigable page. The result of the function
is either undef or a Finance::Bank::Postbank_de::Account object.

C<past_days> - Number of days in the past to request the statement for
The default is 10.

=head2 $account->unread_messages

Returns the number of unread messages. There is no way
to retrieve the messages themselves yet.

=head2 session_timed_out

Returns true if our banking session timed out.

=head2 maintenance

Returns true if the banking interface is currently unavailable due to maintenance.

=head1 AUTHOR

Max Maischein, E<lt>corion@cpan.orgE<gt>

=head1 SEE ALSO

L<perl>, L<WWW::Mechanize>.

=head1 REPOSITORY

The public repository of this module is
L<https://github.com/Corion/Finance-Bank-Postbank_de>.

=head1 SUPPORT

The public support forum of this module is
L<https://perlmonks.org/>.

=head1 BUG TRACKER

Please report bugs in this module via the RT CPAN bug queue at
L<https://rt.cpan.org/Public/Dist/Display.html?Name=Finance-Bank-Postbank_de>
or via mail to L<finance-bank-postbank_de-Bugs@rt.cpan.org>.

=head1 COPYRIGHT (c)

Copyright 2003-2019 by Max Maischein C<corion@cpan.org>.

=head1 LICENSE

This module is released under the same terms as Perl itself.

=cut
