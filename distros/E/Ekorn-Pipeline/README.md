[![Actions Status](https://github.com/nukopian/Ekorn-Pipeline/actions/workflows/test.yml/badge.svg?branch=main)](https://github.com/nukopian/Ekorn-Pipeline/actions?workflow=test)
[![CPAN](https://img.shields.io/cpan/v/Ekorn-Pipeline)](https://metacpan.org/release/Ekorn-Pipeline) [![Kwalitee](https://cpants.cpanauthors.org/dist/Ekorn-Pipeline.svg)](https://cpants.cpanauthors.org/dist/Ekorn-Pipeline)

# Ekorn-Pipeline

Stages for any function: let the caller finish the job.

A function that hands out values can't know everything its callers
will want done with them. With Ekorn::Pipeline, it takes a list of
_stages_ from its caller: small functions that each see one value at
a time. It runs what it would return through them. The caller says
what they want, beside the call, and the function does only what it
alone can.

```perl
use Ekorn::Pipeline;
use Ekorn::Pipeline::Tooling qw(:all);

# The author's function: it reads log lines, and nothing else.
sub log_lines ($file, @stages) {
    return Ekorn::Pipeline->new(@stages)->iterator(from_file($file));
}

# A caller's use of it: the first ten errors, as their messages.
my $errors = log_lines(
    'app.log',
    sub { m( \A ERROR \  (.*) )x ? $1 : () },    # only errors, as messages
    take(10),                                    # ten, then stop reading
);
while (my($message) = $errors->()) { say $message }
```

The file is read only as far as the tenth error, and closed there,
however the caller's loop ends.

Every stage, source, sink and word here comes from one module,
[Ekorn::Pipeline::Tooling](https://metacpan.org/pod/Ekorn%3A%3APipeline%3A%3ATooling), by tags, and the examples below assume
it; the sections say which module makes each.

## The problem it solves

Every function that returns a list meets the same pressure. One caller
wants only some of the values. Another wants them in a different
shape, a third wants the first ten, and a fourth wants them in batches
of 500. The author has two ways to answer, and both cost something.

- **Grow options.** `active_only`, `fields`, `limit`,
`offset`, `as_hash`, `batch_size`, `callback`. Each is code the
author writes, tests, documents and maintains. Each interacts with the
others: does `limit` count before or after `active_only`? The list
is never finished, because the next caller wants something nobody
thought of. And every caller has to read about options they'll never
use.
- **Leave it to the caller.** The function returns everything, and
each caller writes a loop around the call: a temporary array, a
counter, a flag, a `last`. The calling code fills with noise, and the
same few loops are written over and over. Worse, the function can't
stop early: by the time the caller has the values, all the work of
making them is done.

Stages are a third way. The function takes a list of them as its last
arguments, and runs each value it makes through them. The caller's
processing happens _inside_ the function, one value at a time, as
the values are made:

```perl
# Options
sub users (%opt) {
    my @users = load_users();
    @users = grep { $_->{active} } @users if $opt{active_only};
    @users = map  { $_->{name} } @users   if $opt{names_only};
    @users = splice @users, 0, $opt{limit} if $opt{limit};
    return @users;
}

# Stages
sub users (@stages) {
    return Ekorn::Pipeline->new(@stages)->(load_users());
}

my @names = users(
    take_if { $_->{active} },
    sub { $_->{name} },
    take(10),
);
```

The second `users` does everything the first does, and everything it
doesn't, without a line more. Its author is done with it. Whatever a
caller wants next, they can write as a stage, without asking.

## What everyone gets

- **The caller says it once, beside the call.** No loop, no
temporary array, no counter, no flag. What the caller wants done is
written where they ask for the values, in the order it happens, and
reads as a list of steps.
- **The work stops when the caller has enough.** A stage that
stops ends the function's work too. A caller who wants ten results
reads ten lines, or fetches one page, not all of them. Nothing is held
between stages, so a function over a million values needs no more
memory than one over ten.
- **The author keeps an interface that doesn't grow.** One list of
stages replaces every option a caller might ask for next. The
function's signature, documentation and tests stay the size of what
only it can do. A new need is met in the caller's code, and breaks
nobody else's.
- **The author keeps control of what only it should touch.** The
function still opens and closes the file, fetches the pages, and
handles the connection or transaction. The caller shapes the values
without ever seeing the handle they came from.
- **Order answers the questions options raise.** Does `limit`
count before or after `active_only`? With stages, they run in the
order the caller wrote them.
- **A stage is written once, for every function.** A stage
written for one function works with every function that takes stages,
whoever wrote it. The ready-made stages here work with all of them.

## The shape of a run

Every run of a pipeline has the same shape. Values come from
somewhere, go through stages one at a time, and end up somewhere:

```
  source  -->  stage  -->  stage  -->  stage  -->  sink
 (where       (change, drop, multiply,          (where they
they come      or stop: one value at a time)      end up)
  from)
```

The _stages_ are the heart of it, and the only part a function that
takes stages needs. The other two are optional. A _source_ is where
a pulled pipeline gets its values, such as a file, opened as the run
starts and closed however it ends. A _sink_, given last, takes every
value that comes out and gives one result, such as a count, the first
value, or the number of lines written to a file. Without a sink, the
run gives back whatever comes out of the last stage.

The sections below take the parts in that order, after the stages:
how a pipeline runs, how a stage stops it, parts made afresh for each
run, sources, sinks, and joining them with `|`.

## Stages

A stage is most often a plain code reference. It's called with one
value, as its argument and in `$_`, and returns a list:

- **nothing,** to drop the value: a _filter_;
- **one value,** to pass it on, changed or not: a _map_;
- **several,** each of which goes on through the rest of the
stages by itself: a _flatMap_.

One shape covers all three. A pipeline is just a list of stages, and a
stage needs no wrapper to say which kind it is:

```perl
sub { $_ % 2 ? $_ : () }                # filter: the odd numbers
sub { $_ * 10 }                         # map: ten times each
sub ($user) { @{ $user->{roles} } }     # flatMap: each of a user's roles
```

Returning a list, rather than a value or `undef`, is what makes this
work. An empty list plainly means "nothing", so `undef`, `0` and the
empty string are ordinary values, and can be passed on. A test, which
returns true or false, isn't a filter: give it to `take_if` or
`drop_if`, from [Ekorn::Pipeline::Stages::Flow](https://metacpan.org/pod/Ekorn%3A%3APipeline%3A%3AStages%3A%3AFlow), as in
`take_if { $_->{active} }`.

A stage can also be:

- **another pipeline,** which stands for its own stages, spliced
in where it's given;
- **a stage made with a word,** such as `stage { ... }` or
`gather { ... }`, from [Ekorn::Pipeline::Factories](https://metacpan.org/pod/Ekorn%3A%3APipeline%3A%3AFactories), or one of the
ready-made stages, such as `take(10)`;
- **any object with an `EKORN_STAGE` method,** so another
package can deliver stages without using Ekorn's classes (see
["Parts for other packages"](#parts-for-other-packages)).

So stages you've put together once can be reused, in another pipeline
or with any function that takes stages:

```perl
my $active_names = Ekorn::Pipeline->new(
    take_if { $_->{active} },
    sub { $_->{name} },
);
my @names = users(
    $active_names,
    take(10),
);
```

If a function accepts only code references, give it the pipeline's
stages instead: `users($active_names->stages, take(10))`.

## One value at a time

Each value goes through every stage before the next one starts, as it
would in a `for` loop. The values come out in order, and each stage
sees them in order. Nothing is held between stages, so a pipeline over
a million values needs no more memory than one over ten.

A pipeline runs two ways:

- **Pushed:** called with values, it returns the list that comes
out of the last stage.

    ```perl
    my @results = $pipeline->(@values);
    ```

- **Pulled:** given a _source_, `iterator` returns an iterator,
an object called as a function, which hands out the results one per
call. The source is asked for values only when a result is wanted. A
function reading a file, a socket or a database reads only as much as
its caller asks for.

    ```perl
    my $next = $pipeline->iterator(sub { @queue ? shift @queue : () });
    while (my($result) = $next->()) { ... }
    ```

The simplest source is a sub that returns the next value, or an empty
list when there are no more. An iterator can also give everything
that's left, with `all`, or just the next, with `first`; end its run
early, with `finish`; and say how the run ended, with `ended`. An
iterator let go before its values run out ends its run, so a source
closes what it opened.

## Stopping early

A stage can end the pipeline with [Ekorn::Pipeline::Stop](https://metacpan.org/pod/Ekorn%3A%3APipeline%3A%3AStop). The values
already out are kept, and any values the stop carries go on through
the rest of the stages. Nothing else is made: once a stage has stopped
it, a pulled pipeline never calls its source again.

```perl
sub ($user) { $user->{id} == $wanted ? Stop($user) : () }    # find one, then stop
```

This is how a caller's stages save the author's work. With
`take(10)`, the function in the first example reads up to the tenth
error line, and leaves the rest of the file unread. Nobody wrote an
option for it, and the caller wrote no `last`.

It matters more where each value costs more. A function over a paged
web API fetches a page only when its caller wants a result from it:

```perl
sub search ($query, @stages) {
    my $page = 0;
    return Ekorn::Pipeline->new(@stages)->iterator(sub {
        return @{ fetch_page($query, ++$page) };    # a request; empty after the last page
    });
}

my $hits = search('squirrels', take(10));
while (my($hit) = $hits->()) { say $hit->{title} }    # one request, if a page holds ten
```

Without stages, that function either fetches every page, or grows
`max_results`, `max_pages` and `on_result` options, for its author
to write and maintain.

## Parts made for each run

A stage is a closure, so it can keep state, such as a count. But a
plain closure keeps its state from one run to the next, and can't tell
when the last value has gone by, or how the run ended.
[Ekorn::Pipeline::Gather](https://metacpan.org/pod/Ekorn%3A%3APipeline%3A%3AGather) makes a stage afresh at the start of each
run. Its block is the stage's _set-up_, and returns the stage's
_step_, called with each value, and, if it needs them:

- **a flush,** called once the values run out, whose values go on
through the rest of the stages, so a stage can hold values back and
hand them over at the end;
- **an end,** called once the run is over, however it ended, and
told how: `done`, `stopped` or `died`, so a stage can tidy up.

The parts are given by name, in a hash reference, or as a list in that
order:

```perl
sub batches_of ($size) {
    return gather {
        my @batch;    # this run's
        return {
            step  => sub ($x) { push @batch, $x; @batch == $size ? [splice @batch] : () },
            flush => sub ()   { @batch ? [@batch] : () },    # the last, short batch
        };
    };
}
```

That's how `batch`, `collect`, `take` and `drop` are made. Sources
and sinks are made the same way, from a set-up called at the start of
each run, so every part of a run can have state of its own, and be
told how the run ended.

## Sources

A plain sub makes a fine source, but it's the same sub on every run,
and it's never told when the run is over: a sub reading a file can't
close it when the caller stops early. The sources in
[Ekorn::Pipeline::Sources](https://metacpan.org/pod/Ekorn%3A%3APipeline%3A%3ASources) are made afresh for each run, and told
when it ends:

- `from_array(@values)`, the values given, from the first, on
each run;
- `from_file($path, $layers)`, a file's lines, without their
newlines, opened as the run starts, through the I/O layers given, and
closed however it ends;
- `from_fh($fh)`, the lines of a filehandle you opened, left
open;
- `counter($start, $step)`, numbers without end.

The word `source`, from [Ekorn::Pipeline::Factories](https://metacpan.org/pod/Ekorn%3A%3APipeline%3A%3AFactories), makes your
own. Its block is the source's set-up, and returns its step, which
gives the next value or an empty list at the end, and, if it needs one,
its end:

```perl
sub lines_of ($file) {
    return source {
        open my $fh, '<', $file or die "Can't read $file: $!\n";
        return {
            step => sub () { my $line = readline $fh; defined $line ? $line =~ s( \n \z )()xr : () },
            end  => sub ($how) { close $fh },
        };
    };
}
```

The set-up can also give a _context_, anything its stages may want
to know about the run, such as a file's column names, which a stage
asks for with `Ekorn::Pipeline::run_context()`. And for a producer
that's easiest written as a loop, the word `generator` takes a block
that calls `yield` with each value.

An iterator is a source too, so one pipeline's results can be read as
another's values, and ending the outer run ends the inner one.

## Sinks

A sink is the opposite of a source: given last in a pipeline, it takes
every value that comes out, and gives one result, which is what the
run gives. [Ekorn::Pipeline::Sinks](https://metacpan.org/pod/Ekorn%3A%3APipeline%3A%3ASinks) has them ready-made:

- `count_items`, how many;
- `keep_first`, `keep_last` and `keep_single`, one value,
`keep_single` warning if there's a second;
- `keep_all` and `keep($n)`, every value, or the first `$n`,
as a list, or as an array reference in scalar context;
- `to_file($path, $layers)` and `to_fh($fh)`, writing each
value on a line of its own, and giving how many.

```perl
my $errors = Ekorn::Pipeline->new(
    take_if { m( \A ERROR )x },
    count_items,
)->(@lines);
my $first = Ekorn::Pipeline->new(
    take_if { m( \A ERROR )x },
    keep_first,
)->(@lines);
```

A sink that has what it needs, such as `keep_first`, stops the run
there, so a source is read no further.

The words `sink_one` and `sink_many` make your own, giving one value
or a list. The set-up returns the step, called with each value; the
flush, giving the result; and optionally an end. A sink whose end is
told `done` knows every value arrived, so it can commit a
transaction, or move a file into place, only then.

## Joining parts with `|`

With [Ekorn::Pipeline::Operators](https://metacpan.org/pod/Ekorn%3A%3APipeline%3A%3AOperators) in scope, sources, stages and sinks
join with `|`, as commands do in a Unix shell. A chain from a source
to a sink runs at once, and gives the sink's result:

```perl
use Ekorn::Pipeline::Operators;

my $errors = from_file('app.log') | take_if { m( \A ERROR )x };
say $errors | count_items;
my $messages = $errors
    | stage { s( \A ERROR \  )()xr }
    | take(10)
    | keep_all;
say for @$messages;
```

A source joined to stages, with no sink, is a new source, which can be
kept and ended in different sinks, each chain a run of its own. Stages
joined with no source make a pipeline, and `|=` adds to it.
`@{ $source }` reads a source to its end, and gives every value.

It's a shorthand for the commonest shape, and everything it does can
be done with `new` and `iterator`. Two things to mind, both Perl's:
start a chain with one of Ekorn's types, a source, a stage made with
`stage`, or a ready-made one, as `sub {...} | sub {...}` is Perl's
bitwise OR of two addresses; and put a chain inside a larger
expression in parentheses, as `|` binds more loosely than `.` and
`+`.

## Stages are values

Stages can be kept in variables, built by functions and passed around.
A function that returns a stage is a word in a vocabulary, and the
vocabulary grows in the caller's code, not the author's:

```perl
sub only_active ()    { take_if { $_->{active} } }
sub value_of ($name)  { sub { $_->{$name} } }

my @page  = (drop(20), take(10));
my @names = users(
    only_active,
    value_of('name'),
    @page,
);
```

A stage written for `users` works for `log_lines` too, or for a
function on CPAN whose author has never heard of it.

A pipeline you use often can be given a name, and used by it. The word
`pipeline` makes a pipeline in which a name stands for the pipeline it
names:

```perl
Ekorn::Pipeline->named(active_names =>
    only_active,
    value_of('name'),
);
my @names = users(pipeline(
    'active_names',
    take(10),
));
```

A name belongs to the package that defined it, unless it's qualified,
so two modules can each have their own. A stage that dies inside a
named pipeline is reported with its name. [Ekorn::Pipeline::Sugar](https://metacpan.org/pod/Ekorn%3A%3APipeline%3A%3ASugar)
names pipelines as the program compiles, and gives your package a
function of each name:

```perl
use Ekorn::Pipeline::Sugar pipeline => {
    active_names => [only_active, value_of('name')],
};
my @names = active_names(@users);
```

## Writing a function that takes stages

- **Take the stages last.** The function's own arguments come
first, then the stages: `sub log_lines ($file, @stages)`. A caller
who wants nothing done passes no stages. A pipeline with no stages
returns its values unchanged, so there's nothing to special-case.
- **Push what you have; pull what you make.** If the values are
already in memory, call the pipeline with them. If they're made one at
a time, from a file, a socket, a database or a computation, give
`iterator` a source and return the iterator. Then a stage that stops
saves the work of making the rest, and a source that closes what it
opens closes it however the caller's use ends.
- **Let the stages do the optional work.** If you're about to add
an option that filters, reshapes or limits what's returned, a stage
does it already, and it's one less thing for you to maintain. Keep the
arguments only the function can act on, such as which file to read, or
a filter a database can apply with an index.
- **Report your callers' mistakes at their lines.** Put
`@Ekorn::Pipeline::Errors::INTERNAL` in your module's `@CARP_NOT`.
Then a stage that dies is reported at the caller's line, where the
stage was written, not at the line in your module that ran the
pipeline.
- **Find the stages with `is_stage`.** If the function takes a
list of values of its own before the stages, take the stages off the
end with `is_stage`, from Ekorn::Pipeline. It's the test `new` uses,
so your callers can pass a pipeline as a stage, too. The values
mustn't be code references or pipelines themselves.
- **Or take a pipeline given last.** If the values can be code
references, such as callbacks, `is_stage` can't tell them from
stages. Take a pipeline given last as the stages instead, which your
callers make with the word `pipeline`: `call_all(@callbacks,
pipeline(sub { $_ * 10 }, take(2)))`.

A class of your own can have `pipe` and `tap` methods, from
[Ekorn::Pipeline::Pipes](https://metacpan.org/pod/Ekorn%3A%3APipeline%3A%3APipes), which run an object through stages. `pipe`
returns what comes out. `tap` returns the object, so a chain of
method calls can carry on after it.

## Parts for other packages

Your own classes can be sources, stages and sinks, with no need to
load Ekorn or inherit from anything. An object says what it can be by
its methods, named in capitals because Ekorn calls them, not your
users: `EKORN_SOURCE`, to be read from; `EKORN_STAGE`, to be a stage
with state of its own; and `EKORN_SINK_ONE` or `EKORN_SINK_MANY`, to
be written to. Each is called at the start of a run, and returns the
parts, as a set-up does:

```perl
package My::Queue {
    sub new ($class, @items) { bless {items => [@items]}, $class }

    # Read: each item, taken off the front of the queue.
    sub EKORN_SOURCE ($self) {
        return {step => sub () { @{ $self->{items} } ? shift @{ $self->{items} } : () }};
    }
}

my @loud = Ekorn::Pipeline->new(sub { uc })->iterator(My::Queue->new(qw(a b)))->all;
```

The methods are the whole contract, so your package and Ekorn can
each change their insides freely. A source class can also overload
`|` and `@{}` with Operators' `chain` and `drain`, so its users
can start a chain with it.
[The reference's "Making each kind of part"](https://metacpan.org/pod/Ekorn%3A%3APipeline%3A%3AManual%3A%3AReference#Making-each-kind-of-part)
has what each method is called with and must return, with a worked
example of each.

## Errors

A stage that dies is named by its position in the pipeline, and
reported at the line of the caller's code that ran it, with its
message below:

```perl
Pipeline stage #2 failed at app.pl line 12:
    No name for user 7 at app.pl line 9.
```

A stage inside a pipeline given as a stage is numbered within it, as
`#2.1`, and one inside a named pipeline is named with it, as
`#2.1 (main::clean#1)`. An exception object is passed on unchanged.
Either way the run ends, pushed or pulled, an iterator returns nothing
more, and every part's end is called, told `died`, before the error
is thrown. A mistake in making a pipeline or a ready-made part, such
as a stage that's neither a code reference nor a pipeline, or
`take(-1)`, is also reported at the caller's line.

## What comes with it

- [Ekorn::Pipeline::Tooling](https://metacpan.org/pod/Ekorn%3A%3APipeline%3A%3ATooling): everything below but the
operators, from one module, by tags: `:core`, `:flow`, `:batch`,
`:taps`, `:stages`, `:sources`, `:sinks`, `:json`, `:words` and
`:all`.
- [Ekorn::Pipeline::Stages::Flow](https://metacpan.org/pod/Ekorn%3A%3APipeline%3A%3AStages%3A%3AFlow): `take`, `drop`,
`take_first`, `take_last`, `take_single`, `take_if`, `drop_if`,
`take_while` and `drop_while`, which pass values on by their position
or by a test.
- [Ekorn::Pipeline::Stages::Batch](https://metacpan.org/pod/Ekorn%3A%3APipeline%3A%3AStages%3A%3ABatch): `batch` and `collect`,
which gather values and pass them on together.
- [Ekorn::Pipeline::Stages::Taps](https://metacpan.org/pod/Ekorn%3A%3APipeline%3A%3AStages%3A%3ATaps): `peek`, `count_into` and
`dump_to`, which look at each value and pass it on, for logging,
counting and debugging.
- [Ekorn::Pipeline::Sources](https://metacpan.org/pod/Ekorn%3A%3APipeline%3A%3ASources) and [Ekorn::Pipeline::Sinks](https://metacpan.org/pod/Ekorn%3A%3APipeline%3A%3ASinks):
the sources and sinks above.
- [Ekorn::Pipeline::JSON](https://metacpan.org/pod/Ekorn%3A%3APipeline%3A%3AJSON): `from_json` and `to_json`, which
read and write one JSON document, and `from_jsonl` and `to_jsonl`,
which read and write JSON Lines: each a source or a sink given a file
or a filehandle, and a stage given neither. The how-to walks through
how a module like it is put together.
- [Ekorn::Pipeline::Sugar](https://metacpan.org/pod/Ekorn%3A%3APipeline%3A%3ASugar): pipelines named as the program
compiles, each with a function of its name.
- [Ekorn::Pipeline::Factories](https://metacpan.org/pod/Ekorn%3A%3APipeline%3A%3AFactories): the words that make Ekorn's
types, `pipeline`, `stage`, `gather`, `source`, `generator` and
`yield`, `sink_one` and `sink_many`.
- [Ekorn::Pipeline::Operators](https://metacpan.org/pod/Ekorn%3A%3APipeline%3A%3AOperators): `|`, `|=` and `@{}`, in the
scope that uses it.

## Stage modules of your own

Anyone can make stages, in any namespace. Where a module of stages
belongs depends on what its stages need to know:

- **Stages for any values** go under `Ekorn::Pipeline::Stages`,
like the ready-made stages. They work whatever the values are and
wherever they come from.
- **Stages for one kind of value, or one source,** go with the
module that knows about it, under its namespace. DBIx::Squirrel's
stages for rows, `pluck` and `as_hash`, need a statement's column
names, so they're in `DBIx::Squirrel::Stages::Rows`. Stages for a log
format of your own might be in `My::Log::Stages`.

Wherever it goes, a module of stages is built from the same parts as
the ready-made stages:

- [Ekorn::Pipeline::Gather](https://metacpan.org/pod/Ekorn%3A%3APipeline%3A%3AGather), for state, flushes and ends;
- [Ekorn::Pipeline::Stop](https://metacpan.org/pod/Ekorn%3A%3APipeline%3A%3AStop), to end early;
- `croakf`, from [Ekorn::Pipeline::Errors](https://metacpan.org/pod/Ekorn%3A%3APipeline%3A%3AErrors), to report a mistake
in making a stage at the line of the caller who made it.

Here's a small one:

```perl
package My::Stages::Words;

use v5.36;
use Exporter qw(import);
use Ekorn::Pipeline::Errors qw(croakf);

our @EXPORT_OK = qw(longer_than);

sub longer_than ($length) {
    croakf 'Expected a length of 0 or more, not %s', $length // 'undef'
        unless defined $length && $length =~ m( \A \d+ \z )xa;
    return sub ($word) { length $word > $length ? $word : () };
}
```

## When to use something else

- **Code with no other caller.** Where the values are made and
used in one place, by one author, a plain `for`, `grep` or `map` is
clearer. Stages pay off where a function and its callers are written
separately.
- **Tight loops over cheap values.** Each stage costs a
subroutine call for each value, and a pulled value costs a call of its
own. That's nothing beside reading a file or a socket, but it shows in
a loop doing arithmetic on millions of numbers in memory, where `map`
and `grep` are many times faster.
- **Work that needs every value at once,** such as sorting. A
stage sees one value at a time, so a sort has to wait for them all, as
`collect { sort @_ }` does, and saves nothing. Where the source can
sort, as a database can with `ORDER BY`, let it.
- **Concurrency.** A pipeline runs in the calling thread, one
value at a time, and a stage that blocks blocks the run.

## Where it came from

The pipeline began in
[DBIx::Squirrel](https://metacpan.org/dist/DBIx-Squirrel), where
stages written beside a query shape the rows it returns. None of it
needs a database, so it's here on its own, for any function to use,
and to grow beyond what rows need. DBIx::Squirrel now uses it, in
place of its own copy, from v2.0.5.

## Documentation

[The user guide](https://metacpan.org/pod/Ekorn%3A%3APipeline%3A%3AManual%3A%3AHowTo) tours the package
from the bottom up, from a single stage to functions and packages
built on it, with recipes for what each part can do, and where it
falls short. [The reference](https://metacpan.org/pod/Ekorn%3A%3APipeline%3A%3AManual%3A%3AReference) describes
every module, function and method in full, and how a pipeline
behaves, with notes for stage authors. Each module's POD, starting
with [Ekorn::Pipeline](https://metacpan.org/pod/Ekorn%3A%3APipeline), says the same more briefly, and is the
authority where they differ.

## Installing

From CPAN:

```
cpanm Ekorn::Pipeline
```

Or the latest from GitHub:

```
cpanm https://github.com/nukopian/Ekorn-Pipeline.git
```

It needs Perl 5.36 or later.

## Licence

Copyright (c) 2024-2026 by Iain Campbell. This is free software; you can
redistribute it and/or modify it under the same terms as the Perl 5
programming language system itself. See the file `LICENSE`.

## Acknowledgements

Designed and created by Iain Campbell, in collaboration with Claude,
Anthropic's AI model.
