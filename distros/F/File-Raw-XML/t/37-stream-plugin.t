#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use File::Raw qw(slurp);
use File::Raw::XML qw(:all);

# The plugin's stream phase: a synthetic file of a hundred megabytes
# streamed record by record with each_line($path, $cb, plugin => 'xml',
# record => [$ns, $local]), the resident size read before and after with
# the Proc::ProcessTable gate t/15 uses, and the records counted. A flat
# resident size is the whole point of the phase: the file is a thousand
# times the memory the stream is allowed to grow by.
#
# The records are counted and checked whether or not that module is
# installed; only the resident-size assertion needs it, and it skips by
# name so a run without it says which coverage it did not get.

my $HAVE_PT = eval {
    require Proc::ProcessTable;
    my $t = Proc::ProcessTable->new(enable_ttys => 0);
    grep { $_ eq 'rss' } $t->fields or die "no rss field\n";
    1;
};

my $PT = $HAVE_PT ? Proc::ProcessTable->new(enable_ttys => 0) : undef;

sub _rss_raw {
    return undef unless $PT;
    for my $p (@{ $PT->table }) {
        return $p->rss if $p->pid == $$;
    }
    return undef;
}

# Proc::ProcessTable's rss is bytes on some platforms and KiB on others -
# darwin reports KiB, matching ps -o rss= exactly - and the module
# documents neither, because the field is filled by per-platform XS. So
# the unit is measured, not assumed: assuming the wrong one would scale
# the gate below by 1024 and it would still say PASS.
my $RSS_IS_KIB = 1;
if ($PT) {
    my $before = _rss_raw() // 0;
    my $blob   = 'x' x (32 * 1024 * 1024);
    substr($blob, 0, 1) = 'y';               # touch it, so it is resident
    my $moved  = (_rss_raw() // 0) - $before;
    $RSS_IS_KIB = $moved > 4 * 1024 * 1024 ? 0 : 1;
}

sub rss_kb {
    my $r = _rss_raw();
    return undef unless defined $r;
    return $RSS_IS_KIB ? $r : int($r / 1024);
}

my $MB   = $ENV{FRX_STREAM_MB} || 100;
my $dir  = tempdir(CLEANUP => 1);
my $path = "$dir/big.xml";

# ~120 bytes a record; the file is written in one pass and never held
{
    open my $fh, '>:raw', $path or die "$path: $!";
    print {$fh} qq{<?xml version="1.0"?>\n<log xmlns="urn:log" xmlns:m="urn:meta">\n};
    my $i = 0;
    my $written = 0;
    my $target = $MB * 1024 * 1024;
    while ($written < $target) {
        $i++;
        my $rec = qq{  <Record id="$i" m:kind="event"><name>record $i</name><body>} . ('x' x 60) . qq{</body></Record>\n};
        print {$fh} $rec;
        $written += length $rec;
    }
    print {$fh} "</log>\n";
    close $fh;
    ok(-s $path >= $target, "a $MB MiB file of $i records");
    $main::RECORDS = $i;
}

# a first, short run warms every allocator so the gate measures the stream
my ($seen, $last_id, $bad) = (0, 0, 0);
my $ok = eval {
    File::Raw::each_line($path, sub {
        my ($doc) = @_;
        $seen++;
        my $id = $doc->root->attr('id');
        $bad++ unless $id == $seen && $doc->root->ns eq 'urn:log';
        $last_id = $id;
        if ($seen == 1) {
            is($doc->root->c14n, '<Record xmlns="urn:log" xmlns:m="urn:meta" id="1" m:kind="event"><name>record 1</name><body>' . ('x' x 60) . '</body></Record>',
               'the first record canonicalises with the in-scope namespaces carried in');
        }
        die "stop\n" if $seen == 1000;
    }, plugin => 'xml', record => ['urn:log', 'Record']);
    1;
};
is($@, "stop\n", 'a die in the callback ends the stream and comes out of each_line');
is($seen, 1000, 'after a thousand records of warm-up');

$seen = 0; $bad = 0;
my $before = rss_kb() // 0;
eval {
    File::Raw::each_line($path, sub {
        my ($doc) = @_;
        $seen++;
        $bad++ unless $doc->root->attr('id') == $seen;
    }, plugin => 'xml', record => ['urn:log', 'Record']);
    1;
} or diag("stream died: $@");
my $after = rss_kb() // 0;
is($seen, $main::RECORDS, "every record was emitted ($seen)");
is($bad, 0, 'each with its own id, in order');
my $growth = $after - $before;
SKIP: {
    skip 'Proc::ProcessTable is not installed; resident size is not gated', 1
        unless $HAVE_PT;
    cmp_ok($growth, '<=', 8 * 1024, "the resident size stayed flat over $MB MiB (grew ${growth} KiB)");
}

# the option's shape, and the refusals
{
    ok(!eval { File::Raw::each_line($path, sub { }, plugin => 'xml'); 1 }, 'the stream phase needs record');
    like($@, qr/streams records: pass record => \[\$ns, \$local\]/, 'and says so');
    ok(!eval { file_xml_decode('<a/>', record => ['', 'a']); 1 }, 'record is not an option of the codec');
    like($@, qr/record is an option of the xml plugin's stream phase/, 'saying to use each_line');
    my @seen;
    eval { File::Raw::each_line($path, sub { push @seen, $_[0]->root->local; die "enough\n" if @seen == 2 }, plugin => 'xml', record => [undef, 'name']) };
    is_deeply(\@seen, ['name', 'name'], 'undef for the namespace matches any; a nested element is a record too');
    ok(!eval { File::Raw::each_line($path, sub { }, plugin => 'xml', record => ['urn:log', 'Record'], profile => 'sideways'); 1 }, 'the reader\'s options are checked');
    unlink $path;
}

done_testing;
