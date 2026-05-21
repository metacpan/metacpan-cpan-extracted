use strict;
use warnings;
use utf8;
use warnings FATAL => 'utf8';
use open ':std', ':encoding(UTF-8)';
use Test2::V0;
use Test2::Bundle::More;
use Test2::Tools::Exception qw/dies lives/;
use Path::Tiny;
use Finance::Tiller2QIF::Map;
use Finance::Tiller2QIF::ReadCSV;
use Finance::Tiller2QIF::Util;
use Finance::Tiller2QIF::WriteQIF;
use Mojo::SQLite;
use feature qw/signatures postderef/;

require './t/TestHelper.pm';

# ---------------------------------------------------------------------------
# pipe_variants — comprehensive coverage of all three pattern forms:
#   1. Simple pattern (no pipe)
#   2. Escaped literal pipe (\|)
#   3. Slash-delimited alternation (/pattern|pattern/)
#   4. Slash-delimited with literal pipe inside (/pattern\|pattern|other/)
#
# Rule ordering: more specific (longer) literal patterns must precede shorter
# ones because matching is substring-based. Anchors (^ and $) are used to
# prevent shorter literals from matching longer payee strings.
# ---------------------------------------------------------------------------

subtest pipe_variants => sub {
  my $dbfile  = uniqfile( 'map_pipevar', 'sqlite3' );
  my $csvfile = uniqfile( 'map_pipevar', 'csv' );
  my $mapfile = uniqfile( 'map_pipevar', 'map' );
  my $db      = freshdb($dbfile);

  # Payees are designed so each transaction reaches exactly one rule.
  # id=1: exact literal "Alpha|Beta"         — should hit rule: ^Alpha\|Beta$
  # id=2: plain word "Alpha"                 — should hit rule: /Alpha|Beta/
  # id=3: exact literal "Alpha|Beta|Gamma"   — should hit rule: ^Alpha\|Beta\|Gamma$
  # id=4: exact literal "Alpha|Beta" again   — confirms rule 1 still applies
  # id=5: "Gamma" alone                      — reaches /Alpha|Beta|Gamma/ not /Alpha|Beta/
  # id=6: literal "Alpha|Beta" in alternation — hits /Alpha\|Beta|Delta/
  freshcsv( $csvfile,
    '04/25/2026,1,Checking,5.00,Alpha|Beta,Alpha|Beta,Test',
    '04/25/2026,2,Checking,5.00,Alpha,Alpha,Test',
    '04/25/2026,3,Checking,5.00,Alpha|Beta|Gamma,Alpha|Beta|Gamma,Test',
    '04/25/2026,4,Checking,5.00,Alpha|Beta,Alpha|Beta,Test',
    '04/25/2026,5,Checking,5.00,Gamma,Gamma,Test',
    '04/25/2026,6,Checking,5.00,Delta,Delta,Test',
  );

  # Rules ordered most-specific first to prevent shorter literals
  # from stealing matches intended for longer ones.
  freshmap( $mapfile,
    # Anchored multi-literal must precede single-literal
    'payee | ^Alpha\|Beta\|Gamma$ | Pipe:MultiLiteral',
    # Anchored single-literal
    'payee | ^Alpha\|Beta$        | Pipe:Literal',
    # Slash-delimited alternation — "Alpha" or "Beta"
    'payee | /Alpha|Beta/         | Pipe:Regex',
    # Slash-delimited multi-alternation — must precede two-token rule
    'payee | /Alpha|Beta|Gamma/   | Pipe:MultiRegex',
    # Slash-delimited with literal pipe inside alternation
    # matches literal "Alpha|Beta" OR "Delta"
    'payee | /Alpha\|Beta|Delta/  | Pipe:AltWithLiteral',
    'default | source',
  );

  Finance::Tiller2QIF::ReadCSV::Ingest( $csvfile, $dbfile );
  Finance::Tiller2QIF::Map::Map({db_path => $dbfile, mapfile => $mapfile});

  my %tx = map { $_->{id} => $_->{mapped_category} }
    $db->select( 'transactions', [qw(id mapped_category)] )->hashes->@*;

  is( $tx{1}, 'Pipe:Literal',        'Anchored literal ^Alpha\|Beta$ matches exact payee' );
  is( $tx{2}, 'Pipe:Regex',          'Slash alternation /Alpha|Beta/ matches plain word' );
  is( $tx{3}, 'Pipe:MultiLiteral',   'Anchored multi-literal ^Alpha\|Beta\|Gamma$ matches exact payee' );
  is( $tx{4}, 'Pipe:Literal',        'Anchored literal matches second occurrence of same payee' );
  is( $tx{5}, 'Pipe:MultiRegex',     '"Gamma" reaches /Alpha|Beta|Gamma/ after /Alpha|Beta/ misses' );
  is( $tx{6}, 'Pipe:AltWithLiteral', '"Delta" matches second branch of /Alpha\|Beta|Delta/, confirming \| inside slashes is literal pipe' );

  my $qiffile = uniqfile( 'map_pipevar', 'qif' );
  Finance::Tiller2QIF::WriteQIF::Emit( $dbfile, $qiffile );
  my $qif = path($qiffile)->slurp_utf8;

  like( $qif, qr/LPipe:Literal/,        'QIF contains Pipe:Literal' );
  like( $qif, qr/LPipe:Regex/,          'QIF contains Pipe:Regex' );
  like( $qif, qr/LPipe:MultiLiteral/,   'QIF contains Pipe:MultiLiteral' );
  like( $qif, qr/LPipe:MultiRegex/,     'QIF contains Pipe:MultiRegex' );
  like( $qif, qr/LPipe:AltWithLiteral/, 'QIF contains Pipe:AltWithLiteral' );

  $db->disconnect;
};

