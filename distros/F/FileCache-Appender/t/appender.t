use Test::Most;
use Test::FailWarnings;
use FileCache::Appender;

use Path::Tiny;

my $dir = Path::Tiny->tempdir;
my $appender = FileCache::Appender->new( max_open => 2 );

for my $num ( 1 .. 3 ) {
    for my $file (qw(aa bb cc dd)) {
        my $fh = $appender->file( path( $dir, $file ) );
        ok $fh, "Got file handler for $file";
        $fh->syswrite("$num\n");
    }
}

for my $file (qw(aa bb cc dd)) {
    my $path = path( $dir, $file );
    my $content = $path->slurp;
    is $content, "1\n2\n3\n", "File $file contains expected data";
}

dies_ok {
    $appender->file( path( $dir, "subdir", "file" ) );
}
"Failed to open file in non-existing directory";

ok !-e path( $dir, "subdir" ), "didn't create directory";

subtest "with mkpath parameter" => sub {
    my $mkpath = FileCache::Appender->new( mkpath => 1 );
    my $fh = $mkpath->file( path( $dir, "sub", "dir", "file" ) );
    ok $fh, "returned file handle for path with new directories";
    ok -d path( $dir, "sub", "dir" ), "created subdirectories";
    ok -f path( $dir, "sub", "dir", "file" ), "created file";
    my $curdir = Path::Tiny->cwd;
    chdir $dir;
    $fh = $mkpath->file("boo");
    ok $fh, "got file handle for file without path";
    chdir $curdir;
    my $fh2 = $mkpath->file( path( $dir, "boo" )->absolute );
    is $fh, $fh2, "got the same file handle when specified absolute path";
};

done_testing;
