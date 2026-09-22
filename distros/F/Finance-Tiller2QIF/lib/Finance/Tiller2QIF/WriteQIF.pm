package Finance::Tiller2QIF::WriteQIF;
# ABSTRACT: Write transactions to QIF format
$Finance::Tiller2QIF::WriteQIF::VERSION = '1.10';
=encoding utf8

=head1 DESCRIPTION

Exports transactions from the SQLite database to QIF (Quicken Interchange Format) for import into financial software. Transactions are grouped by account and sorted by date. Skipped transactions and those without effective categories are handled appropriately.

=head1 FUNCTIONS

=head2 Emit

  Finance::Tiller2QIF::WriteQIF::Emit( $db_path, $outfile );

Write all unexported, non-skipped transactions from the database to a QIF file. Each account is written as a separate QIF account block with transactions sorted by date then payee. Marks written transactions as exported in the database.

=head2 Preview

  Finance::Tiller2QIF::WriteQIF::Preview( $db_path );
  Finance::Tiller2QIF::WriteQIF::Preview( $db_path, $verbose, $viewer );
  Finance::Tiller2QIF::WriteQIF::Preview( $db_path, $verbose, $viewer, $mapfile );

Display all unexported, non-skipped transactions in a formatted table showing date, amount, account, payee, and category. Shows original category in brackets if mapped to a different category. Returns the count of transactions displayed.

C<$viewer> selects where the table goes. The default, C<console>, prints to STDOUT. Any other value names an external program (optionally with arguments, e.g. C<code --wait>); the table is written to a read-only temporary file with a C<.t2qpv> suffix, the program is launched with that file as its argument, and the path is printed. The temporary file is left in place for the viewer to read. An undefined or blank viewer, a program that cannot be found, and a program that fails to launch, dies on a signal, or exits non-zero are all fatal — there is no silent fallback to the console.

Any further arguments are additional files to open alongside the preview, in the same viewer invocation; the CLI passes the mapping file here for C<--multipreview>. They require a real viewer (not C<console>) and must be readable, or the call dies.

=head2 ResolveViewer

  my @command = Finance::Tiller2QIF::WriteQIF::ResolveViewer( $viewer );

Resolve a viewer specification to the command list that would be run, dying with the reason when it cannot be resolved. The specification is split on whitespace: the first word is the program and any remaining words are arguments placed before the file names. A program containing a path separator is used as given and must be executable; a bare program name is looked up along C<PATH>.

Because the specification is split on whitespace, the program's own path cannot contain spaces. Point C<$viewer> at a wrapper script or a symlink when the program you want lives in such a path.

C<Preview> calls this before it writes anything, so an unusable viewer fails before a temporary file is created. C<checkconfig> calls it to report an unusable viewer before any work begins.

=head1 AUTHOR

John Karr E<lt>brainbuz@cpan.orgE<gt>

=head1 LICENSE

GPL version 3 or later.

=cut

use v5.34;

use Path::Tiny;
use Text::CSV;
use File::Temp ();
use File::Spec ();
use Finance::Tiller2QIF::DB qw( connect_db );
use utf8;
use warnings FATAL => 'utf8';
use open ':std', ':encoding(UTF-8)';
use feature qw/signatures postderef/;
# use Data::Printer;

