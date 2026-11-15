use v5.36;
use Test2::V0;
use Test2::Plugin::NoWarnings;

# Ekorn::Pipeline::Sources: from_array, from_fh, from_file and counter
# (roadmap 2026-0016). Slurping and I/O layers are in t/15-proofs.t too.

use File::Temp qw(tempdir);
use Ekorn::Pipeline;
use Ekorn::Pipeline::Sources qw(:all);
use Ekorn::Pipeline::Stages::Flow;

my $class = 'Ekorn::Pipeline';
my $file  = __FILE__;
my $dir   = tempdir(CLEANUP => 1);

# Return every value a pipeline of the stages given gives, from $source.
sub read_all ($source, @stages) {
    return $class->new(@stages)->iterator($source)->all;
}


# Write $content to a new file in the test's directory, returning its path.
sub file_of ($name, $content) {
    my $path = "$dir/$name";
    open my $fh, '>', $path or die "Can't write $path: $!\n";
    print { $fh } $content;
    close $fh or die "Can't close $path: $!\n";
    return $path;
}

subtest 'Nothing is exported by default' => sub {

    package My::Plain {
        use Ekorn::Pipeline::Sources;
    }
    ok !My::Plain->can($_), "not $_"
        for qw(from_array from_fh from_file counter);
};

subtest 'from_array: the values given, from the first, each run' => sub {
    my $source = from_array('a', undef, 0, 'b');
    is [read_all($source)],          ['a', undef, 0, 'b'], 'undef and 0 included';
    is [read_all($source, take(1))], ['a'];
    is [read_all($source)],          ['a', undef, 0, 'b'], 'and again';
    is [read_all(from_array())],     [],                   'none, given none';
};

subtest 'from_fh: a filehandle\'s records, left open' => sub {
    my $text = "one\ntwo\nthree\n";
    open my $fh, '<', \$text or die "Can't read a string: $!\n";
    is [read_all(from_fh($fh), take(2))], ['one', 'two'], 'each chomped';
    ok defined fileno($fh) || tell($fh) >= 0, 'still open';
    is [read_all(from_fh($fh))], ['three'], 'a run reading on from the last';

    my $slurped = "a\nb\n";
    open my $whole, '<', \$slurped or die "Can't read a string: $!\n";
    {
        local $/;
        is [read_all(from_fh($whole))], ["a\nb\n"], 'slurped, with $/ undefined';
    }
    my $empty = '';
    open my $none, '<', \$empty or die "Can't read a string: $!\n";
    {
        local $/;
        is [read_all(from_fh($none))], [], 'and an empty one gives none';
    }

    my $line = __LINE__ + 1;
    is dies { from_fh('not a handle') },
        "Expected an open filehandle at $file line $line.\n",
        'anything else croaks, at the caller\'s line';
    close $fh;
    like dies { from_fh($fh) }, qr( \A Expected\ an\ open\ filehandle\  )x,
        'and so does a closed one';
};

subtest 'from_file: a file\'s records, opened and closed each run' => sub {
    my $path = file_of('lines.txt', "one\ntwo\nthree\n");
    is [read_all(from_file($path))], ['one', 'two', 'three'];
    is [read_all(from_file($path), take(1))], ['one'], 'stopped';

    my $paras = file_of('paras.txt', "a\nb\n\nc\n");
    {
        local $/ = '';
        is [read_all(from_file($paras))], ["a\nb", "c"],
            'by paragraph, with $/ empty';
    }

    my $missing = "$dir/missing.txt";
    my $source  = from_file($missing);
    my $line    = __LINE__ + 1;
    like dies { $class->new->iterator($source) },
        qr( \A Can't\ read\ \Q$missing\E:\ .+\ at\ \Q$file\E\ line\ $line\.\n \z )x,
        'one that can\'t be opened croaks as the run starts';
};

subtest 'counter: on, without end' => sub {
    is [read_all(counter(), take(3))], [1, 2, 3], '1, 2, 3 by default';
    is [read_all(counter(10, -5), take(3))], [10, 5, 0],
        'from a start, by a step';
    is [read_all(counter(0.5, 0.25), take(3))], [0.5, 0.75, 1],
        'of any numbers';
    my $source = counter(7);
    read_all($source, take(2));
    is [read_all($source, take(1))], [7], 'each run from the start';

    my $line = __LINE__ + 1;
    is dies { counter('x') },
        "Expected a number to start from, and one to step by at $file line $line.\n",
        'anything else croaks';
    like dies { counter(1, 'y') }, qr( \A Expected\ a\ number )x, 'a step too';
};

done_testing;
