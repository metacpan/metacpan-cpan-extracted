package Finance::Tiller2QIF::ReadCSV;
# ABSTRACT: Read and parse Tiller CSV export files
$Finance::Tiller2QIF::ReadCSV::VERSION = '1.06';
=head1 DESCRIPTION

Ingests Tiller CSV exports into a SQLite database.

=head1 FUNCTIONS

=head2 Ingest

  Finance::Tiller2QIF::ReadCSV::Ingest( $csv_file, $db_path );

Parse a Tiller CSV export and insert rows into the SQLite database. Handles multiple number formats (US, European, with currency symbols). Dates are normalized to YYYY-MM-DD format. Missing Transaction IDs cause the row to be skipped.

=head1 AUTHOR

John Karr E<lt>brainbuz@cpan.orgE<gt>

=head1 LICENSE

GPL version 3 or later.

=cut

use v5.34;

use Path::Tiny;
use Text::CSV;
use DBI;
use utf8;
use warnings FATAL => 'utf8';
use feature qw/signatures postderef/;
use DateTime::Format::Flexible;
use Finance::Tiller2QIF::Util qw( vPrint );

# Enable experimental try/catch for Perl 5.32, suppressing warnings
no warnings 'experimental::try';
use feature 'try';

sub _normalize_amount ($raw) {
  my $amount = $raw;
  $amount =~ s/[£€¥₹\$]//g;
  $amount =~ s/\s//g;
  return $amount unless length $amount;

  my $last_dot   = rindex( $amount, '.' );
  my $last_comma = rindex( $amount, ',' );

  if ( $last_dot >= 0 && $last_comma >= 0 ) {
    if ( $last_comma > $last_dot ) {
      # European format: 1.234,56 — dot=thousands, comma=decimal
      $amount =~ s/\.//g;
      $amount =~ s/,/./;
    }
    else {
      # US format: 1,234.56 — comma=thousands, dot=decimal
      $amount =~ s/,//g;
    }
  }
  elsif ( $last_comma >= 0 ) {
    if ( $amount =~ /,\d{1,2}$/ ) {
      # European decimal without thousands: 100,50
      $amount =~ s/,/./;
    }
    else {
      # US thousands without decimal: 1,000
      $amount =~ s/,//g;
    }
  }

  return $amount;
}

sub _prepare_insert ($dbdbi) {
  $dbdbi->prepare(
    q{
    INSERT OR IGNORE INTO transactions (id, account, date, amount, payee, memo, category, check_number)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?)
    }
  );
}

my @REQUIRED_HEADERS = ( 'Date', 'Transaction ID', 'Account', 'Amount', 'Description' );

sub _validate_csv ( $csv_file, $csv, $fh, $header ) {
  my %found = map { $_ => 1 } @$header;
  my @missing = grep { !$found{$_} } @REQUIRED_HEADERS;
  if (@missing) {
    die "CSV validation failed for $csv_file: missing required column(s): "
      . join( ', ', @missing ) . "\n";
  }
  if ( $csv->error_diag() ) {
    die "CSV parse error in $csv_file: " . $csv->error_diag() . "\n";
  }
}

sub _prepare_count ($dbdbi) {
  $dbdbi->prepare(
    q{ SELECT COUNT (*) FROM transactions;  }
  );
}

sub _insert_row ( $insert, $columns, $row, $verbose ) {
  my %r;
  @r{@$columns} = @$row;
  my $amount = _normalize_amount( $r{'Amount'} // '' );
  my $date   = $r{'Date'} // '';
  my $rowstr = join( ", ", map { $_ // '' } @r{@$columns} );
  my $dt;
  try {
    $dt   = DateTime::Format::Flexible->parse_datetime($date);
    $date = $dt->ymd;
  }
  catch ($e) {
    print "[WARN] Could not parse date '$date' for record: $rowstr\n";
    return;
  }
  my $id        = $r{'Transaction ID'}   || return;
  my $account   = $r{'Account'}          || '';
  my $payee     = $r{'Description'}      || $r{'Full Description'} // '';
  my $memo      = $r{'Full Description'} || '';
  my $cat       = $r{'Category'}         || '';
  my $check_num = $r{'Check Number'}     // '';
  $check_num = undef if !length($check_num) || $check_num eq '0';
  try {
    # if the insert fails catch will report the issue.
    local $SIG{__WARN__} = sub {};
    $insert->execute( $id, $account, $date, $amount, $payee, $memo, $cat, $check_num );
    vPrint( $verbose, "Ingest: $rowstr" );
  }
  catch ($e) {
    say "Failed to import row to transactions ${rowstr} \n$e  ";
  }
}

sub Ingest ( $csv_file, $db_path, $verbose=0 ) {
  my $dbdbi = DBI->connect(
    "dbi:SQLite:dbname=$db_path",
    "", "",
    {
      RaiseError      => 1,
      PrintError      => 0,
      AutoCommit      => 1,
      sqlite_unicode  => 1,
    }
  );
  my $csv = Text::CSV->new({ binary => 1 });
  my $fh  = path($csv_file)->openr_utf8 or die "File not found: $csv_file\n";
  my $header = $csv->getline($fh)
    or die "CSV appears empty or unreadable\n";
  _validate_csv( $csv_file, $csv, $fh, $header );

  my $insert = _prepare_insert($dbdbi);
  my $counter = _prepare_count($dbdbi);
  $counter->execute();
  my ($StartCnt) = $counter->fetchrow_array;

  while ( my $row = $csv->getline($fh) ) {
    _insert_row( $insert, $header, $row, $verbose );
  }
  $counter->execute();
  my ($EndCnt) = $counter->fetchrow_array;
  return ( $EndCnt - $StartCnt );
}

1;
