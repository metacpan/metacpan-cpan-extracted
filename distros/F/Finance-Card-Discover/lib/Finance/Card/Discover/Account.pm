package Finance::Card::Discover::Account;

use strict;
use warnings;

use Carp qw(croak);
use DateTime::Tiny;
use Object::Tiny qw(
    card credit expiration id nickname number type
);

our $XML_PARSER;

sub new {
    my ($class, $data, $num, %params) = @_;

    my ($year, $month) = split '/', $data->{"expiry${num}"}, 2;
    $year += 2000 if 2000 > $year;
    my $expiration = DateTime::Tiny->new(year => $year, month => $month);

    return bless {
        card       => $params{card},
        credit     => $data->{"AccountOpenToBuy${num}"},
        expiration => $expiration,
        id         => $data->{"cardsubid${num}"},
        nickname   => $data->{"nickname$num"},
        number     => $data->{"pan${num}"},
        type       => $data->{"cardtype${num}"},
    }, $class;
}

sub balance {
    my $dom = $_[0]->_ofx_request;
    return unless $dom;
    $dom->findvalue('//CCSTMTTRNRS/CCSTMTRS/LEDGERBAL/BALAMT');
}

sub transactions {
    my ($self, %params) = @_;

    for my $param (qw(start end)) {
        next unless exists $params{$param};
        my $type = ref $params{$param} || '';
        croak "'$param' must be a DateTime or DateTime::Tiny, not $type"
            unless $type =~ m[^DateTime(?:::Tiny)$];
    }

    my $dom = $self->_ofx_request(%params, transactions => 1);
    return unless $dom;

    require Finance::Card::Discover::Account::Transaction;

    my @transactions;
    for my $node ($dom->findnodes('//BANKTRANLIST/STMTTRN')) {
        my ($type, $date, $amount, $id, $name) =  map {
            $node->findvalue($_)
        } qw(TRNTYPE DTPOSTED TRNAMT FITID NAME);
        my ($year, $month, $day) = unpack 'A4A2A2', $date;
        $date = DateTime::Tiny->new(year=>$year, month=>$month, day=>$day);
        my $transaction = Finance::Card::Discover::Account::Transaction->new(
            type   => lc $type,
            date   => $date,
            amount => $amount,
            id     => $id,
            name   => $name,
        );
        push @transactions, $transaction;
    }

    return @transactions;
}

sub _ofx_request {
    my ($self, %params) = @_;

    my $dt = _dt_to_ofx(DateTime::Tiny->now);

    my ($trans, $start, $end);
    if ($trans = $params{transactions}) {
        ($start, $end) = @params{qw(start end)};
        $_ &&= _dt_to_ofx($_) for ($start, $end);
    }

    my $xml = <<"    __EOF__";
<?xml version="1.0"?>
<?OFX OFXHEADER="200" VERSION="211" SECURITY="NONE" OLDFILEUID="NONE"
  NEWFILEUID="NONE"?>
<OFX>
  <SIGNONMSGSRQV1>
    <SONRQ>
      <DTCLIENT>$dt</DTCLIENT>
      <USERID>@{[ $self->card->{username } ]}</USERID>
      <USERPASS>@{[ $self->card->{password} ]}</USERPASS>
      <LANGUAGE>ENG</LANGUAGE>
      <FI><ORG>Discover Financial Services</ORG><FID>7101</FID></FI>
      <APPID>QWIN</APPID><APPVER>1800</APPVER>
    </SONRQ>
  </SIGNONMSGSRQV1>
  <CREDITCARDMSGSRQV1>
    <CCSTMTTRNRQ>
      <TRNUID>${$}_$dt</TRNUID>
      <CCSTMTRQ>
        <CCACCTFROM><ACCTID>@{[ $self->number ]}</ACCTID></CCACCTFROM>
        <INCTRAN>
          @{[ $start ? "<DTSTART>$start</DTSTART>" : '' ]}
          @{[ $end ? "<DTEND>$end</DTEND>" : '' ]}
          <INCLUDE>@{[ $trans ? 'Y' : 'N' ]}</INCLUDE>
        </INCTRAN>
      </CCSTMTRQ>
    </CCSTMTTRNRQ>
  </CREDITCARDMSGSRQV1>
</OFX>
    __EOF__

    my $ua = $self->card->ua;
    my $uri = URI->new('https://ofx.discovercard.com/');
    my $res = $self->card->{response} = $ua->post(
        $uri,
        if_ssl_cert_subject => "/CN=(?i)\Q@{[$uri->host]}\E\$",
        content_type        => 'application/x-ofx',
        content             => $xml,
    );
    return unless $res->is_success;

    require XML::LibXML;
    $XML_PARSER ||= XML::LibXML->new;
    my $dom = eval {
        $XML_PARSER->parse_string($res->decoded_content);
    } or croak "Failed to parse response XML: $@";
    return $dom;
}

