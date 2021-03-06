
use ETL::Yertl 'Test';
use YAML::Tiny;
use Capture::Tiny qw( capture );
use File::Spec;
my $SHARE_DIR = path( __DIR__, '..', 'share' );

my $script = "$FindBin::Bin/../../bin/yq";
require $script;
$0 = $script; # So pod2usage finds the right file

subtest 'help options' => sub {
    my ( $out, $err, $exit ) = capture { yq::main( 'yq', '-h' ) };
    is $exit, 0, 'successfully showed the help';
    ok !$err, 'requested help is on stdout';
    like $out, qr{Usage:}, 'synopsis is included';
    like $out, qr{Arguments:}, 'arguments are included';
    like $out, qr{Options:}, 'options are included';
};

subtest 'must provide a filter' => sub {
    my ( $out, $err, $exit ) = capture { yq::main() };
    is $exit, 2, 'fatal error';
    ok !$out, 'errors are on stderr';
    like $err, qr{ERROR: Must give a filter};
    like $err, qr{Usage:};
};

subtest 'empty does not print' => sub {
    local *STDIN = $SHARE_DIR->child( yaml => 'noseperator.yaml' )->openr;
    my $filter = 'if .foo eq bar then .foo else empty';
    my ( $output, $stderr ) = capture { yq::main( 'yq', $filter ) };
    ok !$stderr, 'stderr is empty' or diag "STDERR: $stderr";
    my @got = @{ YAML::Tiny->read_string( $output ) };
    cmp_deeply \@got, [ 'bar' ] or diag explain \@got;
};

subtest 'single document with no --- separator' => sub {
    local *STDIN = $SHARE_DIR->child( yaml => 'noseperator.yaml' )->openr;
    my $filter = '.flip.[0]';
    my ( $output, $stderr ) = capture { yq::main( 'yq', $filter ) };
    ok !$stderr, 'stderr is empty' or diag "STDERR: $stderr";
    my @got = @{ YAML::Tiny->read_string( $output ) };
    cmp_deeply \@got, [ 'flop' ] or diag explain \@got;
};

subtest 'file in ARGV' => sub {
    my $file = $SHARE_DIR->child( yaml => 'foo.yaml' );
    my $filter = '.foo';
    my ( $output, $stderr ) = capture { yq::main( 'yq', $filter, "$file" ) };
    ok !$stderr, 'stderr is empty' or diag "STDERR: $stderr";
    my @got = @{ YAML::Tiny->read_string( $output ) };
    cmp_deeply \@got, [ 'bar' ] or diag explain \@got;

    subtest 'multiple files with no seperators' => sub {
        my $file = $SHARE_DIR->child( yaml => 'noseperator.yaml' );
        my $filter = '.foo';
        my ( $output, $stderr ) = capture { yq::main( 'yq', $filter, "$file", "$file" ) };
        ok !$stderr, 'stderr is empty' or diag "STDERR: $stderr";
        my @got = @{ YAML::Tiny->read_string( $output ) };
        cmp_deeply \@got, [ 'bar', 'bar' ] or diag explain \@got;
    };
};

subtest 'multiple documents print properly' => sub {
    local *STDIN = $SHARE_DIR->child( yaml => 'noseperator.yaml' )->openr;
    my $filter = '.foo, .baz';
    my ( $output, $stderr ) = capture { yq::main( 'yq', $filter ) };
    ok !$stderr, 'stderr is empty' or diag "STDERR: $stderr";
    my @got = @{ YAML::Tiny->read_string( $output ) };
    cmp_deeply \@got, [ 'bar', 'buzz' ] or diag explain \@got;
};

subtest 'finish() gets called' => sub {
    local *STDIN = $SHARE_DIR->child( yaml => 'group_by.yaml' )->openr;
    my $filter = 'group_by( .foo )';
    my ( $output, $stderr ) = capture { yq::main( 'yq', $filter ) };
    ok !$stderr, 'stderr is empty' or diag "STDERR: $stderr";
    my @got = docs_from_string( $output );

    cmp_deeply \@got, [
        {
            bar => [
                {
                    foo => 'bar',
                    baz => 1,
                },
                {
                    foo => 'bar',
                    baz => 2,
                },
            ],
            baz => [
                {
                    foo => 'baz',
                    baz => 3,
                },
            ],
        },
    ] or diag explain \@got;
};

subtest 'xargs (-x) output' => sub {
    local *STDIN = $SHARE_DIR->child( yaml => 'noseperator.yaml' )->openr;
    my $filter = '.foo, .baz';
    my ( $output, $stderr ) = capture { yq::main( 'yq', $filter, "-x" ) };
    ok !$stderr, 'stderr is empty' or diag "STDERR: $stderr";
    eq_or_diff $output, "bar\nbuzz\n";

    subtest 'missing fields' => sub {
        local *STDIN = $SHARE_DIR->child( yaml => 'group_by.yaml' )->openr;
        my $filter = '.foo, .bar, .baz';
        my ( $output, $stderr ) = capture { yq::main( 'yq', $filter, "-x" ) };
        ok !$stderr, 'stderr is empty' or diag "STDERR: $stderr";
        eq_or_diff $output, "bar\n1\nbar\n2\nbaz\n3\n";
    };
};

subtest 'version check' => sub {
    local $yq::VERSION = '1.00';
    my ( $output, $stderr, $exit ) = capture { yq::main( 'yq', '--version' ) };
    is $exit, 0;
    ok !$stderr, 'stderr is empty' or diag "STDERR: $stderr";
    is $output, "yq version 1.00 (Perl $^V)\n";
};

done_testing;