# ---------------------------------------------------------------------------
# account_filter_alternation — [A|B] restricts a rule to named accounts
# ---------------------------------------------------------------------------

subtest account_filter_alternation => sub {
  my $dbfile  = uniqfile( 'edge_acctalt', 'sqlite3' );
  my $csvfile = uniqfile( 'edge_acctalt', 'csv' );
  my $mapfile = uniqfile( 'edge_acctalt', 'map' );
  my $db      = freshdb($dbfile);
  freshcsv( $csvfile,
    '04/25/2026,1,Checking,10.00,Coffee,Cafe,Food',
    '04/25/2026,2,Savings,10.00,Coffee,Cafe,Food',
    '04/25/2026,3,Brokerage,10.00,Coffee,Cafe,Food',
  );
  freshmap( $mapfile,
    '[Checking|Savings] category | Food | Expenses:Food',
    'default | source',
  );
  Finance::Tiller2QIF::ReadCSV::Ingest( $csvfile, $dbfile );
  Finance::Tiller2QIF::Map::Map({db_path => $dbfile, mapfile => $mapfile});
  my %tx = map { $_->{id} => $_->{mapped_category} }
    $db->select( 'transactions', [qw(id mapped_category)] )->hashes->@*;
  is( $tx{1}, 'Expenses:Food', 'Checking matches alternation filter' );
  is( $tx{2}, 'Expenses:Food', 'Savings matches alternation filter' );
  is( $tx{3}, undef,           'Brokerage not in filter, falls to default source' );
  $db->disconnect;
};

# ---------------------------------------------------------------------------
# null_field_value — NULL or empty field skips the rule entirely; a field
# that is present but non-matching falls through to the default.
# ---------------------------------------------------------------------------

subtest null_field_value => sub {
  my $dbfile  = uniqfile( 'edge_null', 'sqlite3' );
  my $csvfile = uniqfile( 'edge_null', 'csv' );
  my $mapfile = uniqfile( 'edge_null', 'map' );
  my $db      = freshdb($dbfile);
  # id=1: Full Description = "OtherMemo" — present but does not match "Cafe"
  # id=2: Full Description = ""          — empty memo, rule is skipped
  freshcsv( $csvfile,
    '04/25/2026,1,Checking,10.00,Coffee,OtherMemo,Food',
    '04/25/2026,2,Checking,20.00,Coffee,,Food',
  );
  freshmap( $mapfile,
    'memo | Cafe | Expenses:Dining',
    'default | source',
  );
  Finance::Tiller2QIF::ReadCSV::Ingest( $csvfile, $dbfile );
  Finance::Tiller2QIF::Map::Map({db_path => $dbfile, mapfile => $mapfile});
  my %tx = map { $_->{id} => $_->{mapped_category} }
    $db->select( 'transactions', [qw(id mapped_category)] )->hashes->@*;
  is( $tx{1}, undef, 'Non-matching memo leaves mapped_category NULL' );
  is( $tx{2}, undef, 'Empty memo does not match rule, mapped_category stays NULL' );
  $db->disconnect;
};

