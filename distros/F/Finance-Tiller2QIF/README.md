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

Runtime: Cpanel::JSON::XS, DateTime::Format::Flexible, DBD::SQLite, DBI,
Getopt::Long::Descriptive, Path::Tiny, Text::CSV

Testing: Capture::Tiny, Test2::V0, Test2::Bundle::More, Test2::Tools::Exception

### On Debian/Ubuntu:

All of Tiller2QIF’s dependencies are available through package management if you need to install to system Perl on Debian 13 or Ubuntu 26.04 or later.

    sudo apt install libpath-tiny-perl libtext-csv-perl libtest2-suite-perl libcapture-tiny-perl \
      libdbi-perl libdbd-sqlite3-perl libgetopt-long-descriptive-perl \
      libcpanel-json-xs-perl libdatetime-format-flexible-perl
    sudo cpan install Finance::Tiller2QIF

### On Windows

tiller2qif works with Strawberry Perl, after installing Strawberry Perl, install from CPAN.

# CLI COMMANDS

The command word may be given either before or after the options; any other stray argument on the command line is an error.

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

        # read the preview in an editor or pager instead of the terminal
        tiller2qif preview --db tiller.sqlite3 --viewer less

        # and open the mapping file beside it
        tiller2qif preview --db tiller.sqlite3 --mapfile tiller.mapping \
                           --viewer 'code --wait' --multipreview

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
      "viewer":       "console",
      "verbose":      false,
      "checkpoint":   false,
      "confirm":      false,
      "multipreview": false
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
confirmation before writing the QIF file. When used with `--checkpoint`, adds
a revert option (press `r`) to restore the database to its checkpoint state,
useful if you want to undo changes made during ingest or mapping.
- **--viewer** Program used to display preview output. The default, `console`, prints the preview to STDOUT. Any other value names an external program, and may include arguments, for example `less`, `gedit`, or `code --wait`. The value is split on whitespace — first word the program, the rest arguments — so the program's own path cannot contain spaces; point `--viewer` at a wrapper script or a symlink if yours does. The preview is written to a read-only temporary file named `tiller2qif-preview-*.t2qpv`, the program is launched with that file as its argument, and the path is printed so you can find or reopen it. The temporary file is left in place, because graphical editors typically fork and return immediately; ask them to wait (`code --wait`) when you want the export prompt to appear only after you close the preview. A viewer that cannot be found, fails to launch, is killed by a signal, or exits non-zero is a fatal error rather than a fall back to the console. In a config file the key is `viewer`.
- **--multipreview** Open the mapping file in the preview viewer alongside the preview itself, so you can read the pending transactions and edit the rules that produced them side by side. Both files are passed to a single invocation of the viewer. This requires `--viewer` and `--mapfile`; asking for it with the console viewer or without a mapping file is an error rather than a silent no-op. In a config file the key is `multipreview`.
- **--verbose** Print detailed progress information during each phase.  Also
runs `checkconfig` automatically before any operations begin.
- **--version** Print the installed version number and exit.

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

        payee | Cash\|App Payment | Expenses:Transfers

    Patterns are Perl regular expressions, so escape other regex metacharacters
    when they should be literal (`.`, `*`, `+`, the question mark, `(`, `)`,
    `[`, `]`, `$`, `^`, `\`, or `/` in a slash-delimited pattern). Apostrophes
    have no special meaning and do not need escaping:

        payee | /^kaplan's new model$/ | Expenses:Food

    More complex regular expressions are supported when a simple pattern is not
    enough. For example, this matches Kaplan, Kaplan's, or Kaplans followed by
    “New” and an optional “Model”:

        payee | /kaplan(?:'s|s)? new(?: model)?/ | Expenses:Bakeries

    Test complex patterns carefully, to make sure they are interpreted as expected.

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

# VS CODE EXTENSION

The repository includes a Visual Studio Code extension, `vscode-tiller-map/`, which highlights mapping files and preview files and completes destination account names from your chart of accounts. It is not published to the Marketplace, it can only be installed from a checkout of the repository.

With **--viewer code** and **--multipreview** the actions **preview** and **run** will open the preview and map file in vscode

## Installation

    git clone https://github.com/brainbuz/tiller2qif
    cp -r tiller2qif/vscode-tiller-map ~/.vscode/extensions/
    # or, to track the checkout:
    ln -s "$PWD/tiller2qif/vscode-tiller-map" ~/.vscode/extensions/

Reload VS Code afterwards.

## Syntax Highlighting

Files with `.map` and `.mapping` extensions are recognized as mappings, preview files have the `t2qpv` extension.

## Completion Hinting

In addition to completion of Tiller2QIF keywords you can also configure your Chart of Accounts for Completion! The extension's settings `tiller2qifMap.coaPath` and `tiller2qifMap.coaFormat` control this. Currently the only available coaFormat is `gnucash-csv`.

## Row Colors

`tiller2qifMap.rowColors` controls row backgrounds in both file types. `rainbow`, the default, gives rows a repeating series of subtle background colors; `none` turns backgrounds off. A preview transaction occupies two lines, both receive the same color.

# Advanced Use

You can write SQL scripts or use an interactive sqlite3 client to make changes between steps. For example your Tiller sheet might have an account "Checking", while your table of accounts has "Assets::Current Assets::Bank::Checking". With custom SQL you can keep the short name in Tiller even though mapping rules can't rename accounts.

The `--beforemap` and `--aftermap` options allow SQL scripts to run immediately before
and after the map phase without having to break the workflow into separate commands.
This is the preferred way to preprocess or post-process transactions when using `run`,
or `map` as a single step.

The `preview` command is meant to be run between map and emit. You may run the steps individually (ingest, map, preview, emit), or use the `--confirm` option to run preview before emit (including run). The preview table is wide, so `--viewer` is often more comfortable than the terminal; combined with `--confirm` it lets you read the pending transactions in an editor or pager and then answer the export prompt.

When using `--confirm` with `--checkpoint`, three choices Y=Yes N=No R=Revert are offered. No keeps the database state while not completing the export, Revert restores the database to the checkpoint in addition to aborting.

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