sub _init($db_path) {
  my $dbh = connect_db($db_path);
  my $sth = $dbh->prepare(
    q{SELECT distinct(account) FROM transactions WHERE exported = 0 AND skipped = 0;}
  );
  $sth->execute;
  my @accounts = map { $_->[0] } $sth->fetchall_arrayref->@*;
  return ( $dbh, \@accounts );
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
  my ( $dbh, $accounts ) = _init($db_path);
  my @qif;
  my $emitted = 0;
  for my $account (@$accounts) {
    my $header = join( "\n", "!Account", "N$account", "^", "!Type:Bank" );
    my $sth = $dbh->prepare(
      q{ SELECT *,
              COALESCE(mapped_category, category) AS effective_category
          FROM transactions
          WHERE exported = 0
          AND skipped = 0
          AND account = ?
          ORDER BY date, payee; }
    );
    $sth->execute($account);
    my @tx = $sth->fetchall_arrayref({})->@*;
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

  $dbh->do('UPDATE transactions SET exported = 1 WHERE exported = 0');
  $dbh->disconnect;
  return $emitted;
}

sub _trunc ( $str, $max ) { length($str) > $max ? substr( $str, 0, $max ) : $str }

sub _preview_text ($db_path) {
  my ( $dbh, $accounts ) = _init($db_path);

  my @rows;

  for my $account (@$accounts) {
    my $sth = $dbh->prepare(
      q{ SELECT * FROM transactions
          WHERE exported = 0 AND skipped = 0 AND account = ?
          ORDER BY date, payee; }
    );
    $sth->execute($account);
    my @tx = $sth->fetchall_arrayref({})->@*;

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

  my $text = sprintf $L1, 'Date', 'Amount', 'Account', 'Payee';
  $text .= "Category | Memo [Category preceded by original if changed by map]\n";
  $text .= "$div\n";
  for my $row (@rows) {
    $text .= sprintf $L1, $row->{date}, $row->{amount}, $row->{account}, $row->{payee};
    $text .= sprintf $L2, $row->{cat}, $row->{memo};
  }

  $dbh->disconnect;
  return ( scalar @rows, $text );
}

sub ResolveViewer ($viewer) {
  my @cmd = split ' ', $viewer;
  die "preview viewer is empty; use 'console' to print to STDOUT\n" unless @cmd;
  my $prog = $cmd[0];
  if ( $prog =~ m{[/\\]} || File::Spec->file_name_is_absolute($prog) ) {
    die "preview viewer '$prog' is not an executable file\n" unless -x $prog;
    return @cmd;
  }
  # File::Spec->path splits PATH the way this OS does, and resolves an empty
  # entry to '.' exactly as exec will.
  for my $dir ( File::Spec->path ) {
    return @cmd if -x File::Spec->catfile( $dir, $prog );
  }
  die "preview viewer '$prog' was not found in PATH\n";
}

sub _launch_viewer ( $viewer, $text, @also ) {
  my @cmd = ResolveViewer($viewer);
  for my $extra (@also) {
    die "preview cannot open '$extra': it does not exist or can't be read\n"
      unless -r $extra;
  }

  my ( $fh, $file ) = File::Temp::tempfile(
    'tiller2qif-preview-XXXXXXXX',
    SUFFIX => '.t2qpv',
    TMPDIR => 1,
    UNLINK => 0,
  );
  binmode $fh, ':encoding(UTF-8)';
  print {$fh} $text;
  close $fh or die "unable to write preview file $file: $!\n";
  chmod 0400, $file or die "unable to make preview file $file read-only: $!\n";

  say "Preview written to $file";
  say "Also opening: $_" for @also;
  my $rc = system( @cmd, $file, @also );
  die "preview viewer '$cmd[0]' failed to launch: $!\n" if $rc == -1;
  die "preview viewer '$cmd[0]' died on signal ${\ ($rc & 127) }\n" if $rc & 127;
  die "preview viewer '$cmd[0]' exited with status ${\ ($rc >> 8) }\n" if $rc;
  return $file;
}

sub Preview ( $db_path, $verbose=0, $viewer='console', @also ) {
  die "preview viewer is not set; use 'console' to print to STDOUT\n"
    unless defined $viewer && $viewer =~ /\S/;
  die "opening additional files requires a preview viewer, not 'console'\n"
    if @also && lc $viewer eq 'console';

  my ( $count, $text ) = _preview_text($db_path);

  if ( lc $viewer eq 'console' ) { print $text }
  else                           { _launch_viewer( $viewer, $text, @also ) }

  return $count;
}

1;
