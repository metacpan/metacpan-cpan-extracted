# NAME

tiller2qif

Finance::Tiller2QIF

# DESCRIPTION

Convert Tiller CSV exports to QIF for import into Financial software like GnuCash, KMyMoney, Quicken, HomeBank, Money Manager Ex and many others.

# SYNOPSIS

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

# OVERVIEW

Tiller Money (tillerapp.com) aggregates bank and credit-card transactions
into a Google Sheet and lets you export a CSV. This module ingests that CSV
into a SQLite database, optionally applies a category-mapping file to
translate Tiller's auto-assigned categories to match your accounts/categories, then emits a QIF file ready for import.

The three phases can be run individually or together:

- **ingest** — parse the CSV and load rows into the SQLite database.
- **map** — apply a user-supplied mapping file that rewrites categories,
suppresses duplicates (card-payment credits), and assigns destination accounts.
- **emit** — read unexported rows from the database and write a QIF file.

# INSTALLATION

## From CPAN

    cpan Finance::Tiller2QIF
    # or
    cpanm Finance::Tiller2QIF

## Perl Dependencies

Runtime: Cpanel::JSON::XS, DateTime::Format::Flexible, Getopt::Long::Descriptive,
Path::Tiny, Mojo::SQLite, Text::CSV

Testing: Capture::Tiny, Test2::V0, Test2::Bundle::More, Test2::Tools::Exception

### On Debian/Ubuntu:

All of Tiller2QIF’s dependencies are available through package management if you need to install to system Perl.

    sudo apt install libpath-tiny-perl libtext-csv-perl libtest2-suite-perl libcapture-tiny-perl \
      libmojo-sqlite-perl libcpanel-json-xs-perl libdatetime-format-flexible-perl
    sudo cpan install Finance::Tiller2QIF

### On Windows

tiller2qif works with Strawberry Perl, after installing Strawberry Perl, install from CPAN.

# CLI COMMANDS

- **run** -- ingest, map, and emit in one step

        tiller2qif run --input export.csv --db tiller.sqlite3 \
                       --output import.qif [--mapfile mapping.txt]

        run will always create a checkpoint even when the flag is not set.

- **ingest** -- load CSV into the database

        tiller2qif ingest --input export.csv --db tiller.sqlite3

- **map** -- apply category mapping rules

        tiller2qif map --db tiller.sqlite3 [--mapfile mapping.txt] \
                       [--beforemap before.sql] [--aftermap after.sql]

- **preview** -- preview the records that would be emitted

        tiller2qif preview --db tiller.sqlite3

- **emit** -- write QIF from the database

        tiller2qif emit --db tiller.sqlite3 --output import.qif [--qifdate mdy]

- **newdb** -- initialise a new SQLite database

        tiller2qif newdb --db tiller.sqlite3

- **newconfig** -- create a starter config file

        tiller2qif newconfig [--config ~/.config/tiller2qif.conf]

- **checkconfig** -- check the merged values of cli arguments and config file

        # The verbose flag will run checkconfig before beginning any operations.
        tiller2qif checkconfig [--config ~/.config/tiller2qif.conf]

- **clean** -- remove checkpoint copies of the database

    Deletes all timestamped checkpoint files created by `--checkpoint` or `run`,
    leaving the live database intact.

        tiller2qif clean --db tiller.sqlite3

- **version** -- print the installed version number

        tiller2qif version

# OPTIONS

All options can be supplied on the command line or in a JSON config file.
Use `tiller2qif newconfig --config path/to/file.conf` to generate a starter
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

Pass the config file with `--config`.  Command-line options override config
file values.

- **--config** Path to a JSON config file.
- **--input** CSV export from Tiller.
- **--output** QIF file to create.
- **--db** SQLite database file used to store and transform transactions between phases.
- **--mapfile** File containing category mapping rules.  Optional; omitting it passes
transactions through with their original Tiller categories.
- **--beforemap** Path to a SQL script to execute against the database immediately
before the mapping rules are applied.  Useful for preprocessing transactions — for
example, renaming accounts or correcting data — in ways that affect which map rules
fire.
- **--aftermap** Path to a SQL script to execute against the database immediately
after the mapping rules are applied.  Useful for post-processing the mapped results —
for example, marking or transforming rows based on what the map phase produced.
- **--qifdate** QIF output date format.  Accepts `ymd` (default, ISO 8601:
`2026-04-24`), `mdy` (US: `04/24/2026`), or `dmy` (European: `24/04/2026`).
Use `mdy` or `dmy` when your financial software does not recognise ISO dates
during import.
- **--checkpoint** Copy the database with a timestamp suffix before any operations.
The `run` command always checkpoints, even without this flag.
- **--confirm** Run preview before emit (including on `run`) and prompt for
confirmation before writing the QIF file.
- **--verbose** Print detailed progress information during each phase.  Also
runs `checkconfig` automatically before any operations begin.

