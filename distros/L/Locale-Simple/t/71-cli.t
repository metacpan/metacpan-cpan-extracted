use strict;
use warnings;
use utf8;
use Test::More;
use Test::InDistDir;
use Capture::Tiny 'capture';
use File::pushd;
use File::Temp 'tempdir';
use JSON::PP 'decode_json';
use Path::Tiny;
use Locale::Simple::CLI;
use Locale::Simple::PO2JSON qw( po2data data2json );

my $po = 't/data/locale/de_DE/LC_MESSAGES/test.po';
my ( $out, $err, $rc );

( $out, $err, $rc ) = capture { Locale::Simple::CLI::run( 'po2json', '--domain', 'myapp', $po ) };
is $rc, 0, 'po2json exits 0';
is_deeply [ keys %{ decode_json($out) } ], ['myapp'], '--domain names the bundle';

( $out, undef, $rc ) = capture { Locale::Simple::CLI::run( 'po2json', $po ) };
ok exists decode_json($out)->{test}, 'domain from file name';
is $out, path('t/data/po2json/test.domain.json')->slurp_raw, 'JS fixture is current';

( $out, undef, $rc ) = capture { Locale::Simple::CLI::run( 'po2json', '--pretty', $po ) };
like $out, qr/\n   /, '--pretty indents';

( $out, undef, $rc ) = capture { Locale::Simple::CLI::run('--version') };
is $rc, 0, '--version exits 0';
like $out, qr/^locale-simple \d+\.\d+\n\z/, '--version text';

for my $h (qw( help --help -h )) {
    ( $out, undef, $rc ) = capture { Locale::Simple::CLI::run($h) };
    is $rc, 0, "$h exits 0";
    like $out, qr/Usage/, "$h prints usage on STDOUT";
}

( undef, $err, $rc ) = capture { Locale::Simple::CLI::run('frobnicate') };
is $rc, 2, 'unknown command exits 2';
like $err, qr/Usage/, 'usage on STDERR';
( undef, $err, $rc ) = capture { Locale::Simple::CLI::run() };
is $rc, 2, 'no command exits 2';

( undef, $err, $rc ) = capture { Locale::Simple::CLI::run( 'po2json', 'nope.po' ) };
is $rc, 1, 'unreadable PO exits 1';
like $err, qr/Cannot read PO file/, 'message on STDERR';
( undef, $err, $rc ) = capture { Locale::Simple::CLI::run('po2json') };
is $rc, 2, 'po2json without file exits 2';

{
    my $g = pushd('t/data/n-fixtures');
    ( $out, undef, $rc ) = capture { Locale::Simple::CLI::run( 'scrape', '--only', 'N-calls\.pl' ) };
    is $rc, 0, 'scrape exits 0';
    like $out, qr/^msgid "/m, 'scrape prints a template';
}
{
    my $g = pushd( tempdir( CLEANUP => 1 ) );
    ( $out, undef, $rc ) = capture { Locale::Simple::CLI::run('scrape') };
    is $rc, 0, 'scrape in an empty dir exits 0';
    is $out, '', 'empty dir, empty output';
}

for my $h (qw( --help -h )) {
    ( $out, $err, $rc ) = capture { Locale::Simple::CLI::run( 'scrape', $h ) };
    is $rc, 0, "scrape $h exits 0";
    like $out, qr/Usage: locale-simple scrape.*--output FORMAT/s, "scrape $h prints the options on STDOUT";
    is $err, '', "scrape $h writes nothing to STDERR";
}
for my $bad ( [ '--bogus' ], [ '--output', 'xml' ], [ 'stray' ] ) {
    my $g = pushd('t/data/n-fixtures');
    ( $out, $err, $rc ) = capture { Locale::Simple::CLI::run( 'scrape', @{$bad} ) };
    is $rc, 2, "scrape @{$bad} exits 2";
    like $err, qr/Usage: locale-simple scrape/, "scrape @{$bad}: usage on STDERR";
    is $out, '', "scrape @{$bad}: nothing on STDOUT";
}
( undef, $err, $rc ) = capture { Locale::Simple::CLI::run( 'scrape', '--output', 'xml' ) };
like $err, qr/Unknown output format: xml/, 'the reason is named';

