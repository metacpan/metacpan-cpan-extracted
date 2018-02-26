package Finance::Bank::Postbank_de::Account;
use 5.006;
use strict;
use warnings;
use Carp qw(croak);
use POSIX qw(strftime);
use base 'Class::Accessor';

use vars qw[ $VERSION %tags %totals %columns %safety_check ];

$VERSION = '0.48';

BEGIN {
  Finance::Bank::Postbank_de::Account->mk_accessors(qw( number balance balance_unavailable balance_prev transactions_future iban blz account_type name));
};

sub new {
  my $self = $_[0]->SUPER::new();
  my ($class,%args) = @_;

  my $num = delete $args{number} || delete $args{kontonummer};
  croak "'kontonummer' is '$args{kontonummer}' and 'number' is '$num'"
    if $args{kontonummer} and $args{kontonummer} ne $num;

  $self->number($num) if (defined $num);

  $self->name($args{name})
    if (exists $args{name});

  $self;
};

{ no warnings 'once';
*kontonummer = *number;
}

%safety_check = (
  name		=> 1,
  kontonummer	=> 1,
);

%tags = (
  #Girokonto => [qw(Name BLZ Kontonummer IBAN)],
  "gebuchte Ums\x{00E4}tze" => [qw(Name BLZ Kontonummer IBAN)],
  Tagesgeldkonto => [qw(Name BLZ Kontonummer IBAN)],
  Sparcard => [qw(Name BLZ Kontonummer  IBAN)],
  Sparkonto => [qw(Name BLZ Kontonummer  IBAN)],
  Kreditkarte => [qw(Name BLZ Kontonummer IBAN)],
);

%totals = (
  "gebuchte Ums\x{00E4}tze" => [
      [qr'^Aktueller Kontostand' => 'balance'],
      [qr'^Summe vorgemerkter Ums.tze' => 'transactions_future'],
      [qr'^Davon noch nicht verf.gbar' => 'balance_unavailable'],
  ],
  Sparcard => [[qr'Aktueller Kontostand' => 'balance'],],
  Sparkonto => [[qr'Aktueller Kontostand' => 'balance'],],
  Tagesgeldkonto => [[qr'Aktueller Kontostand' => 'balance'],],
);

%columns = (
  qr'Buchungstag'			=> 'tradedate',
  qr'Wertstellung'		=> 'valuedate',
  qr'Umsatzart'			=> 'type',
  qr'Buchungsdetails'		=> 'comment',
  qr'Auftraggeber'		=> 'sender',
  qr'Empf.nger'			=> 'receiver',
  qr"Betrag \((?:\x{20AC}|\x{80})\)"		=> 'amount',
  qr"Saldo \((?:\x{20AC}|\x{80})\)"		=> 'running_total',
);

sub parse_date {
  my ($self,$date) = @_;
  $date =~ /^(\d{2})\.(\d{2})\.(\d{4})$/
    or die "Unknown date format '$date'. A date must be in the format 'DD.MM.YYYY'\n";
  $3.$2.$1;
};

sub parse_amount {
  my ($self,$amount) = @_;
  # '¿ 5.314,05'
  die "String '$amount' does not look like a number"
    unless $amount =~ /^(-?)(?:\s*\x{20AC}\s*|\s*\x{80}\s*|\s*\x{A4}\s*)?([0-9]{1,3}(?:\.\d{3})*,\d{2})(?:\s*\x{20AC}|\s*\x{80})?$/;
  $amount = ($1||'') . $2;
  $amount =~ tr/.//d;
  $amount =~ s/,/./;
  $amount;
};

sub slurp_file {
  my ($self,$filename) = @_;
  local $/ = undef;
  open my $fh, "< $filename"
    or croak "Couldn't read from file '$filename' : $!";
  binmode $fh, ':encoding(CP-1252)';
  <$fh>;
};

