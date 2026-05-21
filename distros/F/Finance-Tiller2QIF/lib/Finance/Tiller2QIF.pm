package Finance::Tiller2QIF;
# ABSTRACT: Convert Tiller CSV exports to QIF format
$Finance::Tiller2QIF::VERSION = '1.06';
use v5.34;
use strict;
use warnings;
use utf8;
use warnings FATAL => 'utf8';
use open ':std', ':encoding(UTF-8)';

use feature qw/signatures postderef try/;

use Path::Tiny;
use Getopt::Long::Descriptive;
use Cpanel::JSON::XS;
use Finance::Tiller2QIF::ReadCSV;
use Finance::Tiller2QIF::Map;
use Finance::Tiller2QIF::Util qw/vPrint/;
use Finance::Tiller2QIF::WriteQIF;
use Time::Piece;
# use Data::Printer;


=pod

=encoding utf8

=head1 NAME

tiller2qif

Finance::Tiller2QIF

=head1 DESCRIPTION

Convert Tiller CSV exports to QIF for import into Financial software like GnuCash, KMyMoney, Quicken, HomeBank, Money Manager Ex and many others.

=head1 SYNOPSIS

  # Command-line
  tiller2qif run --input export.csv --db tiller.sqlite3 \
                 --output import.qif [--mapfile mapping.txt]

  # Programmatic — see PROGRAMMATIC USE below
  use Finance::Tiller2QIF::ReadCSV;
  use Finance::Tiller2QIF::Map;
  use Finance::Tiller2QIF::WriteQIF;

  Finance::Tiller2QIF::ReadCSV::Ingest( 'export.csv', 'tiller.sqlite3' );
  Finance::Tiller2QIF::Map::Map({ db_path => 'tiller.sqlite3', mapfile => 'mapping.txt' });
  Finance::Tiller2QIF::WriteQIF::Emit( 'tiller.sqlite3', 'import.qif' );

=head1 OVERVIEW

Tiller Money (tillerapp.com) aggregates bank and credit-card transactions
into a Google Sheet and lets you export a CSV. This module ingests that CSV
into a SQLite database, optionally applies a category-mapping file to
translate Tiller's auto-assigned categories to match your accounts/categories, then emits a QIF file ready for import.

The three phases can be run individually or together:

=over 4

=item B<ingest> — parse the CSV and load rows into the SQLite database.

=item B<map> — apply a user-supplied mapping file that rewrites categories,
suppresses duplicates (card-payment credits), and assigns destination accounts.

=item B<emit> — read unexported rows from the database and write a QIF file.

=back

=head1 INSTALLATION

=head2 From CPAN

  cpan Finance::Tiller2QIF
  # or
  cpanm Finance::Tiller2QIF

=head2 Perl Dependencies

Runtime: Cpanel::JSON::XS, DateTime::Format::Flexible, Getopt::Long::Descriptive,
Path::Tiny, Mojo::SQLite, Text::CSV

Testing: Capture::Tiny, Test2::V0, Test2::Bundle::More, Test2::Tools::Exception

=head3 On Debian/Ubuntu:

All of Tiller2QIF’s dependencies are available through package management if you need to install to system Perl.

  sudo apt install libpath-tiny-perl libtext-csv-perl libtest2-suite-perl libcapture-tiny-perl \
    libmojo-sqlite-perl libcpanel-json-xs-perl libdatetime-format-flexible-perl
  sudo cpan install Finance::Tiller2QIF

=head3 On Windows

tiller2qif works with Strawberry Perl, after installing Strawberry Perl, install from CPAN.

=head1 CLI COMMANDS

=over 4

=item B<run> -- ingest, map, and emit in one step

  tiller2qif run --input export.csv --db tiller.sqlite3 \
                 --output import.qif [--mapfile mapping.txt]

  run will always create a checkpoint even when the flag is not set.

=item B<ingest> -- load CSV into the database

  tiller2qif ingest --input export.csv --db tiller.sqlite3

