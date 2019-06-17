# NAME

Devel::Optic - Production safe variable inspector

# SYNOPSIS

    use Devel::Optic;
    my $optic = Devel::Optic->new(max_size => 100);
    my $foo = { bar => ['baz', 'blorg', { clang => 'pop' }] };

    # 'pop'
    $optic->inspect(q|$foo->{'bar'}->[-1]->{'clang'}|);

    # 'HASH: { bar => ARRAY ...} (1 total keys / 738 bytes). Exceeds viewing size (100 bytes)"
    $optic->inspect('$foo');

# DESCRIPTION

[Devel::Optic](https://metacpan.org/pod/Devel::Optic) is a [fiberscope](https://en.wikipedia.org/wiki/Fiberscope) for
Perl programs. Just like a real fiberscope, it provides 'nondestructive
inspection' of your variables. In other words: use this in your production
environment to figure out what the heck is in your variables, without worrying
whether the reporting code will blow up your program by trying shove gigabytes
into the logging pipeline.

It provides a basic Perl-ish syntax (a 'query') for extracting bits
of complex data structures from a Perl scope based on the variable name. This
is intended for use by debuggers or similar introspection/observability tools
where the consuming audience is a human troubleshooting a system.

If the data structure selected by the query is too big, it will summarize the
selected data structure into a short, human-readable message. No attempt is
made to make the summary machine-readable: it should be immediately passed to
a structured logging pipeline.

# METHODS

## new

    my $o = Devel::Optic->new(%options);

`%options` may be empty, or contain any of the following keys:

- `uplevel`

    Which Perl scope to view. Default: 1 (scope that `Devel::Optic` is called from)

- `max_size`

    Max size, in bytes, of a data structure that can be viewed without
    summarization. This is a little hairy across different architectures, so this
    is best expressed in terms of Perl data structures if specified. The goal is to
    avoid spitting out subjectively 'big' Perl data structures to a debugger or
    log. If you're tuning this value, keep in mind that CODE refs are _enormous_
    (~33kb on `x86_64`), so basically any data structure with CODE refs inside
    will be summarized.

    Default: Platform dependent. The value is calculated by

        Devel::Size::total_size([ map { { a => [1, 2, 3, qw(foo bar baz)] } } 1 .. 5 ])

    ... which is ~3kb on `x86_64`, and ~160 bytes JSON encoded. This is an
    estimate on my part for the size of data structure that makes sense to export
    in raw format when viewed. To my entirely personal taste, larger data
    structures than this are too big to reasonably export to logs in their
    entirety.

- `scalar_truncation_size`

    Size, in `substr` length terms, that scalar values are truncated to for
    viewing. Default: 256.

- `scalar_sample_size`

    Size, in `substr` length terms, that scalar children of a summarized data
    structure are trimmed to for inclusion in the summary. Default: 64.

- `sample_count`

    Number of keys/indices to display when summarizing a hash or arrayref. Default: 4.

## inspect

    my $stuff = { foo => ['a', 'b', 'c'] };
    my $o = Devel::Optic->new;
    # 'a'
    $o->inspect(q|$stuff->{'foo'}->[0]|);

This is the primary method. Given a query, It will either return the requested
data structure, or, if it is too big, return a summary of the data structure
found at that path.

## fit\_to\_view

    my $some_variable = ['a', 'b', { foo => 'bar' }, [ 'blorg' ] ];

    my $tiny = Devel::Optic->new(max_size => 1); # small to force summarization
    # "ARRAY: [ 'a', 'b', HASH, ARRAY ]"
    $tiny->fit_to_view($some_variable);

    my $normal = Devel::Optic->new();
    # ['a', 'b', { foo => 'bar' }, [ 'blorg' ] ]
    $normal->fit_to_view($some_variable);

This method takes a Perl object/data structure and either returns it unchanged,
or produces a 'squished' summary of that object/data structure. This summary
makes no attempt to be comprehensive: its goal is to maximally aid human
troubleshooting efforts, including efforts to refine a previous invocation of
Devel::Optic with a more specific query.

## full\_picture

This method takes a 'query' and uses it to extract a data structure from the
[Devel::Optic](https://metacpan.org/pod/Devel::Optic)'s `uplevel`. If the query points to a variable that does not
exist, [Devel::Optic](https://metacpan.org/pod/Devel::Optic) will croak.

### QUERY SYNTAX

[Devel::Optic](https://metacpan.org/pod/Devel::Optic) uses a Perl-ish data access syntax for queries.

A query always starts with a variable name in the scope being picked, and
uses `->` to indicate deeper access to that variable. At each level, the
value should be a key or index that can be used to navigate deeper or identify
the target data.

For example, a query like this:

    %my_cool_hash->{'a'}->[1]->{'needle'}

Applied to a scope like this:

    my %my_cool_hash = (
        a => ["blub", { needle => "find me!", some_other_key => "blorb" }],
        b => "frobnicate"
    );

Will return the value:

    "find me!"

A less specific query on the same data structure:

    %my_cool_hash->{'a'}

Will return that branch of the tree:

    ["blub", { needle => "find me!", some_other_key => "blorb" }]

Other syntactic examples:

    $hash_ref->{'a'}->[0]->[3]->{'blorg'}
    @array->[0]->{'foo'}
    $array_ref->[0]->{'foo'}
    $scalar

#### QUERY SYNTAX ALTNERATIVES

The query syntax attempts to provide a reasonable amount of power
for navigating Perl data structures without risking the stability of the system
under inspection.

In other words, while `eval '$my_cool_hash{a}->[1]->{needle}'` would
be a much more powerful solution to the problem of navigating Perl data
structures, it opens up all the cans of worms at once.

The current syntax might be a little bit "uncanny valley" in that it looks like
Perl, but is not Perl. It is Perl-ish. It also might be too complex, since it
allows fancy things like nested resolution:

    $foo->{$bar}

Or even:

    %my_hash->{$some_arrayref->[$some_scalar->{'key'}]}->{'needle'}

Ouch. In practice I hope and expect that the majority of queries will be
simple scalars, or maybe one or two chained hashkey/array index lookups.

I'm open to exploring other syntax in this area as long as it is aligned with
the following goals:

- Simple query model

    As a debugging tool, you have enough on your brain just debugging your system.
    Second-guessing your query syntax when you get unexpected results is a major
    distraction and leads to loss of trust in the tool (I'm looking at you,
    ElasticSearch).

- O(1), not O(n) (or worse)

    I'd like to avoid globs or matching syntax that might end up iterating over
    unbounded chunks of a data structure. Traversing a small, fixed number of keys
    in 'parallel' sounds like a sane extension, but anything which requires
    iterating over the entire set of hash keys or array indicies is likely to
    surprise when debugging systems with unexpectedly large data structures.

# SEE ALSO

- [PadWalker](https://metacpan.org/pod/PadWalker)
- [Devel::Probe](https://metacpan.org/pod/Devel::Probe)