sub parse_statement {
  my ($self,%args) = @_;

  # If $self is just a string, we want to make a new class out of us
  $self = $self->new
    unless ref $self;
  my $filename = $args{file};
  my $raw_statement = $args{content};
  if ($filename) {
    $raw_statement = $self->slurp_file($filename);
  } elsif (! defined $raw_statement) {
    croak "Need an account number if I have to retrieve the statement online"
      unless $args{number};
    croak "Need a password if I have to retrieve the statement online"
      unless exists $args{password};
    my $login = $args{login} || $args{number};

    require Finance::Bank::Postbank_de;
    return Finance::Bank::Postbank_de->new( login => $login, password => $args{password}, past_days => $args{past_days} )->get_account_statement;
  };

  croak "Don't know what to do with empty content"
    unless $raw_statement;

  my @lines = split /\r?\n/, $raw_statement;
  croak "No valid account statement: '$lines[0]'"
    unless $lines[0] =~ /^Umsatzauskunft - (.*)$/;
  shift @lines;

  my $account_type = $1;
  if( ! exists $tags{ $account_type }) {
    $account_type =~ s!([^\x00-\x7f])!sprintf '%08x', ord($1)!ge;
    croak "Unknown account type '$account_type' (" . (join ",",keys %tags) . ")"
      unless exists $tags{$account_type};
  };
  $self->account_type($account_type);

  # Name: PETRA PFIFFIG
  for my $tag (@{ $tags{ $self->account_type }||[] }) {
    $lines[0] =~ /^\Q$tag\E;(.*)$/
      or croak "Field '$tag' not found in account statement ($lines[0])";
    my $method = lc($tag);
    my $value = $1;

    # special check for special fields:
    croak "Wrong/mixed account $method: Got '$value', expected '" . $self->$method . "'"
      if (exists $safety_check{$method} and defined $self->$method and $self->$method ne $value);

    $self->$method($value);
    shift @lines;
  };

  my $sep = ";";
  if( $lines[0] =~ /([\t])/) {
    $sep = $1;
  };

  while ($lines[0] !~ /^\s*$/) {
    my $line = shift @lines;
    my ($method,$balance);
    for my $total (@{ $totals{ $self->account_type }||[] }) {
      my ($re,$possible_method) = @$total;
      if ($line =~ /$re;\s*(?:(?:(\S+)\s*(?:\x{20AC}|\x{80}))|(null))$/) {
        $method = $possible_method;
        $balance = $1 || $2;
        if ($balance =~ /^(-?[0-9.,]+)\s*$/) {
          $self->$method( ['????????',$self->parse_amount($balance)]);
        } elsif ('null' eq $balance) {
          $self->$method( ['????????',$self->parse_amount("0,00")]);
        } else {
          die "Invalid number '$balance' found for $method in '$line'";
        };
      };
    };
    if (! $method) {
        $account_type =~ s!([^\x00-\x7f])!sprintf '%08x', ord($1)!ge;
        $line =~ s!([^\x00-\x7f])!sprintf '%08x', ord($1)!ge;
        croak "No summary found in account '$account_type' statement ($line)";
    };
  };

  $lines[0] =~ m!^\s*$!
    or croak "Expected an empty line after the account balances, got '$lines[0]'";
  shift @lines;

  # Now parse the lines for each cashflow :
  $lines[0] =~ /^"Buchungstag"${sep}"Wertstellung"${sep}"Umsatzart"/
    or croak "Couldn't find start of transactions ($lines[0])";

  my (@fields);
  COLUMN:
  for my $col (split /$sep/, $lines[0]) {
    for my $target (keys %columns) {
      if ($col =~ m!^["']?$target["']?$!) {
        push @fields, $columns{$target};
        next COLUMN;
      };
    };
    die "Unknown column '$col' in '$lines[0]'";
  };
  shift @lines;

  my (%convert) = (
    tradedate => \&parse_date,
    valuedate => \&parse_date,
    amount => \&parse_amount,
    running_total => \&parse_amount,
  );

  my @transactions;
  my $line;
  for $line (@lines) {
    next if $line =~ /^\s*$/;
    my (@row) = split /$sep/, $line;
    scalar @row == scalar @fields
      or die "Malformed cashflow ($line): Expected ".scalar(@fields)." entries, got ".scalar(@row);

    for (@row) {
      $_ = $1
          if /^\s*["']\s*(.*?)\s*["']\s*$/;
    };

    my (%rec);
    @rec{@fields} = @row;
    for (keys %convert) {
      $rec{$_} = $convert{$_}->($self,$rec{$_});
    };

    push @transactions, \%rec;
  };

  # Filter the transactions
  $self->{transactions} = \@transactions;

  $self
};

sub transactions {
  my ($self,%args) = @_;

  my ($start_date,$end_date);
  if (exists $args{on}) {

    croak "Options 'since'+'upto' and 'on' are incompatible"
      if (exists $args{since} and exists $args{upto});
    croak "Options 'since' and 'on' are incompatible"
      if (exists $args{since});
    croak "Options 'upto' and 'on' are incompatible"
      if (exists $args{upto});
    $args{on} = strftime('%Y%m%d',localtime())
      if ($args{on} eq 'today');
    $args{on} =~ /^\d{8}$/ or croak "Argument {on => '$args{on}'} dosen't look like a date to me.";

    $start_date = $args{on} -1;
    $end_date = $args{on};
  } else {
    $start_date = $args{since} || "00000000";
    $end_date = $args{upto} || "99999999";
    $start_date =~ /^\d{8}$/ or croak "Argument {since => '$start_date'} dosen't look like a date to me.";
    $end_date =~ /^\d{8}$/ or croak "Argument {upto => '$end_date'} dosen't look like a date to me.";
    $start_date < $end_date or croak "The 'since' argument must be less than the 'upto' argument";
  };

  # Filter the transactions
  grep { $_->{tradedate} > $start_date and $_->{tradedate} <= $end_date } @{$self->{transactions}};
};

sub value_dates {
  my ($self) = @_;
  my %dates;
  $dates{$_->{valuedate}} = 1 for $self->transactions();
  sort keys %dates;
};

sub trade_dates {
  my ($self) = @_;
  my %dates;
  $dates{$_->{tradedate}} = 1 for $self->transactions();
  sort keys %dates;
};

1;
__END__

=encoding ISO8859-1

=head1 NAME

Finance::Bank::Postbank_de::Account - Postbank bank account class

=head1 SYNOPSIS

=for example begin

  use strict;
  require Crypt::SSLeay; # It's a prerequisite
  use Finance::Bank::Postbank_de::Account;
  my $statement = Finance::Bank::Postbank_de::Account->parse_statement(
                number => '9999999999',
                password => '11111',
              );
  # Retrieve account data :
  print "Balance : ",$statement->balance->[1]," EUR\n";

  # Output CSV for the transactions
  for my $row ($statement->transactions) {
    print join( ";", map { $row->{$_} } (qw( tradedate valuedate type comment receiver sender amount ))),"\n";
  };

=for example end

=for example_testing
  isa_ok($statement,"Finance::Bank::Postbank_de::Account");
  my $expected = <<EOX;
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
EOX
  for ($::_STDOUT_,$expected) {
    s!\r\n!!gsm;
    # Strip out all date references ...
    s/^\d{8};\d{8};//gm;
    s![\x80-\xff]!.!gsm;
  };
  is_deeply([split /\n/, $::_STDOUT_],[split /\n/, $expected],"Retrieved the correct data")
    or do {
      diag "--- Expected";
      diag $expected;
      diag "--- Got";
      diag $::_STDOUT_;
    };

=head1 DESCRIPTION

This module provides a rudimentary interface to the Postbank online banking system at
https://banking.postbank.de/. You will need either Crypt::SSLeay or IO::Socket::SSL
installed for HTTPS support to work with LWP.

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

=item number => '9999999999'

This is the number of the account. If you don't know it (for example, you
are reading in an account statement from disk), leave it undef.

=back

=head2 $account->parse_statement %ARGS

Parses an account statement and returns it as a hash reference. The account statement
can be passed in via two named parameters. If no parameter is given, the current statement
is fetched via the website through a call to C<get_account_statement> (is this so?).

Parameters :

=over 4

=item file => $filename

Parses the file C<$filename> instead of downloading data from the web.

=item content => $string

Parses the content of C<$string>  instead of downloading data from the web.

=back

=head2 $account->iban

Returns the IBAN for the account as a string. Later, a move to L<Business::IBAN> is
planned. The IBAN is a unique identifier for every account, that identifies the country,
bank and account with that bank.

=head2 $account->transactions %ARGS

Delivers you all transactions within a statement. The transactions may be filtered
by date by specifying the parameters 'since', 'upto' or 'on'. The values are, as always,
8-digit strings denoting YYYYMMDD dates.

Parameters :

=over 4

=item since => $date

Removes all transactions that happened on or before $date. $date must
be in the format YYYYMMDD. If the line is missing, C<since =E<gt> '00000000'>
is assumed.

=item upto => $date

Removes all transactions that happened after $date. $date must
be in the format YYYYMMDD. If the line is missing, C<upto =E<gt> '99999999'>
is assumed.

=item on => $date

Removes all transactions that happened on a date that is not C<eq> to $date. $date must
be in the format YYYYMMDD. $date may also be the special string 'today', which will
be converted to a YYYYMMDD string corresponding to todays date.

=back

=head2 $account->value_dates

C<value_dates> is a convenience method that returns all value dates on the account statement.

=cut

=head2 $account->trade_dates

C<trade_dates> is a convenience method that returns all trade dates on the account statement.

=cut

=head2 Converting a daily download to a sequence

=for example begin

  #!/usr/bin/perl -w
  use strict;

  use Finance::Bank::Postbank_de::Account;
  use Tie::File;
  use List::Sliding::Changes qw(find_new_elements);
  use FindBin;
  use MIME::Lite;

  my $filename = "$FindBin::Bin/statement.txt";
  tie my @statement, 'Tie::File', $filename
    or die "Couldn't tie to '$filename' : $!";

  my @transactions;

  # See what has happened since we last polled
  my $retrieved_statement = Finance::Bank::Postbank_de::Account->parse_statement(
                         number => '9999999999',
                         password => '11111',
                );

  # Output CSV for the transactions
  for my $row (reverse @{$retrieved_statement->transactions()}) {
    push @transactions, join( ";", map { $row->{$_} } (qw( tradedate valuedate type comment receiver sender amount )));
  };

  # Find out what we did not already communicate
  my (@new) = find_new_elements(\@statement,\@transactions);
  if (@new) {
    my ($body) = "<html><body><table>";
    my ($date,$balance) = @{$retrieved_statement->balance};
    $body .= "<b>Balance ($date) :</b> $balance<br>";
    $body .= "<tr><th>";
    $body .= join( "</th><th>", qw( tradedate valuedate type comment receiver sender amount )). "</th></tr>";
    for my $line (@{[@new]}) {
      $line =~ s!;!</td><td>!g;
      $body .= "<tr><td>$line</td></tr>\n";
    };
    $body .= "</body></html>";
    MIME::Lite->new(
                    From     =>'update.pl',
                    To       =>'you',
                    Subject  =>"Account update $date",
                    Type     =>'text/html',
                    Encoding =>'base64',
                    Data     => $body,
                    )->send;
  };

  # And update our log with what we have seen
  push @statement, @new;

=for example end

=head1 AUTHOR

Max Maischein, E<lt>corion@cpan.orgE<gt>

=head1 SEE ALSO

L<perl>, L<Finance::Bank::Postbank_de>.
