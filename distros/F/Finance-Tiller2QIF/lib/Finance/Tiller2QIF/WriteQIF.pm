package Finance::Tiller2QIF::WriteQIF;
# ABSTRACT: Write transactions to QIF format
$Finance::Tiller2QIF::WriteQIF::VERSION = '1.06';
=head1 DESCRIPTION

Exports transactions from the SQLite database to QIF (Quicken Interchange Format) for import into financial software. Transactions are grouped by account and sorted by date. Skipped transactions and those without effective categories are handled appropriately.

=head1 FUNCTIONS

=head2 Emit

  Finance::Tiller2QIF::WriteQIF::Emit( $db_path, $outfile );

Write all unexported, non-skipped transactions from the database to a QIF file. Each account is written as a separate QIF account block with transactions sorted by date then payee. Marks written transactions as exported in the database.

=head2 Preview

  Finance::Tiller2QIF::WriteQIF::Preview( $db_path );

Display all unexported, non-skipped transactions in a formatted table showing date, amount, account, payee, and category. Shows original category in brackets if mapped to a different category. Returns the count of transactions displayed.

=head1 AUTHOR

John Karr E<lt>brainbuz@cpan.orgE<gt>

=head1 LICENSE

GPL version 3 or later.

=cut

use v5.34;

use Path::Tiny;
use Text::CSV;
use Mojo::SQLite;
use utf8;
use warnings FATAL => 'utf8';
use open ':std', ':encoding(UTF-8)';
use feature qw/signatures postderef/;
# use Data::Printer;

sub _init($db_path) {
  my $sql      = Mojo::SQLite->new($db_path)->options({ sqlite_unicode => 1 });
  my @accounts =
    map { $_->[0] }
    $sql->db->query(
    q{SELECT distinct(account) FROM transactions WHERE exported = 0 AND skipped = 0;})
    ->arrays->@*;
  return ( $sql, \@accounts );
}

my %_date_fmt = (
  ymd => sub { $_[0] }, # database uses ymd, no transformation
  mdy => sub { my ($y,$m,$d) = split /-/, $_[0]; "$m/$d/$y" },
  dmy => sub { my ($y,$m,$d) = split /-/, $_[0]; "$d/$m/$y" },
);

sub _format_date ( $iso_date, $fmt ) {
  my $fn = $_date_fmt{ $fmt };
  $fn->($iso_date);
}

sub Emit ( $db_path, $outfile, $verbose=0, $qifdate='ymd' ) {
  my ( $sql, $accounts ) = _init($db_path);
  my @qif;
  my $emitted = 0;
  for my $account (@$accounts) {
    my $header = join( "\n", "!Account", "N$account", "^", "!Type:Bank" );
    my @tx     = $sql->db->query(
      q{ SELECT *,
              COALESCE(mapped_category, category) AS effective_category
          FROM transactions
          WHERE exported = 0
          AND skipped = 0
          AND account = ?
          ORDER BY date, payee; },
      $account
    )->hashes()->@*;
    my @qif_tx = map {
      my $date = _format_date( $_->{date}, $qifdate );
      join( "\n",
        "D$date", sprintf("T%.2f", $_->{amount}),
        ( $_->{check_number} ? "N$_->{check_number}" : () ),
        "P$_->{payee}",
        ( $_->{memo} ? "M$_->{memo}" : () ),
        ( $_->{effective_category} ? "L$_->{effective_category}" : () ), "^" )
    } @tx;
    $emitted += scalar @tx;
    push @qif, $header, @qif_tx;
  }

 # Combine all QIF fragments into a single multi-account QIF and write to file

  path($outfile)->spew_utf8( join( "\n", @qif ) . "\n" );

  $sql->db->query('UPDATE transactions SET exported = 1 WHERE exported = 0');
  return $emitted;
}

sub _trunc ( $str, $max ) { length($str) > $max ? substr( $str, 0, $max ) : $str }

sub Preview ( $db_path, $verbose=0 ) {
  my ( $sql, $accounts ) = _init($db_path);

  my @rows;

  for my $account (@$accounts) {
    my @tx = $sql->db->query(
      q{ SELECT * FROM transactions
          WHERE exported = 0 AND skipped = 0 AND account = ?
          ORDER BY date, payee; },
      $account
    )->hashes()->@*;

    for my $tx (@tx) {
      my $orig   = $tx->{category};
      my $mapped = $tx->{mapped_category} // $orig; # uncoverable statement
      my $cat    = $mapped ne $orig
                 ? '[' . $orig . '] ' . $mapped
                 : $mapped;

      push @rows, {
        account => _trunc( $account,          30 ),
        date    => $tx->{date},
        amount  => sprintf( "%.2f", $tx->{amount} ),
        payee   => _trunc( $tx->{payee},      20 ),
        cat     => _trunc( $cat,              30 ),
        memo    => _trunc( $tx->{memo},       30 ),
      };
    }
  }

  # line 1: date | amount | account | payee
  # line 2:  (1-space indent) category | memo
  my $L1 = "%-10s | %8s | %-20s | %-20s\n";
  my $L2 = " %-30s | %-30s\n";
  my $div = '-' x 68;

  printf $L1, 'Date', 'Amount', 'Account', 'Payee';
  say "Category | Memo [Category preceded by original if changed by map]";
  say $div;
  for my $row (@rows) {
    printf $L1, $row->{date}, $row->{amount}, $row->{account}, $row->{payee};
    printf $L2, $row->{cat}, $row->{memo};
  }

  return scalar @rows;
}

1;
