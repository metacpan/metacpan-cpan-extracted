use Test::More;

use Hazy;
use lib '.';

subtest 'process' => sub {
    my $new_dir = sprintf "meh/%s", int( rand(10000000) );
    mkdir $new_dir;

    Hazy->new(
        read_dir  => 'hazy',
        write_dir => $new_dir,
        file_name => 'testing',
        find      => 'meh',
    )->process();

    my $file = sprintf "t/%s/testing.min.css", $new_dir;
    open my $after, "<", $file;
    my $content = do { local $/; <$after> };
    close $after;

    my $expected_css = '.foo{color:#eee;font-size:10px}.thing{color:#fff;font-size:10px}';
    is( $content, $expected_css, "expected output - $expected_html" );

    unlink (sprintf "t/%s/testing.css", $new_dir);
    unlink $file;
    rmdir "t/$new_dir";
    rmdir "t/meh";
};

done_testing();