( $out, $err ) = capture { system $^X, '-Ilib', 'bin/locale_simple_scraper', '--bogus' };
is $? >> 8, 2, 'bin/locale_simple_scraper --bogus exits 2';
like $err, qr/Unknown option: bogus.*Usage: locale-simple scrape/s, 'bin/locale_simple_scraper --bogus: usage on STDERR';
is $out, '', 'bin/locale_simple_scraper --bogus: nothing on STDOUT';
( $out ) = capture { system $^X, '-Ilib', 'bin/locale_simple_scraper', '--help' };
is $? >> 8, 0, 'bin/locale_simple_scraper --help exits 0';
like $out, qr/Usage: locale-simple scrape/, 'bin/locale_simple_scraper --help prints the options';

( $out, undef, $rc ) = capture { system $^X, '-Ilib', 'bin/po2json', $po };
is $out, data2json( po2data($po) ) . "\n", 'bin/po2json keeps its shape';
( $out, undef, $rc ) = capture { system $^X, '-Ilib', 'bin/po2json', '-p', $po };
is $out, data2json( po2data( $po, domain => 'test' ), pretty => 1 ) . "\n", 'bin/po2json -p';
( $out, undef, $rc ) = capture { system $^X, '-Ilib', 'bin/po2json', '-h' };
is $? >> 8, 1, 'bin/po2json -h exits 1';
( undef, $err ) = capture { system $^X, '-Ilib', 'bin/po2json', 'nope.po' };
is $? >> 8, 1, 'bin/po2json unreadable exits 1';
like $err, qr/Cannot read PO file/, 'bin/po2json message';

( $out, undef, $rc ) = capture { system $^X, '-I' . path('lib')->absolute, path('bin/locale-simple')->absolute, '--version' };
like $out, qr/^locale-simple /, 'bin/locale-simple runs';

# --- deprecation notices of the two legacy commands
my $n_scraper = "locale_simple_scraper is deprecated, use: locale-simple scrape\n";
my $n_pretty  = "po2json is deprecated, use: locale-simple po2json --pretty FILE.po\n";
my $n_plain   = "po2json is deprecated, use: locale-simple po2json FILE.po (no exact equivalent: it wraps the data as { \"FILE\": ... })\n";
my $run = sub {
    my ( $script, @args ) = @_;
    my ( $o, $e ) = capture { system $^X, '-Ilib', "bin/$script", @args };
    return ( $o, $e, $? >> 8 );
};
my $notice_count = sub { my ( $e, $n ) = @_; my $c = () = $e =~ /\Q$n\E/g; $c };

{
    my ( $lib, $bin ) = ( path('lib')->absolute, path('bin/locale_simple_scraper')->absolute );
    my $g = pushd('t/data/n-fixtures');
    my ( $o, $e ) = capture { system $^X, "-I$lib", $bin, '--only', 'N-calls\.pl' };
    my $x = $? >> 8;
    is $x, 0, 'bin/locale_simple_scraper run exits 0';
    like $o, qr/^msgid "/m, 'bin/locale_simple_scraper run still prints the template';
    unlike $o, qr/deprecated/, 'bin/locale_simple_scraper run: no notice on STDOUT';
    is( ( split /^/, $e )[0], $n_scraper, 'bin/locale_simple_scraper run: the notice is the first STDERR line' );
    is $notice_count->( $e, $n_scraper ), 1, 'bin/locale_simple_scraper run: the notice appears once';
}
for my $args ( [ '--help' ], [ '--bogus' ] ) {
    ( $out, $err, $rc ) = $run->( 'locale_simple_scraper', @{$args} );
    is( ( split /^/, $err )[0], $n_scraper, "bin/locale_simple_scraper @{$args}: the notice is the first STDERR line" );
    is $notice_count->( $err, $n_scraper ), 1, "bin/locale_simple_scraper @{$args}: the notice appears once";
    unlike $out, qr/deprecated/, "bin/locale_simple_scraper @{$args}: no notice on STDOUT";
}
like $err, qr/Unknown option: bogus.*Usage: locale-simple scrape/s, 'bin/locale_simple_scraper --bogus: the usage follows the notice';

