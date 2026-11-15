use v5.36;

package Ekorn::Pipeline;

use experimental qw(builtin try);

use builtin   qw(blessed refaddr weaken);
use Carp      qw(croak);
use Exporter  qw(import);
use Ref::Util qw(is_arrayref is_coderef is_plain_hashref is_ref);

use parent 'Ekorn::Pipeline::Element';

use Ekorn::Pipeline::Errors   qw(croakf);
use Ekorn::Pipeline::Iterator qw();
use Ekorn::Pipeline::Stage    qw();

use namespace::clean -except => 'import';

our $VERSION = 'v0.3.1';

our @EXPORT_OK = qw(is_sink is_stage);

# Croak at the line that called Ekorn::Pipeline.
our @CARP_NOT = @Ekorn::Pipeline::Errors::INTERNAL;

# Return true if what's given can go where a stage goes: a code
# reference; a pipeline, whose stages go in its place; or anything
# offering a stage's or a sink's role method.
sub is_stage ($thing) {
    return !!(is_coderef($thing)
        || $thing isa 'Ekorn::Pipeline'
        || _stage_role($thing));
}


# Return "one" if what's given is a sink giving one value, "many" if
# it's a sink giving a list, or false otherwise; a pipeline, by the
# sink it ends in.
sub is_sink ($thing) {
    ($thing) = ($thing->stages)[-1] if $thing isa 'Ekorn::Pipeline';
    return !!0                      unless blessed($thing);
    return 'one'                    if $thing->can('EKORN_SINK_ONE');
    return 'many'                   if $thing->can('EKORN_SINK_MANY');
    return !!0;
}


# Return the role method that what's given offers for a stage's place,
# EKORN_STAGE, EKORN_SINK_ONE or EKORN_SINK_MANY, or nothing if it offers none.
sub _stage_role ($thing) {
    return unless blessed($thing);
    my @roles
        = grep { $thing->can($_) } qw(EKORN_STAGE EKORN_SINK_ONE EKORN_SINK_MANY);
    return $roles[0];
}


# Return true if what's given offers a source's role method.
sub _is_source ($thing) {
    return !!(blessed($thing) && $thing->can('EKORN_SOURCE'));
}


# Return the stage given as an element: a part offering a role method is
# kept as it is, and a code reference is made a Stage.
sub _element ($stage) {
    return $stage if $stage isa 'Ekorn::Pipeline::Element' || _stage_role($stage);
    return Ekorn::Pipeline::Stage->new($stage);
}