=item B<map> -- apply category mapping rules

  tiller2qif map --db tiller.sqlite3 [--mapfile mapping.txt] \
                 [--beforemap before.sql] [--aftermap after.sql]

=item B<preview> -- preview the records that would be emitted

  tiller2qif preview --db tiller.sqlite3

=item B<emit> -- write QIF from the database

  tiller2qif emit --db tiller.sqlite3 --output import.qif [--qifdate mdy]

=item B<newdb> -- initialise a new SQLite database

  tiller2qif newdb --db tiller.sqlite3

=item B<newconfig> -- create a starter config file

  tiller2qif newconfig [--config ~/.config/tiller2qif.conf]

=item B<checkconfig> -- check the merged values of cli arguments and config file

  # The verbose flag will run checkconfig before beginning any operations.
  tiller2qif checkconfig [--config ~/.config/tiller2qif.conf]

=item B<clean> -- remove checkpoint copies of the database

Deletes all timestamped checkpoint files created by C<--checkpoint> or C<run>,
leaving the live database intact.

  tiller2qif clean --db tiller.sqlite3

=item B<version> -- print the installed version number

  tiller2qif version

=back

=head1 OPTIONS

All options can be supplied on the command line or in a JSON config file.
Use C<tiller2qif newconfig --config path/to/file.conf> to generate a starter
config file.  A typical config file looks like:

  {
    "input":      "~/Downloads/mytillerdump.csv",
    "output":     "/tmp/tillerout.qif",
    "db":         "~/.data/tiller2qif.sqlite3",
    "mapfile":    "~/.config/tiller.mapping",
    "verbose":    false,
    "checkpoint": false,
    "confirm":    false
  }

Pass the config file with C<--config>.  Command-line options override config
file values.

=over 4

=item B<--config> Path to a JSON config file.

=item B<--input> CSV export from Tiller.

=item B<--output> QIF file to create.

=item B<--db> SQLite database file used to store and transform transactions between phases.

=item B<--mapfile> File containing category mapping rules.  Optional; omitting it passes
transactions through with their original Tiller categories.

=item B<--beforemap> Path to a SQL script to execute against the database immediately
before the mapping rules are applied.  Useful for preprocessing transactions — for
example, renaming accounts or correcting data — in ways that affect which map rules
fire.

=item B<--aftermap> Path to a SQL script to execute against the database immediately
after the mapping rules are applied.  Useful for post-processing the mapped results —
for example, marking or transforming rows based on what the map phase produced.

=item B<--qifdate> QIF output date format.  Accepts C<ymd> (default, ISO 8601:
C<2026-04-24>), C<mdy> (US: C<04/24/2026>), or C<dmy> (European: C<24/04/2026>).
Use C<mdy> or C<dmy> when your financial software does not recognise ISO dates
during import.

=item B<--checkpoint> Copy the database with a timestamp suffix before any operations.
The C<run> command always checkpoints, even without this flag.

=item B<--confirm> Run preview before emit (including on C<run>) and prompt for
confirmation before writing the QIF file.

=item B<--verbose> Print detailed progress information during each phase.  Also
runs C<checkconfig> automatically before any operations begin.

=back

=head1 MAPPING FILE

The mapping file controls how Tiller categories are translated into destination
account or category names and which transactions to suppress.  Each non-comment
line has the form:

  [AccountFilter] field | pattern | destination

Lines beginning with C<#> and blank lines are ignored.  Rules are evaluated in
order; the first matching rule wins and no further rules are checked for that
transaction.

=over 4

=item B<AccountFilter> (optional) — a Perl regex in square brackets that
restricts the rule to transactions on matching accounts.  Alternation works
naturally: C<[Checking|Savings]>. Omit to match all accounts.

=item B<field> — the transaction field to test: C<category>, C<payee>,
C<memo>, C<date>, or C<amount>.

=item B<pattern> — a Perl regex applied case-insensitively to the field value.

