use strict;
use warnings;

use Test::More;
use File::Temp;

use Devel::Mutator::Command::Mutate;

subtest 'creates mutants' => sub {
    my $dir = File::Temp->newdir(CLEANUP => 1);

    _write_file("$dir/foo.pm", 'print 1 + 1');

    my $command = _build_command(root => $dir);
    $command->run("$dir/foo.pm");

    ok -d "$dir/mutants";
    ok -d "$dir/mutants/0fae63c0f5b0fe3dcf214d7a1d9a8145";
    ok -f "$dir/mutants/0fae63c0f5b0fe3dcf214d7a1d9a8145/$dir/foo.pm";
};

subtest 'creates mutants recursively' => sub {
    my $dir = File::Temp->newdir(CLEANUP => 1);

    _write_file("$dir/foo.pm", 'print 1 + 1');

    my $command = _build_command(root => $dir, recursive => 1);
    $command->run($dir);

    ok -d "$dir/mutants";
    ok -d "$dir/mutants/0fae63c0f5b0fe3dcf214d7a1d9a8145";
    ok -f "$dir/mutants/0fae63c0f5b0fe3dcf214d7a1d9a8145/$dir/foo.pm";
};

sub _write_file {
    my ($file, $content) = @_;

    open my $fh, '>', $file;
    print $fh $content;
    close $fh;
}

sub _build_command {
    Devel::Mutator::Command::Mutate->new(@_);
}

done_testing;