# Croak unless what's given, as stage #$n, can go where a stage goes, as
# one role: a source isn't a stage, and a part offering more than one of
# a stage's and a sink's role methods couldn't say which it is.
sub _check_stage ($stage, $n) {
    my @roles
        = blessed($stage)
        ? grep { $stage->can($_) } qw(EKORN_STAGE EKORN_SINK_ONE EKORN_SINK_MANY)
        : ();
    croakf
        'Expected stage #%d to offer one of EKORN_STAGE, EKORN_SINK_ONE and EKORN_SINK_MANY, not %s',
        $n,
        join ' and ', @roles
        if @roles > 1;
    croakf 'Expected stage #%d to be a stage, not a source', $n
        if !@roles && _is_source($stage);
    croakf
        q(Expected stage #%d to be a stage: a code reference, a pipeline, or an object offering a stage's role method),
        $n
        unless is_stage($stage);
    return;
}


# Return a pipeline, called with values to run each of them through the
# stages. A pipeline given as a stage has its stages spliced in, each
# named by its place in each pipeline, such as "2.3". In scalar context,
# a call gives how many values came out, unless the last stage is a
# scalar sink, when it gives that sink's result.
sub new ($class, @given) {
    my(@stages, @names, @within);
    for my $n (1 .. @given) {
        my $stage = $given[$n - 1];
        _check_stage($stage, $n);
        if ($stage isa 'Ekorn::Pipeline') {
            my($inner, $inner_names, $inner_within) = _composed($stage);
            croakf
                'Expected stage #%d, a pipeline, to give only stages from its stages method',
                $n
                unless $inner_names;
            push @stages, map { _element($_) } @$inner;
            push @names,  map { "$n.$_" } @$inner_names;
            push @within,
                map { [[$stage, $inner_names->[$_]], @{ $inner_within->[$_] }] }
                0 .. $#$inner;
            next;
        }
        push @stages, _element($stage);
        push @names,  $n;
        push @within, [];
    }
    # In scalar context, a run gives a scalar sink's result, a list
    # sink's list as an array reference, or how many values came out.
    my $sink = @stages ? is_sink($stages[-1]) : !!0;
    # Where every stage is a plain step, a Stage of Ekorn's own, with no
    # flush, end or sink, and nothing made for a run, a push runs the
    # steps in a plain loop, with none of a run's machinery.
    my @steps
        = (grep { ref ne 'Ekorn::Pipeline::Stage' } @stages)
        ? ()
        : map { $_->{call} } @stages;
    # The pipeline, for its name in messages, held weakly, so the closure
    # it's called as never keeps it.
    my $self;
    my $pipeline = bless {
        stages => \@stages,
        names  => \@names,
        within => \@within,
        call   => sub (@values) {
            return @values unless @stages;
            my @results
                = @steps
                ? _push_steps($self, \@steps, \@names, \@within, @values)
                : _iterator(
                    $self, \@stages, \@names, \@within,
                    sub { splice @values },
                )->all;
            return @results    if wantarray;
            return $results[0] if $sink && $sink eq 'one';
            return \@results   if $sink;
            return scalar @results;
        },
    }, $class;
    weaken($self = $pipeline);
    return $pipeline;
}

# The named pipelines, each by its name qualified by its package.
my %named;

# Return $name qualified by $package, unless it's qualified already, or
# nothing if it isn't a name: identifiers, as Perl's, joined by "::".
sub _qualified ($name, $package) {
    return if !defined $name || is_ref($name);
    return unless $name =~ m( \A (?: [^\W\d] \w* :: )* [^\W\d] \w* \z )x;
    return $name =~ m( :: )x ? $name : "${package}::$name";
}


# Return the stages given, each name replaced by the pipeline it names,
# looked up in $package unless it's qualified.
sub _resolved ($package, @given) {
    my @stages;
    for my $n (1 .. @given) {
        my $stage = $given[$n - 1];
        if (is_stage($stage)) {
            push @stages, $stage;
            next;
        }
        my $name = _qualified($stage, $package);
        croakf
            q(Expected stage #%d to be a stage: a code reference, a pipeline or its name, or an object offering a stage's role method),
            $n
            unless defined $name;
        my $pipeline = $named{$name};
        croakf 'No pipeline named %s', $name unless $pipeline;
        push @stages, $pipeline;
    }
    return @stages;
}


# Return a new pipeline of the invocant's class, of the stages given, each
# a code reference, a pipeline, or the name of one, looked up now in
# $package unless it's qualified; or, given one name alone, the pipeline
# it names, if it's of the invocant's class, so its stages are numbered
# where it's given. The one method that reads names, called by the words,
# such as Factories' pipeline, with their caller's package.
sub pipeline_in ($class, $package, @stages) {
    my @resolved = _resolved($package, @stages);
    return $resolved[0]
        if @stages == 1 && !is_stage($stages[0]) && $resolved[0] isa $class;
    return $class->new(@resolved);
}


# Name a pipeline, in the caller's package unless the name is qualified,
# and return it: on the class, a new one of the stages after the name,
# read as pipeline_in reads them; on a pipeline, that one. The name can't
# be one already defined for another pipeline.
sub named ($invocant, $name, @stages) {
    my $class     = ref $invocant ? ref $invocant : $invocant;
    my $package   = caller;
    my $qualified = _qualified($name, $package);
    croakf 'Expected a name, made of words joined by ::' unless defined $qualified;
    my $pipeline;
    if (ref $invocant) {
        croakf 'Expected only a name, naming a pipeline you have' if @stages;
        $pipeline = $invocant;
    }
    else {
        # Always a new one, even of one name, so a name never aliases.
        $pipeline = $class->new(_resolved($package, @stages));
    }
    my $own = $named{$qualified};
    croakf 'A pipeline named %s is already defined', $qualified
        if $own && refaddr($own) != refaddr($pipeline);
    $pipeline->{name} = $qualified unless defined $pipeline->{name};
    return $named{$qualified} = $pipeline;
}


# Return the first name the pipeline was given, qualified by its
# package, or undef if it has none.
sub name ($self) {
    return $self->{name};
}

# Return the stages of a pipeline given as a stage, from its stages
# method, as giving its stages would, their names, and the pipelines
# each came from within it: its own, if the method returns the stages it
# was made with, as it does unless a subclass overrides it, or else their
# places in what it returns. The names are undefined if what it returns
# isn't all code references.
sub _composed ($pipeline) {
    my @stages = $pipeline->stages;
    my $made   = $pipeline->{stages};
    my $same   = @stages == @$made;
    for my $i (0 .. $#stages) {
        last unless $same;
        $same = (refaddr($stages[$i]) // 0) == refaddr($made->[$i]);
    }
    return \@stages, $pipeline->{names}, $pipeline->{within} if $same;
    return \@stages, undef if grep { !is_stage($_) } @stages;
    return \@stages, [1 .. @stages], [map { [] } @stages];
}


# Return an iterator handing out, one per call, the values from $source
# run through the stages: $source a code reference, or anything
# offering a source's role method, an iterator included.
sub iterator ($self, $source) {
    croakf 'Expected a source: a code reference, or an object offering EKORN_SOURCE'
        unless is_coderef($source) || _is_source($source);
    return _iterator(
        $self, $self->{stages}, $self->{names}, $self->{within},
        $source,
    );
}


# Return the stages, in order, as a list, to splice into another
# pipeline or give to any function taking stages.
sub stages ($self) {
    return @{ $self->{stages} };
}

# What a pipeline is doing while its stages run.
my %running;

# For code telling its stages about the value they're given: true while
# a flush runs, and while the values it gave go through the stages,
# rather than values from the source.
sub ending () {
    return $running{ending};
}


# For code telling its stages about the run: the context the run's
# source gave, if any, such as a statement's columns. A pushed run has
# none; an iterator used as a source passes on its run's.
sub run_context () {
    return $running{context};
}


# Return the step, the end and the context of a run of $source: from
# its EKORN_SOURCE, if it offers one; a code reference is its own step,
# with no end or context.
sub _source_run ($source) {
    return ($source) unless _is_source($source);
    my($step, $end, $context)
        = _parts([qw(step end context)], $source->EKORN_SOURCE);
    croakf
        'Expected the source to return a code reference, and optionally an end and a context'
        unless is_coderef($step) && _code_or_none($end);
    return ($step, $end, $context);
}


# Return the parts a role method or a set-up returned as a list, in the
# order of the keys in @$order: as they are, if they're a list, or, if
# they're one plain hash reference, its values for those keys. Other
# keys are ignored.
sub _parts ($order, @returned) {
    return @returned unless @returned == 1 && is_plain_hashref($returned[0]);
    return @{ $returned[0] }{@$order};
}


# Return true if each of what's given is a code reference, or undefined.
sub _code_or_none (@things) {
    return !grep { defined && !is_coderef($_) } @things;
}


# Return how a stage is named in a message: by its place, $name, and, if
# it's within a named pipeline, the innermost, by its name and its place
# in it, from the pipelines in @$within it came from, and $pipeline, the
# one being run.
sub _label ($pipeline, $name, $within) {
    for my $in (reverse [$pipeline, $name], @$within) {
        my($outer, $place) = @$in;
        my $outer_name = $outer->name;
        return "stage #$name ($outer_name#$place)" if defined $outer_name;
    }
    return "stage #$name";
}


# Return the results of pushing @values through @$steps, each a plain
# step, as a run of them would give them, without a run's machinery: each
# value through every step before the next, what a step returns going on
# in order, a stop's values going on from the step after it, with
# nothing else, and a step that dies named as a run names it.
sub _push_steps ($pipeline, $steps, $names, $within, @values) {
    # A pushed run has no context, and gives no values from a flush.
    local $running{context} = undef;
    local $running{ending}  = undef;
    my(@results, @todo, $n);
    my($at, $more) = (0, 1);
    # One try for as many values as go through without a stop, which is
    # caught, and the values it carries go on from the step after it.
    while ($more) {
        try {
        VALUE:
            while (1) {
                my $value;
                if    (@todo)         { ($n, $value) = @{ pop @todo } }
                elsif ($at < @values) { ($n, $value) = (0, $values[$at++]) }
                else                  { $more = 0; last VALUE }
                while ($n < @$steps) {
                    local $_ = $value;
                    my @values = $steps->[$n]->($value);
                    $n++;
                    next VALUE unless @values;
                    $value = shift @values;
                    push @todo, map { [$n, $_] } reverse @values if @values;
                }
                push @results, $value;
            }
        }
        catch ($e) {
            if ($e isa 'Ekorn::Pipeline::Stop') {
                my(undef, @carried) = is_arrayref($e) ? @$e : ();
                ($at, @todo) = (scalar @values);
                push @todo, map { [$n + 1, $_] } reverse @carried;
                next;
            }
            croak $e if is_ref($e);
            my $where   = Carp::shortmess() =~ s( \.? \n \z )()xr;
            my $message = $e =~ s( \n \z )()xr =~ s( ^ )(    )xmgr;
            my $stage   = _label($pipeline, $names->[$n], $within->[$n]);
            die "Pipeline $stage failed$where:\n$message\n";
        }
    }
    return @results;
}


# Return the text of an end's error: a stop's own text, "Stop used
# outside a pipeline", would mislead, as the stop was in a run.
sub _end_error ($error) {
    return 'Expected no stop in an end, as the run has ended'
        if $error isa 'Ekorn::Pipeline::Stop';
    return "$error";
}


# Call each end given, as [$label, $end, $how], in order. While the run
# is dying, an end that dies is reported as a warning naming it, and the
# rest are called. Otherwise, an end that dies tells every end after it
# "died", and its error is thrown once they've run.
sub _end_all ($ends, $dying) {
    my($error, $failed);
    for my $call (@$ends) {
        my($label, $end, $how) = @$call;
        try {
            local $_ = undef;
            $end->($dying || defined $error ? 'died' : $how);
        }
        catch ($e) {
            if ($dying || defined $error) {
                Carp::carp sprintf 'The end of %s died while the run was already dying: %s',
                    $label, _end_error($e) =~ s( \n \z )()xr;
            }
            else {
                ($error, $failed) = ($e, $label);
            }
        }
    }
    return unless defined $error;
    # A stop from an end is an error like any other: the run has ended.
    croak $error if is_ref($error) && !($error isa 'Ekorn::Pipeline::Stop');
    my $at      = Carp::shortmess()  =~ s( \.? \n \z )()xr;
    my $message = _end_error($error) =~ s( \n \z )()xr =~ s( ^ )(    )xmgr;
    die "Pipeline end of $failed failed$at:\n$message\n";
}


# Make the parts of a run from @$stages, named by @$names, into the
# lists in %$run: each part's step, its flush and its end, by its role
# method, and whether it's a sink. A gather's block may return a
# pipeline as its step, whose stages are made in its place, followed by
# the gather's flush and end, if any, on a stage of their own that
# passes values on.
sub _make_run ($stages, $names, $within, $run) {
    for my $i (0 .. $#$stages) {
        my($stage, $name) = ($stages->[$i], $names->[$i]);
        my $role = _stage_role($stage) // '';
        my($step, $flush, $end);
        if ($stage isa 'Ekorn::Pipeline::Gather') {
            my @made = _parts([qw(step flush end)], $stage->EKORN_STAGE);
            my($inner, $inner_names, $inner_within)
                = @made && $made[0] isa 'Ekorn::Pipeline' ? _composed($made[0]) : ();
            croakf
                'Expected stage #%s, made with gather, to return a code reference or a pipeline, and optionally a flush and an end',
                $name
                unless (@made == 1 || @made == 2 || @made == 3)
                && ($inner ? $inner_names : is_coderef($made[0]))
                && _code_or_none(@made[1 .. $#made]);
            ($step, $flush, $end) = @made;
            if ($inner) {
                _make_run(
                    $inner,
                    [map { "$name.$_" } @$inner_names],
                    [
                        map { [
                            @{ $within->[$i] }, [$made[0], $inner_names->[$_]],
                            @{ $inner_within->[$_] },
                        ] } 0 .. $#$inner
                    ],
                    $run,
                );
                next unless $flush || $end;
                $step = sub ($value) { $value };
            }
        }
        elsif ($role eq 'EKORN_SINK_ONE' || $role eq 'EKORN_SINK_MANY') {
            ($step, $flush, $end) = _parts([qw(step flush end)], $stage->$role);
            croakf
                'Expected sink #%s to return a code reference, a flush, and optionally an end',
                $name
                unless is_coderef($step)
                && is_coderef($flush)
                && _code_or_none($end);
            # What a sink's step returns is ignored, by the run, which knows
            # it's a sink; a scalar sink's flush gives one value, undef if
            # it has none.
            my $result = $flush;
            $flush = sub () { my @result = $result->(); return $result[0] }
                if $role eq 'EKORN_SINK_ONE';
        }
        elsif ($role eq 'EKORN_STAGE') {
            ($step, $flush, $end) = _parts([qw(step flush end)], $stage->EKORN_STAGE);
            croakf
                'Expected stage #%s to return a code reference, and optionally a flush and an end',
                $name
                unless is_coderef($step) && _code_or_none($flush, $end);
        }
        else {
            $step = $stage;
        }
        push @{ $run->{stages} },  $step;
        push @{ $run->{names} },   $name;
        push @{ $run->{within} },  $within->[$i];
        push @{ $run->{flushes} }, $flush;
        push @{ $run->{ends} },    $end;
        push @{ $run->{sinks} },
            $role eq 'EKORN_SINK_ONE' || $role eq 'EKORN_SINK_MANY';
    }
    return;
}


# Return an iterator handing out, one per call, the values from $source
# run through the stages in @$stages, named in messages by @$names.
#
# The run ends as soon as nothing in it can still act on a value: the
# source has run out or stopped, every flush has been called, and every
# value still to be handed out has passed the last stage; or when it's
# ended from outside, or dies. Then each end is called, the source's
# first, told how the run ended from where it stands: "died" if the run
# died; else "done" if its input ran out, and "stopped" if not.
sub _iterator ($pipeline, $stages, $names, $within, $source) {
    my %run = (
        stages => [], names => [], within => [], flushes => [], ends => [],
        sinks  => [],
    );
    # A stage named in a message: by its place, and, if it's within a named
    # pipeline, the innermost, by its name and its place in it.
    my $label = sub ($n) {
        return _label($pipeline, $run{names}[$n], $run{within}[$n]);
    };
    my($pull, $source_end, $context);
    try {
        ($pull, $source_end, $context) = _source_run($source);
        _make_run($stages, $names, $within, \%run);
    }
    catch ($e) {
        _end_all(
            [
                ($source_end ? ['the source', $source_end, 'died'] : ()),
                map { [$label->($_), $run{ends}[$_], 'died'] }
                    grep { $run{ends}[$_] } 0 .. $#{ $run{ends} },
            ],
            1,
        );
        # A set-up runs before the run has values, so has nothing to stop.

        croakf 'Expected no stop in a set-up, as the run has nothing yet to stop'
            if $e isa 'Ekorn::Pipeline::Stop';
        croak $e if is_ref($e);
        die $e;    ## no critic (ErrorHandling::RequireCarping): thrown again, as it was
    }
    my @stages  = @{ $run{stages} };
    my @flushes = @{ $run{flushes} };
    my @ends    = @{ $run{ends} };
    my @sinks   = @{ $run{sinks} };
    # The places of the stages with a flush, so finding the next needn't
    # look at every stage.
    my @flush_at = grep { $flushes[$_] } 0 .. $#stages;
    # Each value waiting to go through a stage, as the stage's index, the
    # value, and whether it came from a flush, the next on top. A value a
    # stage returns on its own, as most are, carries on through the stages
    # without waiting here. Once the source is done, the flushes are called
    # in order, from the first not called or passed over by a stop.
    my(
        @todo,  $done,  $source_done, %flushed, @input_done, $finished, $outside,
        $ended, $spent, $dropped,
    );
    my $next_flush = 0;
    # How many values wait at each stage's index, kept as @todo changes, so
    # asking whether any wait before a stage needn't scan @todo: a flush
    # can put many values there at once.
    my @waiting_at;
    # Values a source's step gave, still to go through the stages from the
    # first, held as they came: @todo's values go first, being further on.
    my @from_source;
    # Put @values on @todo, to go on from stage $n, the first on top.
    my $wait = sub ($n, $from_flush, @values) {
        push @todo, map { [$n, $_, $from_flush] } reverse @values;
        $waiting_at[$n] += @values;
        return;
    };
    # Whether any value waits at a stage up to $upto.
    my $waiting_upto = sub ($upto) {
        return 1 if @from_source && $upto >= 0;
        $waiting_at[$_] && return 1 for 0 .. $upto;
        return 0;
    };
    # How the run ended, as its caller asks: whether the source was read
    # to its end, "stopped" if values still to be handed out were dropped,
    # or "died" if anything died, an end included.
    my $finish = sub ($died) {
        return if $finished++;
        $ended
            = $died        ? 'died'
            : $dropped     ? 'stopped'
            : $source_done ? 'done'
            :                'stopped';
        my @calls;
        push @calls, ['the source', $source_end, $source_done ? 'done' : 'stopped']
            if $source_end;
        push @calls,
            map { [
                $label->($_), $ends[$_], $input_done[$_] ? 'done' : 'stopped',
            ] }
            grep { $ends[$_] } 0 .. $#ends;
        local $running{context} = $context;
        try {
            _end_all(\@calls, $died);
        }
        catch ($e) {
            # An end died: the run died, and hands out nothing more.
            ($ended, $spent, @todo, @waiting_at, @from_source) = ('died', 1);
            die $e;    ## no critic (ErrorHandling::RequireCarping): thrown again, as it was
        }
        return;
    };
    # The index of the next flush to call, if any.
    my $flush_at = sub () {
        for my $n (@flush_at) {
            return $n if $n >= $next_flush && !$flushed{$n};
        }
        return;
    };
    # Every part from the next flush up to $upto has had all its input.
    my $input_ran_out = sub ($upto) {
        $input_done[$_] = 1 for $next_flush .. $upto;
        return;
    };
    # At a stop at stage $n, with nothing more to come from upstream,
    # every stage up to it whose input had run out: none of its values
    # still waiting, and no flush before it still to be called.
    my $input_ran_out_at_stop = sub ($n) {
        for my $stage ($next_flush .. $n) {
            last if $waiting_upto->($stage);
            last if grep { $flushes[$_] && !$flushed{$_} } $next_flush .. $stage - 1;
            $input_done[$stage] = 1;
        }
        return;
    };
    # End the run if nothing in it can still act on a value. Called only
    # once the source is done.
    my $end_if_ended = sub () {
        return if $finished || defined $flush_at->();
        return if $waiting_upto->($#stages);
        $input_ran_out->($#stages);
        $finish->(0);
        return;
    };
    # Where all collects every value still to come, while it does: the
    # loop pushes them onto it, with no return between values. Otherwise,
    # the loop returns the next value.
    my $into;
    my $next = sub () {
        return if $outside;
        while (1) {
            if ($into) {
                # All takes at once a step's values where there are no
                # stages, and the values already at the end, such as a list
                # sink's result.
                if (!@stages && @from_source) {
                    push @$into, splice @from_source;
                    next;
                }
                if (@todo && $todo[-1][0] == @stages) {
                    while (@todo && $todo[-1][0] == @stages) {
                        push @$into, (pop @todo)->[1];
                        $waiting_at[@stages]--;
                    }
                    next;
                }
            }
            my($n, $value, $from_flush, $flush);
            if (@todo) {
                ($n, $value, $from_flush) = @{ pop @todo };
                $waiting_at[$n]--;
            }
            elsif (@from_source) {
                ($n, $value) = (0, shift @from_source);
            }
            elsif (!$done) {
                # Straight onto @from_source, which is empty here.
                try {
                    @from_source = $pull->();
                }
                catch ($e) {
                    if ($e isa 'Ekorn::Pipeline::Stop') {
                        # A source that stops has had enough: what it
                        # carries is its last, and it's done.
                        my(undef, @carried) = is_arrayref($e) ? @$e : ();
                        ($done, $source_done) = (1, 1);
                        @from_source = @carried;
                        next;
                    }
                    ($done, $next_flush, @todo, @waiting_at, @from_source)
                        = (1, scalar @stages);
                    $finish->(1);
                    croak $e if is_ref($e);
                    die $e;    ## no critic (ErrorHandling::RequireCarping): thrown again, as it was
                }
                unless (@from_source) {
                    ($done, $source_done) = (1, 1);
                    next;
                }
                ($n, $value) = (0, shift @from_source);
            }
            else {
                $n = $flush_at->();
                unless (defined $n) {
                    $end_if_ended->();
                    last;
                }
                $input_ran_out->($n);
                $flushed{$n} = 1;
                ($next_flush, $flush, $from_flush) = ($n + 1, $flushes[$n], 1);
            }
            if ($n == @stages) {
                # Nothing can end while the source is still being read.
                $end_if_ended->() if $done;
                return $value     unless $into;
                push @$into, $value;
                next;
            }
            # Set only when it changes, as most values come from the source,
            # and most runs, and the code running them, have no context.
            local $running{ending} = $from_flush
                if $from_flush || $running{ending};
            local $running{context} = $context
                if defined $context || defined $running{context};
            my $kept = 1;
            try {
                if ($flush) {
                    local $_ = undef;
                    my @values = $flush->();
                    $n++;
                    $kept  = @values;
                    $value = shift @values;
                    $wait->($n, 1, @values) if @values;
                }
                while ($kept && $n < @stages) {
                    local $_ = $value;
                    my @values
                        = $sinks[$n]
                        ? do { $stages[$n]->($value); () }
                        : $stages[$n]->($value);
                    last if $outside;
                    $n++;
                    unless (@values) {
                        $kept = 0;
                        last;
                    }
                    $value = shift @values;
                    $wait->($n, $from_flush, @values) if @values;
                }
            }
            catch ($e) {
                if ($e isa 'Ekorn::Pipeline::Stop') {
                    # A stop made by throw is an array; one made otherwise
                    # carries nothing. A sink that stops the run still
                    # gives its result.
                    my(undef, @values) = is_arrayref($e) ? @$e : ();
                    $input_ran_out_at_stop->($n) if $done;
                    $done = 1;
                    my $from = $sinks[$n] && !$flushed{$n} ? $n : $n + 1;
                    $next_flush = $from if $next_flush < $from;
                    (@todo, @waiting_at, @from_source) = ();
                    $wait->($n + 1, $from_flush, @values);
                    next;
                }
                # A stage or a flush that dies ends the run: nothing waiting
                # goes on, and every end is told it died.
                ($done, $next_flush, @todo, @waiting_at, @from_source)
                    = (1, scalar @stages);
                $finish->(1);
                croak $e if is_ref($e);
                my $at      = Carp::shortmess() =~ s( \.? \n \z )()xr;
                my $message = $e =~ s( \n \z )()xr =~ s( ^ )(    )xmgr;
                my $stage   = $label->($n);
                die "Pipeline $stage failed$at:\n$message\n";
            }
            return if $outside;
            if ($kept) {
                $end_if_ended->() if $done;
                return $value     unless $into;
                push @$into, $value;
            }
        }
        # Everything has been handed out: the iterator is spent.
        $spent = 1;
        return;
    };
    # Every value the run has still to give, as $next would give them one
    # at a time, but in one call of it.
    my $all = sub () {
        my @all;
        $into = \@all;
        try {
            $next->();
        }
        catch ($e) {
            $into = undef;
            die $e;    ## no critic (ErrorHandling::RequireCarping): thrown again, as it was
        }
        $into = undef;
        return @all;
    };
    # Ended from outside, by the iterator's finish or as it's let go, the
    # run stops: nothing more is pulled, and nothing waiting goes on.
    my $end_run = sub () {
        $outside = 1;
        # A run that died has nothing waiting: its values were dropped then.
        $dropped = 1 if @todo || @from_source;
        ($done, $next_flush, @todo, @waiting_at, @from_source)
            = (1, scalar @stages);
        $finish->(0);
        $ended = 'stopped' if $dropped;
        return;
    };
    return Ekorn::Pipeline::Iterator->new(
        $next, $end_run, $context,
        # How the run ended, held back until the iterator has nothing more
        # to give, so it's said once, and doesn't change.
        sub () {
            return $ended if $spent || $outside || ($ended // '') eq 'died';
            return;
        },
        sub () { $spent || $outside || ($ended // '') eq 'died' },
        $all,
    );
}
1;
__END__

=encoding utf8

=for stopwords flatMap invocant's

=head1 NAME

Ekorn::Pipeline - run values through a list of stages

=head1 SYNOPSIS

    use Ekorn::Pipeline;

    my $p = Ekorn::Pipeline->new(
        sub { $_->{active} ? $_ : () },          # filter
        sub ($user) { @{ $user->{roles} } },     # flatMap
        sub { uc },                              # map
    );

    # Push: values in, a list out
    my @roles = $p->(@users);

    # Pull: one value per call, from a source
    my $next = $p->iterator(sub { shift @queue // () });
    while (my($role) = $next->()) { ... }

    # A function of your own, taking stages from its caller
    sub lines_of ($file, @stages) {
        open my $fh, '<', $file or die "Can't read $file: $!\n";
        return Ekorn::Pipeline->new(@stages)->iterator(sub { scalar(<$fh>) // () });
    }

    # Named pipelines, and pipeline() to make one from stages and names
    use Ekorn::Pipeline::Factories qw(pipeline);

    Ekorn::Pipeline->named(clean => sub { s( \A \s+ | \s+ \z )()xgr });
    my @first = pipeline(
        'clean',
        sub { length ? $_ : () },
    )->(@lines);

=head1 DESCRIPTION

A pipeline is a list of stages. A stage is a code reference; another
pipeline, which stands for its own stages (see L</A pipeline as a
stage>); a stage made for each run, with L<Ekorn::Pipeline::Gather>;
or a sink, which consumes the values and gives a result (see
L<Ekorn::Pipeline::Sink>).

A code reference is called with one value, both as its argument and in
C<$_>. It can name the value with a signature, C<sub ($row) {
$row-E<gt>[1] }>, or use C<$_>, C<sub { $_-E<gt>[1] }>. C<$_> is
localised for each call, so the caller's is left alone. It returns a
list:

=over

=item * nothing, to drop the value (a filter);

=item * one value, to pass it on (a map);

=item * several, each of which goes through the rest of the stages
on its own (a flatMap).

=back

Each value goes through every stage before the next one starts. The
values come out in order, and each stage sees them in the order a
C<for> loop would.

A stage can end the pipeline early with L<Ekorn::Pipeline::Stop>. The
values already out are kept, and any values the stop carries go on
through the rest of the stages. Nothing else is processed:

    sub ($row) { $row->{id} == $wanted ? Stop($row) : () }

Each call of a pipeline with values is a run, and so is each
iterator. A stage made with L<Ekorn::Pipeline::Gather> is made afresh
for each run, and so are a source and a sink, so a run can open a file,
or start a transaction, and close or commit it when it ends, however
it ends: see L</RUNS AND HOW THEY END>.

=head2 Stages from your caller

A pipeline is for the author of any function that hands out values.
The function takes stages from its caller, as its last arguments, and
runs what it would return through them. The caller says what they want
done with each value, beside the call, and gets back only what they
want:

    sub bands (@stages) {
        return Ekorn::Pipeline->new(@stages)->(load_bands());
    }

    my @names = bands(
        sub { $_->{name} },
        take(5),
    );

With L</iterator>, the values are made one at a time, as the caller
asks for them. A function reading a file or a socket reads no more
than it has to. Once a stage has stopped the pipeline, the source isn't
called again.

Values can come from a source, given to L</iterator>: a code
reference, or one made with L<Ekorn::Pipeline::Source>, which is told
when the run ends. And a pipeline can end in a sink, such as
C<keep_all> or C<count_items>, from L<Ekorn::Pipeline::Sinks>, whose
result is what the run gives.

The canned stages, in L<Ekorn::Pipeline::Stages::Flow>,
L<Ekorn::Pipeline::Stages::Batch> and L<Ekorn::Pipeline::Stages::Taps>,
work in any pipeline. L<Ekorn::Pipeline::Pipes> gives a class of your
own C<pipe> and C<tap> methods, which run an object through stages.

=head1 METHODS

=head2 new

    my $p = Ekorn::Pipeline->new(@stages);

Returns a pipeline that runs values through C<@stages>, in order. Each
stage must be something L</is_stage> is true for: a code reference; a
pipeline (see L</A pipeline as a stage>); or a part offering one of the
role methods C<EKORN_STAGE>, C<EKORN_SINK_ONE> and C<EKORN_SINK_MANY>,
such as a gather or a sink. Anything else croaks, a source included.
With no stages, a pipeline returns its values unchanged.

A pipeline is an object that can be called as a code reference. Called
with values, it returns the list that comes out of the last stage:

    my @results = $p->(@values);

In scalar context, it returns how many results came out, as an array
would:

    my $count = $p->(@values);

Unless its last stage is a sink: then a run gives the sink's result. In
list context, that's the sink's list, or a sink of one's one value. In
scalar context, a sink of one gives its value, and a sink of many its
list as an array reference:

    my $n    = Ekorn::Pipeline->new(count_items)->('a', 'b');    # 2
    my $kept = Ekorn::Pipeline->new(keep_all)->('a', 'b');       # ['a', 'b']

=head3 A pipeline as a stage

You can give C<new> a pipeline wherever it takes a stage. Its stages
are spliced in where it stands, so these two run the same:

    my $clean = Ekorn::Pipeline->new(
        sub { s( \A \s+ | \s+ \z )()xgr },
        sub { length ? $_ : () },
    );

    Ekorn::Pipeline->new(
        $clean,
        take(10),
    );
    Ekorn::Pipeline->new(
        $clean->stages,
        take(10),
    );

The spliced stages belong to the new pipeline's run. A C<take> inside
C<$clean> limits the whole run, not each value.

The only difference is in error messages. Given C<$clean> itself, a
stage inside it is named by its position in each pipeline: the third
stage of a pipeline given second is C<#2.3>, and three levels down,
C<#1.2.3>. Given C<< $clean->stages >>, it's named by its position in
the combined list.

The stages spliced in are whatever the pipeline's L</stages> method
returns, so a subclass can override it. If the override returns a
different list, its stages are named by their position in that list.

To run a pipeline on each value separately instead, call it from a
stage: C<sub { $clean-E<gt>($_) }>. Each call is then a run of its
own, and a C<take> inside limits each call.

=head2 named

    Ekorn::Pipeline->named(clean => @stages);         # define from stages
    Ekorn::Pipeline->new(@stages)->named('clean');    # name one you have

Names a pipeline, and returns it. On the class, it makes a pipeline of
the stages after the name, each a code reference, a pipeline or the
name of one, as L</pipeline_in> takes them, looked up in its caller's
package; a subclass makes one of its own class. On a pipeline, it
names that one, and croaks if given stages after the name.

The name is kept in the caller's package, unless it's qualified, as
L</Named pipelines> explains. A name is identifiers, as Perl's, joined
by C<::>, such as C<clean> or C<My::Module::clean>. It's new in v0.3.0.

A name can't be defined twice for another pipeline, which croaks,
whatever class C<named> was called on. Naming the same pipeline again,
with C<< $p->named('clean') >>, is no mistake; but C<named> on a class
always makes a new pipeline, even from a single pipeline, so calling
C<< Ekorn::Pipeline->named(clean => $p) >> twice croaks. A name can't
be removed, so define each once, as a program or module loads.

=head3 Named pipelines

A named pipeline is kept for the life of the program, in a package,
which says whose name it is, so two modules can each have a
C<clean>.

=over

=item * C<named> keeps a name in the package that called it, and
the word C<pipeline> and C<named> look one up in the package that
called them, so two modules can each have a C<clean> of their own.

=item * A qualified name, such as C<My::Module::clean>, is that
package's, wherever it's used. Code that names or looks up pipelines on
another package's behalf qualifies them: C<"${package}::clean">.

=item * A name is resolved when the pipeline is made, not when it runs,
and the pipeline it names is spliced in, as a pipeline given to L</new>
is. So a pipeline, once made, keeps the pipelines it found, whatever's
defined or overridden later. A name alone, C<pipeline('clean')>, gives
that pipeline itself, and C<named> on a class always makes a new one,
even of one name, so a name never aliases another.

=item * Only L</pipeline_in>, which the word C<pipeline> calls, and
C<named> read names. L</new> doesn't, and L</is_stage> is false for a
string.

=back

=head2 name

    my $name = $p->name;

Returns the first name the pipeline was given with L</named>,
qualified by its package, as C<main::clean>, or C<undef> if it has
none. Errors in its stages name it (see L</DIAGNOSTICS>). It's new in
v0.3.0.

=head2 pipeline_in

    Ekorn::Pipeline->pipeline_in($package, @stages)

Returns a new pipeline of its invocant's class, of C<@stages>, each a
code reference, a pipeline, or the name of one, looked up in
C<$package> unless it's qualified, as L</Named pipelines> explains. It's
the only method that reads names, and it's what the word C<pipeline>,
from L<Ekorn::Pipeline::Factories>, calls, with its caller's package.
Given one name and nothing else, it returns the pipeline named itself,
if it's of the invocant's class or a subclass, so its stages are
numbered where it's given, and in a new pipeline of the invocant's
class otherwise:

    use Ekorn::Pipeline::Factories qw(pipeline);

    # A new pipeline, from stages:
    pipeline(
        sub { uc },
        take(5),
    );

    # The pipeline named clean, itself:
    pipeline('clean');

    # A new pipeline: the one named clean, then more stages:
    pipeline(
        'clean',
        take(5),
    );

    # Another package's, qualified:
    pipeline(
        'My::Module::clean',
        sub {...},
    );

Call it from code the user calls directly, passing the user's package,
as the word does with C<scalar caller>. Code that passes stages
through, such as a function taking stages from its caller, gives them
to L</new>, which reads no names: the user has already turned any
names into pipelines with C<pipeline>, where they wrote them. If C<new>
read names, it would look them up in the package of whatever called
it, which, for a function passing its caller's stages on, isn't the
caller's.

A function whose values can be code references can't tell them from
stages with L</is_stage>, but it can take a pipeline given last as its
stages, which a caller makes with C<pipeline>:

    sub call_all (@callbacks) {
        my $stages = @callbacks && $callbacks[-1] isa 'Ekorn::Pipeline' ? pop @callbacks : pipeline();
        return $stages->(map { $_->() } @callbacks);
    }

    call_all(@callbacks, pipeline(
        sub { $_ * 10 },
        take(2),
    ));

It's new in v0.3.0, as is the word C<pipeline>.

=head2 iterator

    my $next = $p->iterator($source);

Returns an iterator, an L<Ekorn::Pipeline::Iterator>, which hands out
the values that come out of the stages, one per call. C<$source> is a
code reference that returns the next value or values each time it's
called, and an empty list when there are no more; or anything offering
an C<EKORN_SOURCE> method, such as an L<Ekorn::Pipeline::Source>, made
for the run and told when it ends, or another iterator. It's called
only once the values from its last call have all been handed out.

The iterator returns an empty list when the values run out, and on
every call after that. After a stop, it returns an empty list once the
values the stop carried are handed out, and the source isn't called
again. Read it in list context, so that an C<undef> value isn't
mistaken for the end:

    while (my($x) = $next->()) { ... }

The flushes of gathers and sinks are called once their input runs
out, before the iterator returns an empty list. The run's ends are
called as it ends, as L</RUNS AND HOW THEY END> describes. The
iterator has methods of its own, to pull every value still to come,
or the first, and to end the run early: see
L<Ekorn::Pipeline::Iterator>.

If a stage or a flush dies, the call dies with it, and the run has
ended, as a pushed run does. Every call after returns an empty list.
Nothing waiting goes on through the stages, no flush is called, and
the source isn't called again; each end is called, told C<died>, before
the error is thrown again. To skip a bad value and carry on, catch the
error inside the stage.

=head2 stages

    my @stages = $p->stages;

Returns the pipeline's stages, in order. A pipeline that was given as
a stage appears as the stages it was made of. In scalar context, it
returns how many there are.

The list can go anywhere stages go: to L</new>, or to a function that
takes stages. Each is one of Ekorn's types, an object called as a code
reference: a code reference given to C<new> comes back as an
L<Ekorn::Pipeline::Stage> of it. So a function that takes only plain
code references, testing them with C<is_coderef> or C<ref>, won't take
them; v0.2.0 gave the code references themselves.

    my $clean  = Ekorn::Pipeline->new(
        sub { s( \A \s+ | \s+ \z )()xgr },
        sub { length ? $_ : () },
    );
    my @titles = Ekorn::Pipeline->new(
        $clean->stages,
        take(10),
    )->(@raw);

To give C<new> the pipeline itself, see L</A pipeline as a stage>.
Either way, the stages run as if they had been written out in full:

=over

=item * A stop in one of them ends the whole run.

=item * A stage made with L<Ekorn::Pipeline::Gather> starts afresh on
each run, so pipelines that share it don't share its state.

=item * A plain closure is the same code reference wherever it goes,
so anything it keeps is shared. Keep state in C<gather> instead.

=item * A stage that dies is named by its position, as
L</A pipeline as a stage> describes.

=back

=head1 RUNS AND HOW THEY END

A run is one call of a pipeline with values, or one iterator made from
it. Each run has its own state. A part of the pipeline that needs
state, such as a batch it's filling or a file it has open, is made
afresh for each run.

=head2 Made for a run

A gather (L<Ekorn::Pipeline::Gather>), a source
(L<Ekorn::Pipeline::Source>) or a sink (L<Ekorn::Pipeline::Sink>) has a
I<set-up>, a code reference called at the start of each run. It
declares whatever the run needs, with C<my>, and returns closures
sharing what it declared:

=over

=item * the I<step>, called with each value (a gather or a sink), or
each time the source is pulled (a source);

=item * the I<flush>, for a gather or a sink, called once its input
runs out, what it returns going on through the stages after it. A
sink's gives its result, and is required;

=item * the I<end>, called once, when the run has ended, told how. It's
optional;

=item * a I<context>, for a source only, and optional: anything its
stages may ask for with L</run_context>.

=back

Two iterators of the same pipeline each get their own, from their own
call of the set-up. A plain code reference is never made for a run:
it's the same code, with the same closure, in every run.

The set-up returns its parts as a list, in the order above, leaving
out those it doesn't give from the end, and giving C<undef> for one it
leaves out before one it gives. Or it returns them I<by name>, as a
hash reference whose keys are C<step>, C<flush>, C<end> and
C<context>, giving only those it has, in any order:

    gather {
        my $n = 0;    # this run's
        return {
            step => sub ($x)   { $n++; $x },
            end  => sub ($how) { $$total = $n },
        };
    }

A key Ekorn doesn't read is ignored, and a hash without what its part
needs, a step, and a sink's flush, croaks, as a list without them
does. Only a plain hash reference returned alone is taken for parts by
name. Parts by name are new in v0.3.0.

Any object can take part, by offering a role method that does what a
set-up does, returning the same parts, as a list or by name:
C<EKORN_SOURCE>, C<EKORN_STAGE>, C<EKORN_SINK_ONE> or
C<EKORN_SINK_MANY>. L<Ekorn::Pipeline::Manual::Reference/Delivering
parts for Ekorn> has how.

=head2 How a run ends

A run ends in one of three ways, and each part's end is told which,
from where the part stands:

=over

=item * C<died>, if the run died, anywhere, before it ended;

=item * C<stopped>, if its input was cut short, by a stop at or after
it, or by the run being ended from outside, as an iterator's
L<finish|Ekorn::Pipeline::Iterator/finish> does;

=item * C<done>, if its input ran out, and the run didn't die. A part
whose input had run out before a stop is told C<done>, and so is a
sink that stops the run itself.

=back

So a stop ends the stream early for what's before it, and normally
for what's after it. In

    my $n = Ekorn::Pipeline->new(
        take(5),
        count_items,
    )->iterator($lines)->();

C<$lines> is told C<stopped>, and closes its file, and C<count_items>,
after C<take(5)>, is told C<done>, and gives 5.

=head2 Flushes and ends

A flush is called once its part's input runs out normally: when the
values ran out, after a stop in a stage before it, or, for a sink, when
the sink stopped the run itself. What it returns goes on through the
stages after it, and while it runs, and they do, L</ending> is true. It
isn't told how the run ended, as the run hasn't.

An end:

=over

=item * always runs, once, when the run has ended, however it ended,
and is given how, as its argument: C<done>, C<stopped> or C<died>. A
run has ended as soon as nothing in it can still act on a value. With
a sink last, that's as the sink's result is ready, so a sink that
commits only when told C<done> commits then, and never for a run that
dies after it;

=item * gives nothing: what it returns is dropped;

=item * runs in order: the source's end first, then each stage's,
first stage first, so a source that fails to close is known before any
sink commits.

=back

After a stage dies, every end still runs, told C<died>, and then the
error is thrown again, as it would have been. An end that dies then is
reported as a warning, naming its stage, and the first error is kept.
An end that dies in a run that hadn't died ends the run with its
error, and the ends after it are told C<died>.

An iterator dropped before its values run out ends its run when the
last reference to it goes, as L<Ekorn::Pipeline::Iterator> describes.

=head1 FUNCTIONS

=head2 is_stage

    use Ekorn::Pipeline v0.1.3 qw(is_stage);

    is_stage($thing)

True if C<$thing> can be used as a stage: a code reference; a pipeline
of this class or a subclass; or an object offering one of the role
methods C<EKORN_STAGE>, C<EKORN_SINK_ONE> and C<EKORN_SINK_MANY>, such
as a stage made with L<Ekorn::Pipeline::Gather>, or a sink. It's the
same test L</new> uses. It's false for a string, even the name of a
pipeline, and for a source.

Use it in a function that takes its stages from the end of its
arguments, so that it accepts the same stages C<new> does, pipelines
included:

    sub fetch ($url, @args) {
        my @stages;
        unshift @stages, pop @args while @args && is_stage($args[-1]);
        ...
    }

It's exported on request. It's new in v0.1.3, so ask for that version
on the C<use> line, as above: v0.1.2 has no C<import>, so without the
version, C<use Ekorn::Pipeline qw(is_stage)> compiles under it, and
fails only when C<is_stage> is called.

A pipeline is a blessed hash, so C<is_hashref> is true of one too. A
function that takes a hash reference of options before its stages
should test C<is_stage> first, or it takes a pipeline for the options.

=head2 is_sink

    use Ekorn::Pipeline qw(is_sink);

    is_sink($thing)

Returns C<one> if C<$thing> is a sink of one, giving one value, and
C<many> if it's a sink of many, giving a list; for a pipeline, the sink
it ends in, if any. Both are true. It's false for anything else. A sink
is anything offering C<EKORN_SINK_ONE> or C<EKORN_SINK_MANY>, as
L<Ekorn::Pipeline::Sink> describes. It's exported on request.

=head2 ending

    Ekorn::Pipeline::ending()

True while a flush runs, and while the values it gave go through the
stages after it, rather than values from the source. It's for code that
tells its stages more about each value, such as where it came from: a
value from a flush has no such origin. It isn't exported.

=head2 run_context

    Ekorn::Pipeline::run_context()

Returns the context the run's source gave, if any: its C<context>, or
the third part its C<EKORN_SOURCE> method returned as a list, such as
a statement's column names. It's for stages that need to know about
the values' source, called as they run. Each run has its own. A pushed
run has none, and an iterator used as a source passes on its own
run's. It isn't exported.

    sub pluck ($name) {
        return sub ($row) {
            my $columns = Ekorn::Pipeline::run_context()->{columns};
            my($at) = grep { $columns->[$_] eq $name } 0 .. $#$columns;
            return $row->[$at];
        };
    }

=head1 DIAGNOSTICS

=over

=item Expected stage #%d to be a stage: a code reference, a pipeline, or an object offering a stage's role method

A stage given to L</new> was something else, such as a string.

=item Expected stage #%d, a pipeline, to give only stages from its stages method

A stage given to L</new> was a pipeline whose overridden C<stages>
method returned something that isn't a stage.

=item Expected stage #%d to be a stage: a code reference, a pipeline or its name, or an object offering a stage's role method

A stage given to L</pipeline_in>, and so to the word C<pipeline>, or
to L</named> after the name, was none of them. For C<named>, stages
are counted from the first after the name.

=item No pipeline named %s

A name given to L</pipeline_in>, and so to the word C<pipeline>, or to
L</named>, isn't defined in that package. The name is given qualified,
so it says which package it was looked up in. It may be defined in
another package, which a qualified name reaches.

=item A pipeline named %s is already defined

L</named> was given a name already defined for another pipeline.

=item Expected a name, made of words joined by ::

L</named> was given something other than a name.

=item Expected only a name, naming a pipeline you have

L</named>, on a pipeline, was given stages after the name.

=item Expected stage #%d to be a stage, not a source

A source, something offering C<EKORN_SOURCE> and none of a stage's
role methods, was given as a stage. Give it to L</iterator> instead.

=item Expected stage #%d to offer one of EKORN_STAGE, EKORN_SINK_ONE and EKORN_SINK_MANY, not %s

A stage offered more than one of the role methods, so it couldn't say
which it is.

=item Expected a source: a code reference, or an object offering EKORN_SOURCE

The source given to L</iterator> was something else, such as a stage,
or a string.

=item Expected the source to return a code reference, and optionally an end and a context

A source's C<EKORN_SOURCE> returned something else. It's reported as
the run starts.

=item Expected stage #%s to return a code reference, and optionally a flush and an end

A stage's C<EKORN_STAGE> returned something else. It's reported as the
run starts.

=item Expected sink #%s to return a code reference, a flush, and optionally an end

A sink's C<EKORN_SINK_ONE> or C<EKORN_SINK_MANY> returned something
else. It's reported as the run starts.

=item Expected no stop in a set-up, as the run has nothing yet to stop

A set-up, or a role method, threw a L<Ekorn::Pipeline::Stop>. The ends
of the parts already made are called, told C<died>.

=item Pipeline end of %s failed at %s line %d:

An end died, in a run that hadn't died. The message it died with
follows, indented, and the end is named: C<the source>, or a stage by
its position, as C<stage #2>. An exception object is passed on
unchanged.

=item Expected no stop in an end, as the run has ended

An end threw a L<Ekorn::Pipeline::Stop>, which is an error like any
other there, reported as the message above.

=item The end of %s died while the run was already dying: %s

A warning: an end died in a run that had died. The run's own error is
thrown, once every end has run.

=item Expected stage #%s, made with gather, to return a code reference or a pipeline, and optionally a flush and an end

The block given to L<Ekorn::Pipeline::Gather/gather> for that stage
returned something else.

=item Pipeline stage #%s failed at %s line %d:

A stage, or its flush, died. The message it died with follows,
indented. An exception object is passed on unchanged.

In this message and the one above, a stage is named by its position:
C<#2> for the second stage, or C<#2.3> for the third stage of a
pipeline given as the second stage.

A stage within a named pipeline, or of the named pipeline run, is
named with it too: after its position, the innermost named pipeline
it's in, by its L</name>, and its position there, as C<#1.2
(main::clean#2)> for the second stage of the pipeline named C<clean>,
given as the first stage. It's the name the pipeline has when the
stage dies.

=back

=head1 SEE ALSO

L<Ekorn::Pipeline::Tooling>, to import everything from one place;
L<Ekorn::Pipeline::Factories>, the words; L<Ekorn::Pipeline::Sugar>,
pipelines named as the program compiles; L<Ekorn::Pipeline::Gather>,
L<Ekorn::Pipeline::Stop>, L<Ekorn::Pipeline::Source>,
L<Ekorn::Pipeline::Sink> and L<Ekorn::Pipeline::Iterator>, the types;
L<Ekorn::Pipeline::Stages::Flow>, L<Ekorn::Pipeline::Stages::Batch>,
L<Ekorn::Pipeline::Stages::Taps>, L<Ekorn::Pipeline::Sources>,
L<Ekorn::Pipeline::Sinks> and L<Ekorn::Pipeline::JSON>, the
ready-made parts; L<Ekorn::Pipeline::Operators>, for C<|>;
L<Ekorn::Pipeline::Pipes>; and L<DBIx::Squirrel>, where the pipeline
began

L<Ekorn::Pipeline::Manual::HowTo>, the user guide, tours the package
from the bottom up, with recipes, and
L<Ekorn::Pipeline::Manual::Reference> describes every module, function
and method in full.

=head1 AUTHOR

Iain Campbell E<lt>cpanic@cpan.orgE<gt>

=head1 LICENSE

Copyright (c) 2024-2026 by Iain Campbell.

This is free software; you can redistribute it and/or modify it under the
same terms as the Perl 5 programming language system itself.

=cut
