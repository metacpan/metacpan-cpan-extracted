use strict;
use warnings;
use utf8;
use warnings FATAL => 'utf8';
use open ':std', ':encoding(UTF-8)';
use Test2::V0;
use Test2::Bundle::More;
use Path::Tiny;
use Mojo::SQLite;
use Finance::Tiller2QIF::ReadCSV;
use Finance::Tiller2QIF::Map;
use Finance::Tiller2QIF::WriteQIF;
use Finance::Tiller2QIF::Util;
use feature qw/signatures postderef/;

require './t/TestHelper.pm';

subtest csv_payee_with_unicode => sub {
  my $csvfile = uniqfile( 'mojibake_payee', 'csv' );
  my $dbfile  = uniqfile( 'mojibake_payee', 'sqlite3' );

  freshcsv( $csvfile,
    '04/25/2026,1,Checking,10.00,café,Café visit,Expenses:Food',
    '04/25/2026,2,Checking,20.00,Привет,Russian greeting,Expenses:Utilities',
    '04/25/2026,3,Checking,30.00,你好,Chinese hello,Expenses:Entertainment',
    '04/25/2026,4,Checking,40.00,🎉Party,Party time,Expenses:Dining',
  );

  my $db = freshdb($dbfile);
  Finance::Tiller2QIF::ReadCSV::Ingest( $csvfile, $dbfile );

  my $rows = $db->select( 'transactions' )->hashes();
  is( scalar(@$rows), 4, '4 transactions loaded' );
  is( $rows->[0]{payee}, 'café', 'café payee preserved' );
  is( $rows->[1]{payee}, 'Привет', 'Cyrillic payee preserved' );
  is( $rows->[2]{payee}, '你好', 'Chinese payee preserved' );
  is( $rows->[3]{payee}, '🎉Party', 'Emoji payee preserved' );

  $db->disconnect;
};

subtest csv_memo_with_unicode => sub {
  my $csvfile = uniqfile( 'mojibake_memo', 'csv' );
  my $dbfile  = uniqfile( 'mojibake_memo', 'sqlite3' );

  freshcsv( $csvfile,
    '04/25/2026,1,Checking,10.00,Test,café résumé,Expenses:Food',
    '04/25/2026,2,Checking,20.00,Test,Привет Мир,Expenses:Utilities',
    '04/25/2026,3,Checking,30.00,Test,你好 🌍,Expenses:Entertainment',
  );

  my $db = freshdb($dbfile);
  Finance::Tiller2QIF::ReadCSV::Ingest( $csvfile, $dbfile );

  my $rows = $db->select( 'transactions' )->hashes();
  is( $rows->[0]{memo}, 'café résumé', 'Unicode in memo preserved' );
  is( $rows->[1]{memo}, 'Привет Мир', 'Cyrillic in memo preserved' );
  is( $rows->[2]{memo}, '你好 🌍', 'Mixed Unicode in memo preserved' );

  $db->disconnect;
};

subtest mapping_rules_with_unicode_patterns => sub {
  my $mapfile = uniqfile( 'mojibake_map', 'map' );
  my $dbfile  = uniqfile( 'mojibake_map', 'sqlite3' );
  my $csvfile = uniqfile( 'mojibake_map', 'csv' );

  freshmap( $mapfile,
    '# Test mapping with Unicode patterns',
    'payee | café | Expenses:Coffee',
    'payee | Привет | Expenses:Russian',
    'payee | /你好|世界/ | Expenses:Chinese',
    'payee | 🎉Party | Expenses:Celebration',
  );

  freshcsv( $csvfile,
    '04/25/2026,1,Checking,10.00,café,Coffee,Expenses:Other',
    '04/25/2026,2,Checking,20.00,Привет,Greeting,Expenses:Other',
    '04/25/2026,3,Checking,30.00,你好,Hello,Expenses:Other',
    '04/25/2026,4,Checking,40.00,🎉Party,Party,Expenses:Other',
  );

  my $db = freshdb($dbfile);
  Finance::Tiller2QIF::ReadCSV::Ingest( $csvfile, $dbfile );
  Finance::Tiller2QIF::Map::Map({db_path => $dbfile, mapfile => $mapfile});

  my $rows = $db->select( 'transactions' )->hashes();
  is( $rows->[0]{mapped_category}, 'Expenses:Coffee', 'café pattern matched' );
  is( $rows->[1]{mapped_category}, 'Expenses:Russian', 'Cyrillic pattern matched' );
  is( $rows->[2]{mapped_category}, 'Expenses:Chinese', 'Chinese regex matched' );
  is( $rows->[3]{mapped_category}, 'Expenses:Celebration', 'Emoji pattern matched' );

  $db->disconnect;
};

