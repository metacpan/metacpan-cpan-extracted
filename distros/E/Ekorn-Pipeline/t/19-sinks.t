use v5.36;
use Test2::V0;
use Test2::Plugin::NoWarnings;

# Ekorn::Pipeline::Sinks: the keep family, count_items, to_fh and to_file
# (roadmap 2026-0017). How sinks end a run is in t/15-proofs.t.

use File::Temp qw(tempdir);

# A close that fails when asked, as one does on a full disk, in place of
# Perl's for the code compiled after it, Sinks included.
our $FAIL_CLOSE;


BEGIN {
    *CORE::GLOBAL::close = sub : prototype(;*) ($fh = *ARGV) {
        my $closed = CORE::close($fh);
        return $closed unless $FAIL_CLOSE;
        $! = 28;    # No space left on device
        return 0;
    };
}
use Ekorn::Pipeline;
use Ekorn::Pipeline::Sinks   qw(:all);
use Ekorn::Pipeline::Sources qw(from_array from_file);

my $class = 'Ekorn::Pipeline';
my $file  = __FILE__;
my $dir   = tempdir(CLEANUP => 1);

# Return a source of 1 to $n, counting its pulls into $$pulls.
sub counted ($n, $pulls) {
    my $i = 0;
    return sub () { $$pulls++; $i < $n ? ++$i : () };
}

subtest 'Nothing is exported by default' => sub {

    package My::Plain {
        use Ekorn::Pipeline::Sinks;
    }
    ok !My::Plain->can($_), "not $_"
        for qw(
            keep keep_all count_items keep_first keep_last keep_single to_fh
            to_file);
};

subtest 'keep_all: every item' => sub {
    is [$class->new(keep_all)->(1, 2, 3)], [1, 2, 3], 'as a list';
    is scalar $class->new(keep_all)->(1, 2, 3), [1, 2, 3],
        'as an array reference, asked for one value';
    is scalar $class->new(keep_all)->(), [], 'an empty one, given none';
};

subtest 'keep($n): the first $n items, stopping there' => sub {
    my $pulls = 0;
    is [$class->new(keep(2))->iterator(counted(9, \$pulls))->all], [1, 2];
    is $pulls,                         2,  'reading no more';
    is [$class->new(keep(0))->(1, 2)], [], 'none, for 0';
    my $line = __LINE__ + 1;
    is dies { keep(-1) },
        "Expected a count of 0 or more at $file line $line.\n",
        'croaking at what is not a count';
    like dies { keep(undef) }, qr( \A Expected\ a\ count )x, 'or none';
};

subtest 'keep_first, keep_single and keep_last' => sub {
    my $pulls = 0;
    is scalar $class->new(keep_first)->iterator(counted(9, \$pulls))->(), 1,
        'keep_first: the first';
    is $pulls,                             1,     'reading no more';
    is scalar $class->new(keep_first)->(), undef, 'or undef';

    is scalar $class->new(keep_single)->(7), 7, 'keep_single: the one';
    my @warnings;
    local $SIG{__WARN__} = sub ($warning) { push @warnings, $warning };
    is scalar $class->new(keep_single)->(7, 8, 9), 7, 'the first, at a second';
    like \@warnings,
        [qr( \A Expected\ only\ one\ item,\ but\ there\ were\ more\  )x],
        'with a warning';
    is scalar $class->new(keep_single)->(), undef, 'or undef';

    is scalar $class->new(keep_last)->(1, 2, 3), 3,     'keep_last: the last';
    is scalar $class->new(keep_last)->(),        undef, 'or undef';
};

subtest 'count_items: how many' => sub {
    is scalar $class->new(count_items)->('a', undef, 0), 3,
        'undef and 0 included';
    is scalar $class->new(count_items)->(), 0;
    is prototype(\&count_items), '',
        'with an empty prototype, so + is never its argument';
};

subtest 'to_fh: each item printed, followed by $/' => sub {
    my $text = '';
    open my $fh, '>', \$text or die "Can't write a string: $!\n";
    is scalar $class->new(to_fh($fh))->('a', 'b'), 2, 'giving how many';
    is $text, "a\nb\n",                               'each followed by a newline';
    ok print({$fh} 'c'), 'leaving it open';
    {
        local $/ = '';
        $class->new(to_fh($fh))->('d');
    }
    {
        local $/;
        $class->new(to_fh($fh))->('e');
    }
    is $text, "a\nb\ncd\n\ne",
        'a blank line in paragraph mode; nothing, slurped';

    my $line = __LINE__ + 1;
    is dies { to_fh('not a handle') },
        "Expected an open filehandle at $file line $line.\n",
        'anything else croaks';

    open my $reading, '<', \$text or die "Can't read a string: $!\n";
    my @warnings;
    local $SIG{__WARN__} = sub ($warning) { push @warnings, $warning };
    like dies { $class->new(to_fh($reading))->('x') },
        qr( Can't\ write\ the\ filehandle:\  )x, 'and a handle it cannot write';
};

subtest 'to_file: written through, read back unchanged' => sub {
    my $original = "$dir/original.txt";
    open my $fh, '>', $original or die "Can't write $original: $!\n";
    print { $fh } "one\ntwo\n";
    close $fh or die "Can't close $original: $!\n";

    my $copy = "$dir/copy.txt";
    is scalar $class->new(to_file($copy))->iterator(from_file($original))->(),
        2,
        'giving how many';
    is [$class->new(keep_all)->iterator(from_file($copy))->all], ['one', 'two'],
        'which from_file reads as written';

    my $line = __LINE__ + 1;
    like dies { $class->new(to_file($dir))->('x') },
        qr( \A Can't\ write\ \Q$dir\E:\ .+\ at\ \Q$file\E\ line\ $line\.\n \z )x,
        'a file it cannot open croaks as the run starts';

    local $FAIL_CLOSE = 1;
    like dies { $class->new(to_file($copy))->('x') },
        qr( \A Pipeline\ end\ of\ stage\ \#1\ failed\ .*\n \ +Can't\ write\ \Q$copy\E:\  )xs,
        'and one it cannot close croaks as the run ends';
};

done_testing;