For a simple pattern containing no C<|>, write it as-is:

  payee | Starbucks | Expenses:Coffee

To allow setting a category with only an AccountFilter, use C<*> as the entire pattern to match against any field value:

  # Without an account filter all transactions will match!
  [AccountFilter] any_matchable_field | * | new_category

To use regex alternation (matching either of several values), enclose the
pattern in forward slashes:

  payee | /Starbucks|Dunkin/ | Expenses:Coffee

To match a literal pipe character in the data, escape it with a backslash:


=item C<source> — keep the original Tiller category unchanged.

=item C<blank> — emit no category field in the QIF output.

=item C<skip> — exclude the transaction from QIF output entirely (useful for
suppressing the credit-side of card payments that appear in both accounts).

=back

For double-entry programs such as GnuCash, destination is a full account name
(e.g. C<Expenses:Groceries>).  For single-entry programs such as Quicken it is
a category name.


The optional C<default> line sets the fallback for transactions that match no
rule.  It must appear as the last non-comment line:

  default | source

If the C<default> line is omitted, unmatched transactions behave as
C<default | source>.

=head2 EXAMPLES

=over 4

=item * Map by category

  category | Groceries | Expenses:Groceries

=item * Map by payee with alternation (slash-delimited pattern)

  payee | /Starbucks|Dunkin/ | Expenses:Coffee

=item * Map by payee, scoped to one account

  [Checking] payee | Payroll | Income:Salary

=item * Scope to multiple accounts using alternation in the account filter

  [Checking|Savings] category | Transfer | skip

=item * Skip card-payment credits on the card account

  [CapitalOne] category | Transfer | skip

=item * Match a literal pipe character in a payee name

  payee | Cash\|App | Expenses:Transfers

=item * Suppress category in QIF (no L field)

  category | Miscellaneous | blank

=item * Default: leave unmatched transactions with their Tiller category

  default | source

=back

=head1 Advanced Use

You can write SQL scripts or use an interactive sqlite3 client to make changes between steps. For example your Tiller sheet might have an account "Checking", while your table of accounts has "Assets::Current Assets::Bank::Checking". With custom SQL you can keep the short name in Tiller even though mapping rules can't rename accounts.

The C<--beforemap> and C<--aftermap> options allow SQL scripts to run immediately before
and after the map phase without having to break the workflow into separate commands.
This is the preferred way to preprocess or post-process transactions when using C<run>,
or C<map> as a single step.

The C<preview> command is meant to be run between map and emit. You may run the steps individually (ingest, map, preview, emit), or use the --confirm option to run preview before emit (including run).

While other CSV export sources are not directly supported, you can write a script to remap the fields for ingestion or just import into the table, and then use the map and emit stages to complete your export. If translating other CSV sources be aware that Tiller currently only provides it's data in the US 'MM/DD/YYYY' format, this program can also accept dates in ISO 8601 'YYYY-MM-DD'. Data is written into the SQLite database using the ISO 8601 format.

=head1 PROGRAMMATIC USE

C<Finance::Tiller2QIF> is primarily a CLI tool; the public functions exist to
support the command dispatcher. Programmatic users will likely use this module
as example code and call the sub-modules directly (C<Finance::Tiller2QIF::ReadCSV>,
C<Finance::Tiller2QIF::Map>, C<Finance::Tiller2QIF::WriteQIF>).

Note that all functions expect C<db_path> as the database parameter. The CLI
normalises the C<--db> option to C<db_path> internally; programmatic callers
should use C<db_path> directly.

=for Pod::Coverage run_cli

=head1 AUTHOR

John Karr E<lt>brainbuz@cpan.orgE<gt>

=head1 LICENSE

GPL version 3 or later.

=cut

# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------

sub _ingest (%options) {
  Finance::Tiller2QIF::ReadCSV::Ingest( $options{input}, $options{db_path},
    $options{verbose} );
}

sub _apply_map (%options) {
  Finance::Tiller2QIF::Map::Map( \%options );
}