# MAPPING FILE

The mapping file controls how Tiller categories are translated into destination
account or category names and which transactions to suppress.  Each non-comment
line has the form:

    [AccountFilter] field | pattern | destination

Lines beginning with `#` and blank lines are ignored.  Rules are evaluated in
order; the first matching rule wins and no further rules are checked for that
transaction.

- **AccountFilter** (optional) — a Perl regex in square brackets that
restricts the rule to transactions on matching accounts.  Alternation works
naturally: `[Checking|Savings]`. Omit to match all accounts.
- **field** — the transaction field to test: `category`, `payee`,
`memo`, `date`, or `amount`.
- **pattern** — a Perl regex applied case-insensitively to the field value.

    For a simple pattern containing no `|`, write it as-is:

        payee | Starbucks | Expenses:Coffee

    To allow setting a category with only an AccountFilter, use `*` as the entire pattern to match against any field value:

        # Without an account filter all transactions will match!
        [AccountFilter] any_matchable_field | * | new_category

    To use regex alternation (matching either of several values), enclose the
    pattern in forward slashes:

        payee | /Starbucks|Dunkin/ | Expenses:Coffee

    To match a literal pipe character in the data, escape it with a backslash:

- `source` — keep the original Tiller category unchanged.
- `blank` — emit no category field in the QIF output.
- `skip` — exclude the transaction from QIF output entirely (useful for
suppressing the credit-side of card payments that appear in both accounts).

For double-entry programs such as GnuCash, destination is a full account name
(e.g. `Expenses:Groceries`).  For single-entry programs such as Quicken it is
a category name.

The optional `default` line sets the fallback for transactions that match no
rule.  It must appear as the last non-comment line:

    default | source

If the `default` line is omitted, unmatched transactions behave as
`default | source`.

## EXAMPLES

- Map by category

        category | Groceries | Expenses:Groceries

- Map by payee with alternation (slash-delimited pattern)

        payee | /Starbucks|Dunkin/ | Expenses:Coffee

- Map by payee, scoped to one account

        [Checking] payee | Payroll | Income:Salary

- Scope to multiple accounts using alternation in the account filter

        [Checking|Savings] category | Transfer | skip

- Skip card-payment credits on the card account

        [CapitalOne] category | Transfer | skip

- Match a literal pipe character in a payee name

        payee | Cash\|App | Expenses:Transfers

- Suppress category in QIF (no L field)

        category | Miscellaneous | blank

- Default: leave unmatched transactions with their Tiller category

        default | source

# Advanced Use

You can write SQL scripts or use an interactive sqlite3 client to make changes between steps. For example your Tiller sheet might have an account "Checking", while your table of accounts has "Assets::Current Assets::Bank::Checking". With custom SQL you can keep the short name in Tiller even though mapping rules can't rename accounts.

The `--beforemap` and `--aftermap` options allow SQL scripts to run immediately before
and after the map phase without having to break the workflow into separate commands.
This is the preferred way to preprocess or post-process transactions when using `run`,
or `map` as a single step.

The `preview` command is meant to be run between map and emit. You may run the steps individually (ingest, map, preview, emit), or use the --confirm option to run preview before emit (including run).

While other CSV export sources are not directly supported, you can write a script to remap the fields for ingestion or just import into the table, and then use the map and emit stages to complete your export. If translating other CSV sources be aware that Tiller currently only provides it's data in the US 'MM/DD/YYYY' format, this program can also accept dates in ISO 8601 'YYYY-MM-DD'. Data is written into the SQLite database using the ISO 8601 format.

# PROGRAMMATIC USE

`Finance::Tiller2QIF` is primarily a CLI tool; the public functions exist to
support the command dispatcher. Programmatic users will likely use this module
as example code and call the sub-modules directly (`Finance::Tiller2QIF::ReadCSV`,
`Finance::Tiller2QIF::Map`, `Finance::Tiller2QIF::WriteQIF`).

Note that all functions expect `db_path` as the database parameter. The CLI
normalises the `--db` option to `db_path` internally; programmatic callers
should use `db_path` directly.

# AUTHOR

John Karr <brainbuz@cpan.org>

# LICENSE

GPL version 3 or later.
