use strict;
use warnings;
use utf8;
use Test::More;

use Mackerel::ReleaseUtils qw/replace/;
use Path::Tiny ();

subtest dirglob => sub {
    my @files;
    replace 't/testdata/*/file1' => sub {
        my ($content, $file) = @_;
        push @files, $file;
        $content;
    };
    is_deeply [sort @files], [qw{t/testdata/dir1/file1 t/testdata/dir2/file1}];
};

subtest fileglob => sub {
    my @files;
    replace 't/testdata/dir1/file*' => sub {
        my ($content, $file) = @_;
        push @files, $file;
        $content;
    };
    is_deeply [sort @files], [qw{t/testdata/dir1/file1 t/testdata/dir1/file2}];
};

subtest 'keep permission' => sub {
    my $temp = Path::Tiny->tempfile;
    my $content = "aaa\nbbb\nccc\n";
    $temp->spew($content);
    $temp->chmod(0755);

    replace $temp.q() => sub {
        my $content = shift;
        $content . "ddd\n";
    };
    is $temp->slurp_utf8, $content . "ddd\n";
    ok -x $temp;
};

done_testing;