sub _emit (%options) {
  Finance::Tiller2QIF::WriteQIF::Emit( $options{db_path}, $options{output},
    $options{verbose}, $options{qifdate} // 'ymd' );
}

sub _preview (%options) {
  Finance::Tiller2QIF::WriteQIF::Preview( $options{db_path}, $options{verbose} );
}

sub _run (%options) {
  _ingest(%options);
  _apply_map(%options);
  _emit(%options);
}

sub _checkpoint($file) {
  my $new = "$file." . localtime()->datetime();
  $new =~ s/[T:]/_/g;
  path($file)->copy($new);
}

sub _clean_checkpoints($file) {
  my @checkpoints = grep { /\.\d{4}-\d{2}-\d{2}_\d{2}_\d{2}_\d{2}$/ } glob( $file . '.*' );
  for my $cp (@checkpoints) {
    path($cp)->remove;
    say "Removed checkpoint: $cp";
  }
  return scalar @checkpoints;
}

# ---------------------------------------------------------------------------
# CLI entry point — called by bin/tiller2qif
# ---------------------------------------------------------------------------

my $VALID_COMMANDS = join '|',
  qw(run ingest map emit preview newdb newconfig checkconfig clean version);

my $hlpmsg = <<'END_USAGE';
tiller2qif — Convert Tiller Money CSV exports to QIF format.

Ingests a Tiller CSV into a SQLite database, optionally applies a
category-mapping file, then writes a QIF file ready for import into
GnuCash, KMyMoney, Quicken, HomeBank, and similar programs.

Usage: tiller2qif <command> %o

Commands: run | ingest | map | emit | preview | newdb | newconfig | checkconfig | version

For the full manual: perldoc Finance::Tiller2QIF
END_USAGE

my $badcmdhelp = <<'BADCMD';

There was an error in your command line.
Common causes are:
* mistyping an option
* command after options
* accidental text in the line

BADCMD

sub run_cli {
  my $cmd = '';
  # uncoverable branch true
  # uncoverable branch false
  if ( @ARGV && $ARGV[0] !~ /^-/ ) {
    $cmd = lc shift @ARGV;
  }

  my ( $opt, $usage ) = eval {
    describe_options(
      $hlpmsg,
      [ 'config|c=s',   "JSON config file" ],
      [ 'checkpoint|C', "copy database with timestamp before run." ],
      [ 'input|i=s',    "CSV file to read      (ingest, run)" ],
      [ 'output|o=s',   "QIF file to write     (emit, run)" ],
      [ 'db|d=s', "SQLite database file  (all commands except newconfig)" ],
      [ 'mapfile|f=s', "Category mapping file (map, run — optional)" ],
      [ 'beforemap=s', "sql script to run prior to map" ],
      [ 'aftermap=s',  "sql script to run after map" ],
      [ 'qifdate=s',   "QIF date format: ymd (default), mdy, or dmy" ],
      [ 'confirm',     "run preview before emit and confirm export"],
      [ 'verbose|v',   "Print detailed progress information" ],
      [],
      [ 'help|h', "Print usage and exit", { shortcircuit => 1 } ],
    );
  };
  # uncoverable branch true
  die $@, $badcmdhelp if $@;

  if ( $opt->help ) {
    say $usage;
    return;
  }

  if ( !$cmd ) {
    die
"Command Missing! Valid commands: $VALID_COMMANDS\nFor help: tiller2qif --help\n";
  }

  die qq{Unknown command '$cmd'.
    Valid commands: $VALID_COMMANDS
    for help tiller2qif --help or perldoc tiller2qif
    \n}
    unless $cmd =~ /^(?:$VALID_COMMANDS)$/;

  if ( $cmd eq 'version' ) {
    # dzil is in charge of the $VERSION variable which means it is undefined during development
    # uncoverable branch true
    # uncoverable branch false
    my $v = do { no strict 'vars'; $VERSION // 'unversioned' };
    say "Tiller2QIF VERSION: ${v}";
    return;
  }

  if ( $cmd eq 'newconfig' ) {
    die "newconfig requires --config\n" unless $opt->config;
    # say "Creating config file: " . $opt->config if $opt->verbose;
    vPrint( $opt->verbose, "Creating config file: " . $opt->config );
    Finance::Tiller2QIF::Util::InitConfig( $opt->config );
    say "Config file created: " . $opt->config;
    return;
  }

  # Precedence: defaults < config file < CLI args
  my %options = (
    input      => undef,
    output     => undef,
    db         => undef,
    mapfile    => undef,
    beforemap  => undef,
    aftermap   => undef,
    qifdate    => 'ymd',
    verbose    => 0,
    checkpoint => 0,
    confirm    => 0,
  );

  if ( $opt->config ) {
    my $config = Cpanel::JSON::XS->new->utf8->relaxed->decode(
      path( $opt->config )->slurp_utf8 );
    for my $key ( keys %options ) {
      $options{$key} = $config->{$key} if defined $config->{$key};
    }
  }

  for my $key ( keys %options ) {
    my $val = $opt->$key();
    $options{$key} = $val if defined $val;
  }

  $options{db_path} = delete $options{db} if defined $options{db};

  if ( $cmd eq 'newdb' ) {
    die "newdb requires --db\n" unless $options{db_path};
    vPrint( $opt->verbose, "Creating database: " . $options{db_path} );
    # say "Creating database: " . $options{db_path} if $opt->verbose;
    Finance::Tiller2QIF::Util::InitDB( $options{db_path} );
    say "Database initialized: " . $options{db_path};
    return;
  }

  if ( $cmd eq 'clean' ) {
    die "clean requires --db\n" unless $options{db_path};
    my $removed = _clean_checkpoints( $options{db_path} );
    say "Removed $removed checkpoint(s)";
    return;
  }

  my @missing;
  push @missing, '--input'  if $cmd =~ /^(?:ingest|run)$/ && !$options{input};
  push @missing, '--db'     if !$options{db_path};
  push @missing, '--output' if $cmd =~ /^(?:emit|run)$/ && !$options{output};

  if (@missing) {
    die "tiller2qif $cmd: missing required option(s): "
      . join( ', ', @missing ) . "\n";
  }

  if ( $options{verbose} || $cmd eq 'checkconfig' ) {
    Finance::Tiller2QIF::Util::CheckConfig(%options);
  }

  if ( $options{checkpoint} || $cmd eq 'run' ) {
    _checkpoint( $options{db_path} );
  }

  if ( $cmd =~ /^(?:ingest|run)$/ ) {
    vPrint( $options{verbose}, "Ingesting CSV: " . $options{input} );

    my $newitems = _ingest(%options);
    say "Ingested: ${newitems} transactions from: " . $options{input};
  }

  if ( $cmd =~ /^(?:map|run)$/ ) {
    if ( $options{mapfile} ) {
      say "Applying mapping: " . $options{mapfile} if $options{verbose};
      _apply_map(%options);
      say "Mapping applied: " . $options{mapfile};
    }
    else {
      say "No mapfile provided, skipping mapping phase";
    }
  }

  if ( $cmd =~ /^(?:emit|run)$/ ) {
    if ( $options{confirm} ) {
      my $count = _preview(%options);
      say "${count} transaction(s) pending export.";
      say '?'x60;
      print "Complete export? Y/n: ";
      my $response = <STDIN>;
      # uncoverable branch true
      # uncoverable branch false
      return unless $response =~ /^y/i;
    }
    vPrint( $options{verbose}, "Writing QIF: " . $options{output} );
    my $changed = _emit(%options);
    say "QIF written: ${\ $options{output}}, ${changed} records emitted!";
  }

  if ( $cmd eq 'preview' ) {
    my $count = _preview(%options);
    say "${count} transaction(s) pending export.";
  }
}

1;

=for Pod::Coverage run_cli