subtest mapping_destination_with_unicode => sub {
  my $mapfile = uniqfile( 'mojibake_dest', 'map' );
  my $dbfile  = uniqfile( 'mojibake_dest', 'sqlite3' );
  my $csvfile = uniqfile( 'mojibake_dest', 'csv' );

  freshmap( $mapfile,
    'payee | Test1 | Expenses:Café',
    'payee | Test2 | Expenses:Русский',
    'payee | Test3 | Expenses:中文',
    'payee | Test4 | Expenses:🎉',
  );

  freshcsv( $csvfile,
    '04/25/2026,1,Checking,10.00,Test1,Coffee,Expenses:Other',
    '04/25/2026,2,Checking,20.00,Test2,Greeting,Expenses:Other',
    '04/25/2026,3,Checking,30.00,Test3,Hello,Expenses:Other',
    '04/25/2026,4,Checking,40.00,Test4,Party,Expenses:Other',
  );

  my $db = freshdb($dbfile);
  Finance::Tiller2QIF::ReadCSV::Ingest( $csvfile, $dbfile );
  Finance::Tiller2QIF::Map::Map({db_path => $dbfile, mapfile => $mapfile});

  my $rows = $db->select( 'transactions' )->hashes();
  is( $rows->[0]{mapped_category}, 'Expenses:Café', 'Unicode destination café' );
  is( $rows->[1]{mapped_category}, 'Expenses:Русский', 'Unicode destination Russian' );
  is( $rows->[2]{mapped_category}, 'Expenses:中文', 'Unicode destination Chinese' );
  is( $rows->[3]{mapped_category}, 'Expenses:🎉', 'Unicode destination emoji' );

  $db->disconnect;
};

subtest qif_output_with_unicode => sub {
  my $qiffile = uniqfile( 'mojibake_qif', 'qif' );
  my $dbfile  = uniqfile( 'mojibake_qif', 'sqlite3' );
  my $csvfile = uniqfile( 'mojibake_qif', 'csv' );

  freshcsv( $csvfile,
    '04/25/2026,1,Checking,10.00,café ☕,résumé test,Expenses:Food',
    '04/25/2026,2,Checking,20.00,Привет,Русский мир,Expenses:Utilities',
    '04/25/2026,3,Checking,30.00,你好世界,中文标签,Expenses:Entertainment',
  );

  my $db = freshdb($dbfile);
  Finance::Tiller2QIF::ReadCSV::Ingest( $csvfile, $dbfile );
  Finance::Tiller2QIF::WriteQIF::Emit( $dbfile, $qiffile );

  my $qif_content = path($qiffile)->slurp_utf8;
  ok( $qif_content =~ /café/, 'café in QIF output' );
  ok( $qif_content =~ /☕/, 'coffee emoji in QIF output' );
  ok( $qif_content =~ /Привет/, 'Cyrillic in QIF output' );
  ok( $qif_content =~ /你好世界/, 'Chinese in QIF output' );
  ok( $qif_content =~ /résumé/, 'Accented characters in QIF output' );

  $db->disconnect;
};

subtest account_filter_with_unicode => sub {
  my $mapfile = uniqfile( 'mojibake_acct', 'map' );
  my $dbfile  = uniqfile( 'mojibake_acct', 'sqlite3' );
  my $csvfile = uniqfile( 'mojibake_acct', 'csv' );

  freshmap( $mapfile,
    '[Chequing|支票|Checking] payee | Test | Expenses:Matched',
  );

  freshcsv( $csvfile,
    '04/25/2026,1,Checking,10.00,Test,Coffee,Expenses:Other',
    '04/25/2026,2,Savings,20.00,Test,Tea,Expenses:Other',
    '04/25/2026,3,支票,30.00,Test,Greeting,Expenses:Other',
  );

  my $db = freshdb($dbfile);
  Finance::Tiller2QIF::ReadCSV::Ingest( $csvfile, $dbfile );
  Finance::Tiller2QIF::Map::Map({db_path => $dbfile, mapfile => $mapfile});

  my $rows = $db->select( 'transactions', '*', {}, { order_by => 'id' } )->hashes();
  is( $rows->[0]{mapped_category}, 'Expenses:Matched', 'Checking account matched' );
  is( $rows->[1]{mapped_category}, undef, 'Savings account not matched' );
  is( $rows->[2]{mapped_category}, 'Expenses:Matched', 'Chinese account name matched' );

  $db->disconnect;
};

