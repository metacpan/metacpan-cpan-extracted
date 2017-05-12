use strict;
use warnings;

use Test::More;
use File::Temp;
use File::Path;

use Devel::Mutator::Command::Test;

subtest 'returns 0 on success' => sub {
    my $dir = File::Temp->newdir(CLEANUP => 1);

    _write_file("$dir/lib/foo.pm", 'print 1 + 1');
    _write_file("$dir/mutants/abcde/lib/foo.pm", 'print 1 - 1');
    _write_file("$dir/t/00.t", 'use Test::More; ok(0); done_testing;');

    my $command = _build_command(root => $dir, command => "cd $dir; prove -l t");
    is $command->run, 0;
};

subtest 'returns 255 on failure' => sub {
    my $dir = File::Temp->newdir(CLEANUP => 1);

    _write_file("$dir/lib/foo.pm", 'print 1 + 1');
    _write_file("$dir/mutants/abcde/lib/foo.pm", 'print 1 - 1');
    _write_file("$dir/t/00.t", 'use Test::More; ok(1); done_testing;');

    my $command = _build_command(root => $dir, command => "cd $dir; prove -l t");
    is $command->run, 255;
};

subtest 'reverts original code' => sub {
    my $dir = File::Temp->newdir(CLEANUP => 1);

    _write_file("$dir/lib/foo.pm", 'print 1 + 1');
    _write_file("$dir/mutants/abcde/lib/foo.pm", 'print 1 - 1');
    _write_file("$dir/t/00.t", 'use Test::More; ok(0); done_testing;');

    my $command = _build_command(root => $dir, command => "cd $dir; prove -l t");
    $command->run;

    like _slurp_file("$dir/lib/foo.pm"), qr/print 1 \+ 1/;
};

subtest 'removes killed mutations' => sub {
    my $dir = File::Temp->newdir(CLEANUP => 1);

    _write_file("$dir/lib/foo.pm", 'print 1 + 1');
    _write_file("$dir/mutants/abcde/lib/foo.pm", 'print 1 - 1');
    _write_file("$dir/t/00.t", 'use Test::More; ok(0); done_testing;');

    my $command = _build_command(
        root    => $dir,
        remove  => 1,
        command => "cd $dir; prove -l t"
    );
    $command->run;

    ok !-d "$dir/mutants/abcde";
};

sub _write_file {
    my ($file, $content) = @_;

    File::Path::make_path(File::Basename::dirname($file));

    open my $fh, '>', $file;
    print $fh $content;
    close $fh;
}

sub _slurp_file {
    my ($file) = @_;

    return do { local $/; open my $fh, '<', $file; <$fh> };
}

sub _build_command {
    Devel::Mutator::Command::Test->new(@_);
}

done_testing;
