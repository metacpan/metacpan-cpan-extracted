use v5.36;
use Test2::V0;
use Test2::Plugin::NoWarnings;

# DBIx-Squirrel's documents link to sections of ours on GitHub's main,
# so a heading renamed here sends its readers to the top of the page.
# This keeps each heading it links to, and keeps our index linking the
# names its index uses to the sections it expects, which its own
# xt/reference-index.t checks, but only after we release (roadmap
# 2026-0058). The links are listed here, as of DBIx-Squirrel v4.2.0
# (2026-0058's D2): a release of its that adds or moves one sends us a
# message, and the lists change with it. An author test, as the docs
# aren't in the distribution.

my %DOCS = (
    'docs/REFERENCE.md' => [
        qw(
            csv-ekornpipelinecsv
            delivering-parts-for-ekorn
            gather
            generator-and-yield
            json-ekornpipelinejson
            making-each-kind-of-part
            named-pipelines
            pipe-and-tap-ekornpipelinepipes
            sink_one-and-sink_many
            sinks-ekornpipelinesinks
            source
            sources-ekornpipelinesources
            stage
            the-stop-object
        ),
    ],
    'docs/HOWTO.md' => [
        qw(
            coming-from-dbixsquirrel
            feed-values-in-as-they-arrive
        ),
    ],
);

# The names DBIx-Squirrel's index links to ours, each with the section
# it expects our index to link that name to.
my %INDEX = (
    counter    => 'sources-ekornpipelinesources',
    from_array => 'sources-ekornpipelinesources',
    from_csv   => 'csv-ekornpipelinecsv',
    from_fh    => 'sources-ekornpipelinesources',
    from_file  => 'sources-ekornpipelinesources',
    from_json  => 'json-ekornpipelinejson',
    from_jsonl => 'json-ekornpipelinejson',
    generator  => 'generator-and-yield',
    sink_many  => 'sink_one-and-sink_many',
    source     => 'source',
    stage      => 'stage',
    to_csv     => 'csv-ekornpipelinecsv',
    yield      => 'generator-and-yield',
);

skip_all "the docs aren't here" if grep { !-e } keys %DOCS;

# Return a heading's anchor, as GitHub makes it.
sub anchor ($heading) {
    my $anchor = lc $heading;
    $anchor =~ s( [^\w\-\ ] )()xg;
    $anchor =~ s( \  )(-)xg;
    return $anchor;
}

# Return a document's text, split at its index, if it has one: what
# comes before it, and the index.
sub read_doc ($file) {
    open my $in, '<', $file or die "Can't read $file: $!";
    my $text = do { local $/; <$in> };
    close $in;
    my($body, $index) = $text =~ m( \A (.*?) ^\#\#\ Index\n (.*) \z )xms;
    return defined $body ? ($body, $index) : ($text, '');
}

# Return the anchors of the headings in some text, by anchor. A comment
# in code isn't a heading.
sub anchors ($text) {
    my(%anchors, $in_code);
    for my $line (split m( \n )x, $text) {
        $in_code = !$in_code     if $line =~ m( \A ``` )x;
        next                     if $in_code;
        $anchors{anchor($1)} = 1 if $line =~ m( \A \#+ \  (.+) \z )x;
    }
    return \%anchors;
}

# Return the section each name in an index links to, by name: its first
# listing's, as DBIx-Squirrel's test reads it.
sub index_links ($index) {
    my %link;
    for my $block (split m( (?= ^\#\#\#\#\  ) )xm, $index) {
        my($name, $to)
            = $block
            =~ m( \A \#\#\#\#\ (\S+) \n .*? \s See \s+ \[ [^\]]+ \] \( \# ([^\)]+) \) \. )xs
            or next;
        $link{$name} //= $to;
    }
    return \%link;
}


my $index;
for my $file (sort keys %DOCS) {
    my($body, $doc_index) = read_doc($file);
    $index = $doc_index if $file eq 'docs/REFERENCE.md';

    # A heading in the index doesn't count: #source and #stage are the
    # index's own entries too, but DBIx-Squirrel's links mean the
    # sections above it.
    my $anchors = anchors($body);
    is [grep { !$anchors->{$_} } @{ $DOCS{$file} }], [],
        "$file: has each heading DBIx-Squirrel links to";
}

my $links = index_links($index);
my %got   = map { $_ => $links->{$_} } keys %INDEX;
is \%got, \%INDEX,
    "the index links each name DBIx-Squirrel's index uses where it expects";

done_testing;