( $out, $err, $rc ) = $run->( 'po2json', $po );
is $rc, 0, 'bin/po2json FILE exits 0';
is( ( split /^/, $err )[0], $n_plain, 'bin/po2json FILE: the plain notice is the first STDERR line' );
is $err, $n_plain, 'bin/po2json FILE: the notice is all of STDERR, once';
unlike $out, qr/deprecated/, 'bin/po2json FILE: no notice on STDOUT';
ok eval { decode_json($out); 1 }, 'bin/po2json FILE: STDOUT is still JSON';
is $out, data2json( po2data($po) ) . "\n", 'bin/po2json FILE: STDOUT unchanged';

( $out, $err, $rc ) = $run->( 'po2json', '-p', $po );
my $pretty_out = $out;
is $rc, 0, 'bin/po2json -p FILE exits 0';
is $err, $n_pretty, 'bin/po2json -p FILE: the --pretty notice is all of STDERR, once';
ok eval { decode_json($out); 1 }, 'bin/po2json -p FILE: STDOUT is still JSON';
is $out, data2json( po2data( $po, domain => 'test' ), pretty => 1 ) . "\n", 'bin/po2json -p FILE: STDOUT unchanged';
( my $new_pretty ) = capture { Locale::Simple::CLI::run( 'po2json', '--pretty', $po ) };
is $pretty_out, $new_pretty, 'po2json -p FILE and locale-simple po2json --pretty FILE write the same bytes';

( $out, $err, $rc ) = $run->( 'po2json', '-p', '-h' );
is $rc, 1, 'bin/po2json -p -h exits 1';
is( ( split /^/, $err )[0], $n_pretty, 'bin/po2json -p -h: the --pretty notice comes first' );
is $notice_count->( $err, $n_pretty ), 1, 'bin/po2json -p -h: the notice appears once';

for my $args ( [ '-h' ], [ '--help' ], [], [ $po, $po ], [ 'nope.po' ] ) {
    my $name = join ' ', 'bin/po2json', @{$args} ? map { $_ eq $po ? 'FILE' : $_ } @{$args} : '(no args)';
    ( $out, $err, $rc ) = $run->( 'po2json', @{$args} );
    is $rc, 1, "$name exits 1";
    is( ( split /^/, $err )[0], $n_plain, "$name: the plain notice is the first STDERR line" );
    is $notice_count->( $err, $n_plain ), 1, "$name: the notice appears once";
    is $notice_count->( $err, $n_pretty ), 0, "$name: no --pretty notice";
    unlike $out, qr/deprecated/, "$name: no notice on STDOUT";
}
like $err, qr/Cannot read PO file/, 'bin/po2json nope.po: the reason follows the notice';

# the new command is silent about deprecation
( undef, $err ) = capture { Locale::Simple::CLI::run( 'po2json', $po ) };
unlike $err, qr/deprecated/i, 'run(po2json) prints no deprecation notice';
( undef, $err ) = capture { Locale::Simple::CLI::run( 'po2json', '--pretty', $po ) };
unlike $err, qr/deprecated/i, 'run(po2json --pretty) prints no deprecation notice';
( undef, $err ) = capture { Locale::Simple::CLI::run( 'scrape', '--help' ) };
unlike $err, qr/deprecated/i, 'run(scrape --help) prints no deprecation notice';
{
    my $g = pushd('t/data/n-fixtures');
    ( undef, $err ) = capture { Locale::Simple::CLI::run( 'scrape', '--only', 'N-calls\.pl' ) };
    unlike $err, qr/deprecated/i, 'run(scrape) prints no deprecation notice';
}
my $cmd = sub { my @a = @_; capture { system $^X, '-I' . path('lib')->absolute, path('bin/locale-simple')->absolute, @a } };
( undef, $err ) = $cmd->( 'scrape', '--help' );
unlike $err, qr/deprecated/i, 'bin/locale-simple scrape --help prints no deprecation notice';
( $out, $err ) = $cmd->( 'po2json', $po );
unlike $err, qr/deprecated/i, 'bin/locale-simple po2json FILE prints no deprecation notice';
ok exists decode_json($out)->{test}, 'bin/locale-simple po2json FILE still writes the data';