sub _dt_to_ofx {
    my ($dt) = @_;
    sprintf '%d%02d%02d%02d%02d%02d.000', $dt->year, $dt->month,
        $dt->day, $dt->hour, $dt->minute, $dt->second;
}

sub profile {
    my ($self) = @_;

    my $data = $self->card->_request(
        cardsubid   => $self->id,
        cardtype    => $self->type,
        msgnumber   => 0,
        profilename => 'billing',
        request     => 'getprofile',
    );
    return unless $data;

    require Finance::Card::Discover::Account::Profile;
    return Finance::Card::Discover::Account::Profile->new(
        $data, account => $self
    );
}

sub soan {
    my ($self) = @_;

    my $data = $self->card->_request(
        cardsubid  => $self->id,
        cardtype   => $self->type,
        clienttype => 'thin',
        cpntype    => 'MA',  # ?
        latched    => 'Y',   # ?
        msgnumber  => 2,
        request    => 'ocode',

        # TODO: test to see if this setting alters the expiration from the
        # default value. Currently, a user must call or send a message to
        # DiscoverCard to cancel a SOAN.
        validfor   => undef,
    );
    return unless $data;

    require Finance::Card::Discover::Account::SOAN;
    return Finance::Card::Discover::Account::SOAN->new(
        $data, account => $self
    );
}

sub soan_transactions {
    my ($self) = @_;

    my $data = $self->card->_request(
        cardtype  => $self->type,
        cardsubid => $self->id,
        msgnumber => 1,
        request   => 'ocodereview',

        # These might be useful.
        maxtrans => undef,
        fromdate => undef,
        todate   => undef,
    );
    return unless $data and $data->{Total};

    require Finance::Card::Discover::Account::SOAN::Transaction;
    return map {
        Finance::Card::Discover::Account::SOAN::Transaction->new(
            $data, $_, soan => $self
        );
    } (1 .. $data->{Total});
}


1;

__END__

=head1 NAME

Finance::Card::Discover::Account

=head1 ACCESSORS

=over

=item * card

The associated L<Finance::Card::Discover::Card> object.

=item * credit

The remaining credit for the account.

=item * expiration

The expiration date of the account, as a L<DateTime::Tiny> object.

=item * id

=item * nickname

=item * number

The account number.

=item * type

=back

=head1 METHODS

=head2 balance

    $balance = $account->balance()

Requests and returns the balance for the account.

=head2 profile

    $profile = $account->profile()

Requests profile data for the account and returns
a L<Finance::Card::Discover::Account::Profile> object.

=head2 soan

    $soan = $account->soan()

Requests a new Secure Online Account Number and returns
a L<Finance::Card::Discover::Account::SOAN> object.

=head2 soan_transactions

    @soan_transactions = $account->soan_transactions()

Requests the last 50 transactions made with SOANs and returns a list of
L<Finance::Card::Discover::Account::SOAN::Transaction> objects.

=head2 transactions

    @transactions = $account->transactions()
    @transactions = $account->transactions(
        start => $state_date_time,
        end   => $end_date_time,
    )

Requests a list of credit card transactions and returns the corresponding
L<Finance::Card::Discover::Account::Transaction> objects. Given no
arguments, the latest transactions are returned. The optional B<start> and
B<end> arguments requests only transactions within that time range and
should be L<DateTime> or L<DateTime::Tiny> objects.

Notes:

=over

=item * Each request returns about 500 transactions when a B<start> argument
is given and 200 transactions otherwise, so multiple calls with the
appropriate B<start> and B<end> arguments may be required to pull all
desired transactions.

=item * Several transactions may be related to each other, where additional
transactions are added as notes to the original transaction. These
informational transactions all have an amount of B<-0> and share the same
date and id prefix as the original transaction.

=back

=cut