# ---------------------------------------------------------------------------
# omitted_account_filter — rule without brackets matches all accounts
# ---------------------------------------------------------------------------

subtest omitted_account_filter => sub {
  my $dbfile  = uniqfile( 'edge_noacct', 'sqlite3' );
  my $csvfile = uniqfile( 'edge_noacct', 'csv' );
  my $mapfile = uniqfile( 'edge_noacct', 'map' );
  my $db      = freshdb($dbfile);
  freshcsv( $csvfile,
    '04/25/2026,1,Checking,10.00,Coffee,Cafe,Food',
    '04/25/2026,2,Savings,10.00,Coffee,Cafe,Food',
  );
  freshmap( $mapfile,
    'category | Food | Expenses:Food',
    'default | source',
  );
  Finance::Tiller2QIF::ReadCSV::Ingest( $csvfile, $dbfile );
  Finance::Tiller2QIF::Map::Map({db_path => $dbfile, mapfile => $mapfile});
  my %tx = map { $_->{id} => $_->{mapped_category} }
    $db->select( 'transactions', [qw(id mapped_category)] )->hashes->@*;
  is( $tx{1}, 'Expenses:Food', 'Omitted account filter matches Checking' );
  is( $tx{2}, 'Expenses:Food', 'Omitted account filter matches Savings' );
  $db->disconnect;
};

# ---------------------------------------------------------------------------
# rule_order — first matching rule wins; later rules are not evaluated
# ---------------------------------------------------------------------------

subtest rule_order => sub {
  my $dbfile  = uniqfile( 'edge_order', 'sqlite3' );
  my $csvfile = uniqfile( 'edge_order', 'csv' );
  my $mapfile = uniqfile( 'edge_order', 'map' );
  my $db      = freshdb($dbfile);
  freshcsv( $csvfile,
    '04/25/2026,1,Checking,10.00,Coffee,Cafe,Food',
  );
  freshmap( $mapfile,
    'category | Food | Expenses:First',
    'category | ^Food$ | Expenses:Second',
    'default | source',
  );
  Finance::Tiller2QIF::ReadCSV::Ingest( $csvfile, $dbfile );
  Finance::Tiller2QIF::Map::Map({db_path => $dbfile, mapfile => $mapfile});
  my $tx = $db->select( 'transactions', ['mapped_category'], { id => 1 } )->hash;
  is( $tx->{mapped_category}, 'Expenses:First', 'First matching rule wins, second rule never evaluated' );
  $db->disconnect;
};

# ---------------------------------------------------------------------------
# mapping_file_errors — invalid map file contents die at parse time
# ---------------------------------------------------------------------------

subtest mapping_file_errors => sub {
  my $dbfile  = uniqfile( 'map_err', 'sqlite3' );
  my $mapfile = uniqfile( 'map_err', 'map' );
  freshdb($dbfile);

  freshmap( $mapfile, 'badfield | foo | bar' );
  ok( dies { Finance::Tiller2QIF::Map::Map({db_path => $dbfile, mapfile => $mapfile}) },
    'Unknown field name dies' );

  freshmap( $mapfile, 'category | [unclosed | dest' );
  ok( dies { Finance::Tiller2QIF::Map::Map({db_path => $dbfile, mapfile => $mapfile}) },
    'Invalid regex in pattern dies' );

  freshmap( $mapfile, '[Checking category | Food | Expenses:Food' );
  ok( dies { Finance::Tiller2QIF::Map::Map({db_path => $dbfile, mapfile => $mapfile}) },
    'Unclosed account filter bracket dies' );

  freshmap( $mapfile, 'payee | Alpha|Beta | Expenses:Dining' );
  ok( dies { Finance::Tiller2QIF::Map::Map({db_path => $dbfile, mapfile => $mapfile}) },
    'Bare alternation without slash-quoting dies' );
};

done_testing();

unlink glob "t/tmp/t2q_*" if test_pass();