{
    my $g = pushd('t/data/n-fixtures');
    ( $out, undef, $rc ) = capture { Locale::Simple::CLI::run( 'scrape', '--output', 'json', '--only', 'N-calls\.pl' ) };
    is ref decode_json($out), 'ARRAY', 'scrape json is an array';
    SKIP: {
        skip 'YAML not installed', 1 unless eval { require YAML; 1 };
        ( $out, undef, $rc ) = capture { Locale::Simple::CLI::run( 'scrape', '--output', 'yaml', '--only', 'N-calls\.pl' ) };
        like $out, qr/^---/, 'scrape yaml';
    }
}

{
    my $g = pushd('t/data/utf8-fixtures');
    ( $out, undef, $rc ) = capture { Locale::Simple::CLI::run( 'scrape', '--output', 'json' ) };
    my $found = JSON::PP->new->utf8->decode($out);
    is $found->[0]{msgid}, "Größe", 'scrape json is valid UTF-8 and decodes to the msgid';
}

{
    local @INC = ( sub { die "YAML.pm blocked\n" if $_[1] eq 'YAML.pm'; return }, @INC );
    local %INC = %INC;
    delete $INC{'YAML.pm'};
    my $g = pushd('t/data/n-fixtures');
    ( $out, $err, $rc ) = capture { Locale::Simple::CLI::run( 'scrape', '--output', 'yaml', '--only', 'N-calls\.pl' ) };
    is $rc, 1, 'scrape exits 1 when the scraper dies';
    like $err, qr/--output yaml needs the YAML module/, 'message on STDERR';
    is $out, '', 'nothing on STDOUT';
}

# --- scrape --output perl is byte-stable: the keys of every entry are sorted,
# whatever Perl's hash order is. The entries are compared as text, not eval'd.
{
    my @seeds = ( 1 .. 6 );
    my $lib   = path('lib')->absolute;
    my $bin   = path('bin/locale-simple')->absolute;
    my $with_seed = sub {
        my ( $seed, @cmd ) = @_;
        local $ENV{PERL_HASH_SEED}    = $seed;
        return scalar capture { system $^X, @cmd };
    };

    # precondition: these seeds really do change Perl's key order here, so a
    # missing Sortkeys cannot go unnoticed
    my %orders = map { $_ => 1 }
      map { $with_seed->( $_, '-e', 'my %h = map { $_ => 1 } qw( msgid line file type domain msgctxt ); print join ",", keys %h' ) } @seeds;
    cmp_ok scalar keys %orders, '>', 1, 'PERL_HASH_SEED changes the hash order of the test seeds';

    my $g = pushd('t/data/n-fixtures');
    my %out = map { $_ => $with_seed->( $_, "-I$lib", $bin, 'scrape', '--output', 'perl', '--only', 'N-calls\.pl' ) } @seeds;
    like $out{ $seeds[0] }, qr/^\$VAR1 = \[/, 'scrape --output perl prints a Data::Dumper array';
    my %bytes = map { $_ => 1 } values %out;
    is scalar keys %bytes, 1, 'scrape --output perl is byte-identical across PERL_HASH_SEED values';

    my @entries = split /^ {10}\{\n/m, $out{ $seeds[0] };
    shift @entries;
    cmp_ok scalar @entries, '>', 1, 'the fixture yields several entries';
    my $unsorted = grep {
        my @keys = /^ {12}'([^']+)' =>/mg;
        "@keys" ne join ' ', sort @keys;
    } @entries;
    is $unsorted, 0, 'the keys of every entry are sorted';
    ok scalar( grep { ( () = /^ {12}'[^']+' =>/mg ) > 2 } @entries ), 'some entry has several keys, so the order check means something';
}

done_testing;
