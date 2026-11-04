package Finance::Tiller2QIF::WriteQIF;
# ABSTRACT: Write transactions to QIF format
$Finance::Tiller2QIF::WriteQIF::VERSION = '1.21';
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

Display all unexported, non-skipped transactions as labeled blocks. The first line shows transaction ID, date, and account; indented lines show amount, payee, memo, and category without truncation. Shows original category in brackets if mapped to a different category. Returns the count of transactions displayed.

C<$viewer> selects where the table goes. The default, C<console>, prints to STDOUT. Any other value is used as-is as a shell command line (optionally with arguments, e.g. C<code --wait>); the table is written to a read-only temporary file with a C<.t2qpv> suffix, and the command is run with that file's path (shell-quoted) appended, then the path is printed. Because the whole line goes to the shell, ordinary shell quoting works — a program path containing spaces can be double- or single-quoted within C<$viewer> itself. The temporary file is left in place for the viewer to read. An undefined or blank viewer is fatal, and so is anything other than a normal, successful run of the command — there is no silent fallback to the console, and no attempt to report why it failed beyond that.

Any further arguments are additional files to open alongside the preview, in the same viewer invocation; the CLI passes the mapping file here for C<--multipreview>. They require a real viewer (not C<console>) and must be readable, or the call dies.

On Windows, the command runs through C<cmd.exe> with Windows quoting for the file arguments. Use double quotes around program paths containing spaces. Delayed environment-variable expansion is disabled so file names containing C<!> remain literal.

=head1 AUTHOR

John Karr E<lt>cpan@brainbuz.orgE<gt>

=head1 LICENSE

GPL version 3 or later.

=cut

use 5.036;

use Path::Tiny;
use Text::CSV;
use File::Temp ();
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

sub _preview_inline ($value) {
  $value //= '';
  $value =~ s/\\/\\\\/g;
  $value =~ s/\r/\\r/g;
  $value =~ s/\n/\\n/g;
  $value =~ s/\t/\\t/g;
  return $value;
}

sub _preview_field ($label, $value) {
  $value //= '';
  $value =~ s/\r\n?/\n/g;
  my ($first, @rest) = split /\n/, $value, -1;
  my $text = sprintf "    %-10s%s\n", "$label:", $first // '';
  $text .= "              $_\n" for @rest;
  return $text;
}

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
      my $orig   = $tx->{category} // '';
      my $mapped = $tx->{mapped_category} // $orig; # uncoverable statement
      my $cat    = $mapped ne $orig
                 ? '[' . $orig . '] ' . $mapped
                 : $mapped;

      push @rows, {
        id      => $tx->{id},
        account => $account,
        date    => $tx->{date},
        amount  => sprintf( "%.2f", $tx->{amount} ),
        payee   => $tx->{payee},
        cat     => $cat,
        memo    => $tx->{memo},
      };
    }
  }

  my $text = @rows ? '' : "No transactions pending export.\n";
  for my $row (@rows) {
    $text .= sprintf "ID: %s | Date: %s | Account: %s\n",
      map { _preview_inline($_) } @{$row}{qw(id date account)};
    $text .= _preview_field('Amount', $row->{amount});
    $text .= _preview_field('Payee', $row->{payee});
    $text .= _preview_field('Memo', $row->{memo});
    $text .= _preview_field('Category', $row->{cat});
    $text .= "\n";
  }

  $dbh->disconnect;
  return ( scalar @rows, $text );
}

sub _shell_quote ($str) {
  $str =~ s/'/'\\''/g;
  return "'$str'";
}

sub _launch_windows_viewer ($viewer, @files) {
  require Win32::ShellQuote;
  my $cmd = join ' ', $viewer, Win32::ShellQuote::quote_cmd(@files);
  my $shell = $ENV{COMSPEC} // 'cmd.exe';
  # Force cmd.exe so quoting does not depend on Perl's shell autodetection.
  # Disable AutoRun and delayed expansion so file names containing ! survive.
  # Perl adds the outer quotes for /c; adding another pair breaks viewers
  # whose executable path is already quoted.
  die "preview viewer '$viewer' failed\n"
    if system { $shell } $shell, '/d', '/v:off', '/s', '/c', $cmd;
}

sub _launch_viewer ( $viewer, $text, @also ) {
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
  if ($^O eq 'MSWin32') {
    _launch_windows_viewer($viewer, $file, @also);
  }
  else {
    my $cmd = join ' ', $viewer, map { _shell_quote($_) } $file, @also;
    die "preview viewer '$viewer' failed\n" if system($cmd);
  }
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