subtest literal_pipe_with_unicode => sub {
  my $mapfile = uniqfile( 'mojibake_pipe', 'map' );
  my $dbfile  = uniqfile( 'mojibake_pipe', 'sqlite3' );
  my $csvfile = uniqfile( 'mojibake_pipe', 'csv' );

  freshmap( $mapfile,
    'payee | café\|bar | Expenses:Café\|Bar',
    'payee | /世界\|地球|地球\|世界/ | Expenses:Chinese',
  );

  freshcsv( $csvfile,
    '04/25/2026,1,Checking,10.00,café|bar,Coffee,Expenses:Other',
    '04/25/2026,2,Checking,20.00,世界|地球,Hello,Expenses:Other',
  );

  my $db = freshdb($dbfile);
  Finance::Tiller2QIF::ReadCSV::Ingest( $csvfile, $dbfile );
  Finance::Tiller2QIF::Map::Map({db_path => $dbfile, mapfile => $mapfile});

  my $rows = $db->select( 'transactions' )->hashes();
  is( $rows->[0]{mapped_category}, 'Expenses:Café|Bar', 'café|bar literal pipe preserved' );
  is( $rows->[1]{mapped_category}, 'Expenses:Chinese', 'Chinese alternation matched' );

  $db->disconnect;
};

subtest mixed_unicode_roundtrip => sub {
  my $mapfile = uniqfile( 'mojibake_roundtrip', 'map' );
  my $qiffile = uniqfile( 'mojibake_roundtrip', 'qif' );
  my $dbfile  = uniqfile( 'mojibake_roundtrip', 'sqlite3' );
  my $csvfile = uniqfile( 'mojibake_roundtrip', 'csv' );

  my $complex_payee = 'International 🌍: café (Привет) [你好]';
  my $complex_memo  = 'εξοδα путешествия 旅費';

  freshcsv( $csvfile,
    "04/25/2026,1,Checking,99.99,$complex_payee,$complex_memo,Expenses:Other",
  );

  freshmap( $mapfile,
    'payee | International | Expenses:Travel 旅行:Café',
  );

  my $db = freshdb($dbfile);
  Finance::Tiller2QIF::ReadCSV::Ingest( $csvfile, $dbfile );
  Finance::Tiller2QIF::Map::Map({db_path => $dbfile, mapfile => $mapfile});

  my $rows = $db->select( 'transactions' )->hashes();
  my $row = $rows->[0];
  is( $row->{payee}, $complex_payee, 'Complex payee preserved through pipeline' );
  is( $row->{mapped_category}, 'Expenses:Travel 旅行:Café', 'Complex category mapped' );
  is( $row->{memo}, $complex_memo, 'Complex memo preserved' );

  Finance::Tiller2QIF::WriteQIF::Emit( $dbfile, $qiffile );
  my $qif = path($qiffile)->slurp_utf8;
  ok( $qif =~ /\Q$complex_payee\E/, 'Complex payee in QIF' );
  ok( $qif =~ /Expenses:Travel 旅行:Café/, 'Complex category in QIF' );

  $db->disconnect;
};

subtest hebrew_arabic_complete_pipeline => sub {
  # Two data lines with Hebrew/Arabic, one mapping rule that matches one line
  my $csvfile = uniqfile( 'mojibake_hebrew_complete', 'csv' );
  my $dbfile  = uniqfile( 'mojibake_hebrew_complete', 'sqlite3' );
  my $mapfile = uniqfile( 'mojibake_hebrew_complete', 'map' );
  my $qiffile = uniqfile( 'mojibake_hebrew_complete', 'qif' );

  # Hebrew account and payee names
  my $hebrew_account = 'חשבון בדיקה';
  my $hebrew_payee1 = 'סופר מרקט';
  my $hebrew_payee2 = 'מכוניות דלק';
  my $hebrew_category = 'הוצאות:קניות';
  my $arabic_description = 'خضار وفواكه';

  # Create CSV with Hebrew text
  freshcsv( $csvfile,
    "04/25/2026,1,$hebrew_account,50.00,$hebrew_payee1,$arabic_description,הוצאות:מאכל",
    "04/25/2026,2,$hebrew_account,40.00,$hebrew_payee2,דלק רגיל,הוצאות:תחבורה",
  );

  # Create map that matches first payee and converts to Hebrew destination
  freshmap( $mapfile,
    "payee | $hebrew_payee1 | $hebrew_category",
  );

  # Process: ingest CSV, apply map, emit QIF
  my $db = freshdb($dbfile);
  Finance::Tiller2QIF::ReadCSV::Ingest( $csvfile, $dbfile );

  my $rows = $db->select( 'transactions' )->hashes();
  is( scalar(@$rows), 2, '2 transactions loaded with Hebrew account names' );
  is( $rows->[0]{payee}, $hebrew_payee1, "Hebrew payee '$hebrew_payee1' preserved" );
  is( $rows->[0]{memo}, $arabic_description, "Arabic description '$arabic_description' preserved" );
  is( $rows->[1]{payee}, $hebrew_payee2, "Hebrew payee '$hebrew_payee2' preserved" );

  # Apply mapping
  Finance::Tiller2QIF::Map::Map({db_path => $dbfile, mapfile => $mapfile});

  $rows = $db->select( 'transactions' )->hashes();
  is( $rows->[0]{mapped_category}, $hebrew_category, "Row 1: Hebrew payee mapped to Hebrew category '$hebrew_category'" );
  is( $rows->[1]{mapped_category}, undef, 'Row 2: Hebrew payee with no matching rule stays unmapped' );

  # Emit QIF
  Finance::Tiller2QIF::WriteQIF::Emit( $dbfile, $qiffile );

  my $qif = path($qiffile)->slurp_utf8;
  ok( $qif =~ /\Q$hebrew_account\E/, "Hebrew account '$hebrew_account' in QIF" );
  ok( $qif =~ /\Q$hebrew_payee1\E/, "Hebrew payee '$hebrew_payee1' in QIF" );
  ok( $qif =~ /\Q$hebrew_category\E/, "Hebrew destination category '$hebrew_category' in QIF" );
  ok( $qif =~ /\Q$arabic_description\E/, "Arabic description '$arabic_description' in QIF" );

  $db->disconnect;
};

subtest config_file_with_hebrew_arabic => sub {
  use Cpanel::JSON::XS;

  my $configfile = uniqfile( 'mojibake_config', 'json' );

  # Config with Hebrew keys and Arabic values (right-to-left text stress test)
  my $config = {
    input   => 'בדיקה_עסקאות.csv',              # Hebrew: "test_transactions.csv"
    output  => 'ייצוא_qif.qif',                  # Hebrew: "export_qif.qif"
    db      => 'טעינת_נתונים.sqlite3',          # Hebrew: "load_data.sqlite3"
    mapfile => 'מיפוי_קטגוריות.map',            # Hebrew: "category_mapping.map"
    metadata => {
      user        => 'דוד כהן',                  # Hebrew name
      description => 'تحويل معاملات تيلر',      # Arabic: "Convert Tiller transactions"
      location    => 'القاهرة، مصر',            # Arabic: "Cairo, Egypt"
      note        => 'קובץ הגדרות משותף',       # Hebrew: "shared config file"
    }
  };

  # Write config to JSON
  path($configfile)->spew_utf8( Cpanel::JSON::XS->new->utf8->encode($config) );

  # Read and deserialize config
  my $loaded = Cpanel::JSON::XS->new->utf8->decode( path($configfile)->slurp_utf8 );

  # Verify Hebrew values preserved
  is( $loaded->{input}, 'בדיקה_עסקאות.csv', 'Hebrew input path in config preserved' );
  is( $loaded->{output}, 'ייצוא_qif.qif', 'Hebrew output path in config preserved' );
  is( $loaded->{db}, 'טעינת_נתונים.sqlite3', 'Hebrew db path in config preserved' );
  is( $loaded->{mapfile}, 'מיפוי_קטגוריות.map', 'Hebrew mapfile path in config preserved' );

  # Verify Arabic metadata preserved
  is( $loaded->{metadata}{user}, 'דוד כהן', 'Hebrew user name in config preserved' );
  is( $loaded->{metadata}{description}, 'تحويل معاملات تيلر', 'Arabic description in config preserved' );
  is( $loaded->{metadata}{location}, 'القاهرة، مصر', 'Arabic location in config preserved' );
  is( $loaded->{metadata}{note}, 'קובץ הגדרות משותף', 'Hebrew note in config preserved' );

  # Verify JSON content can be read back and deserialized correctly
  # Note: Right-to-left languages (Hebrew/Arabic) may be escaped in JSON but
  # the round-trip through serialization/deserialization must preserve the values
  my $json_content = path($configfile)->slurp_utf8;
  ok( length($json_content) > 0, 'JSON config file created' );

  # The critical test: values survive the round-trip, not the JSON encoding format
  is( $loaded->{metadata}{description}, 'تحويل معاملات تيلر', 'Arabic survives JSON round-trip' );
  is( $loaded->{metadata}{location}, 'القاهرة، مصر', 'Arabic with diacritics survives JSON round-trip' );
};

done_testing();
unlink glob "t/tmp/*" if test_pass();
