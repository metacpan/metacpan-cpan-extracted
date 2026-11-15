use v5.36;

package Ekorn::Pipeline::Sugar;

use experimental            qw(builtin);
use builtin                 qw(refaddr);
use Ref::Util               qw(is_plain_arrayref is_plain_hashref is_ref);
use Sub::Util               qw(set_subname);
use Ekorn::Pipeline         qw(is_stage);
use Ekorn::Pipeline::Errors qw(croakf);
use namespace::clean;

# Croak at the line that called Ekorn::Pipeline.
our @CARP_NOT = @Ekorn::Pipeline::Errors::INTERNAL;

# Name the pipelines defined after "pipeline", in the package that uses
# this module, and give it a function of each name.
sub import ($class, @args) {
    $class->import_into(scalar caller, @args);
    return;
}


# Name the pipelines defined after "pipeline" in $package, and give it a
# function of each name, as import does for its caller: for a module
# whose own sugar defines pipelines for its caller.
sub import_into ($class, $package, @args) {
    while (@args) {
        my $key = shift @args;
        croakf 'Expected pipeline, not %s', $key // 'undef'
            unless defined $key && $key eq 'pipeline';
        my $definitions = shift @args;
        my @pairs
            = is_plain_hashref($definitions) ? map { ($_, $definitions->{$_}) }
            sort keys %$definitions
            : is_plain_arrayref($definitions) ? @$definitions
            : croakf
            'Expected the pipelines after pipeline in a HASH or an ARRAY of pairs';
        croakf 'Expected the pipelines after pipeline in pairs of a name and an ARRAY'
            if @pairs % 2;
        _define($package, @pairs);
    }
    return;
}


# Check the definitions given, as pairs of a name and an array of
# stages, then name each pipeline in $package, and give it a function of
# its name, each once those it names from the same pairs are.
sub _define ($package, @pairs) {
    my(@names, %stages);
    while (my($name, $stages) = splice @pairs, 0, 2) {
        croakf 'Expected a name for a pipeline (%s)', $name // 'undef'
            unless defined $name && $name =~ m( \A [^\W\d] \w* \z )x;
        croakf 'Expected a pipeline defined once (%s)', $name
            if $stages{$name};
        croakf 'Expected the pipeline %s in an ARRAY', $name
            unless is_plain_arrayref($stages);
        croakf 'Expected no function of the name in %s already (%s)', $package, $name
            if $package->can($name);
        push @names, $name;
        $stages{$name} = $stages;
    }
    for my $name (_in_order($package, \@names, \%stages)) {
        my @stages   = @{ $stages{$name} };
        my $pipeline = Ekorn::Pipeline->pipeline_in($package, @stages);
        # A name alone gives the pipeline it names; a new one is made of
        # it, as named does, so a name never aliases another.
        $pipeline = Ekorn::Pipeline->new($pipeline)
            if @stages == 1 && !is_stage($stages[0]);
        $pipeline->named("${package}::$name");
        _install("${package}::$name", $pipeline);
    }
    return;
}


# Return the names in @$names in an order to define them in: each after
# those it names, from the same definitions, as given otherwise.
sub _in_order ($package, $names, $stages) {
    # The names each definition uses from the same definitions, itself
    # included, which makes a circle of one.
    my %needs;
    for my $name (@$names) {
        my @named = map { _local_name($package, $_) } @{ $stages->{$name} };
        $needs{$name} = [grep { $stages->{$_} } @named];
    }
    my(@order, %done);
    my $ready = sub ($name) {
        !$done{$name} && !grep { !$done{$_} } @{ $needs{$name} };
    };
    while (@order < @$names) {
        my($next) = grep { $ready->($_) } @$names;
        croakf q(Expected pipelines that don't name each other in a circle (%s)),
            join ', ', grep { !$done{$_} } @$names
            unless defined $next;
        push @order, $next;
        $done{$next} = 1;
    }
    return @order;
}


# Return the name a stage gives, without its package, if it's a name in
# $package; or nothing.
sub _local_name ($package, $stage) {
    return if !defined $stage || is_ref($stage);
    my($local) = $stage =~ m( \A \Q$package\E :: (\w+) \z )x;
    return $local if defined $local;
    return        if $stage =~ m( :: )x;
    return $stage;
}


# Install a function of the full name given, running values through the
# pipeline, and, given a pipeline last, through that after it.
#
# Making the pipeline of both costs more than running a few values
# through it, so the last one made is kept, with the pipeline it was
# made for, and used again while that's the one given, as in a loop.
# Only the last is kept: the one made holds the one given, for naming
# its stages in errors, so a cache of every one given would keep them
# all for ever.
sub _install ($name, $pipeline) {
    my($given, $both);
    my $function = sub (@values) {
        return $pipeline->(@values)
            unless @values && $values[-1] isa 'Ekorn::Pipeline';
        my $more = pop @values;
        ($given, $both) = ($more, Ekorn::Pipeline->new($pipeline, $more))
            unless $given && refaddr($given) == refaddr($more);
        return $both->(@values);
    };
    no strict 'refs';    ## no critic (TestingAndDebugging::ProhibitNoStrict)
    *{ $name } = set_subname($name, $function);
    return;
}

1;

__END__

=encoding utf8

=head1 NAME

Ekorn::Pipeline::Sugar - name pipelines as the program compiles, each with a function

=head1 SYNOPSIS

    use Ekorn::Pipeline::Sugar pipeline => {
        titles => [sub { $_->{title} }],
        top    => ['titles', take(3)],
    };

    my @titles = titles(@tracks);    # values in, a list out
    my @top    = top(@tracks);       # the first three titles
    my @loud   = top(@tracks, pipeline(sub { uc }));    # and more stages

    my $next = pipeline('top')->iterator($source);    # pulled

=head1 DESCRIPTION

A pipeline used in several places can be named once, as the program
compiles, rather than kept in a variable or wrapped in a sub. C<use
Ekorn::Pipeline::Sugar> takes C<pipeline> and the definitions after
it, each a name and an array of stages. Each pipeline is named in the
package that uses the module, as L<Ekorn::Pipeline/named> names it, so
C<pipeline('name')> finds it, and the package gets a function of each
name.

The definitions are a hash, C<{...}>, or an array of pairs, C<[...]>,
to read in order. A string where a stage goes names a pipeline, as it
does in C<pipeline> and C<named>: one from the same C<use>, or one
defined before it. A definition can name any other in the same C<use>,
in either order: each is defined once those it names are.

Nothing is exported: C<use> defines the names it's given, and nothing
else. A mistake croaks as the C<use> is compiled, at its line.

=head1 FUNCTIONS

=head2 A function of each name

    my @results = name(@values);
    my @results = name(@values, $pipeline);

Runs the values through the pipeline of that name, and returns what
comes out, in the caller's context, as calling the pipeline does: a
list in list context; in scalar context, a sink's result, or how many
values came out. Given a pipeline last, such as one made with the word
C<pipeline>, it runs them through that too, after the named one, so a
caller can add stages of their own. A pipeline is taken for stages
only last, so any other value, a code reference included, is a value.

Joining the two pipelines costs more than running a few values through
them, so the function keeps the last one it was given, joined, and
uses it again while that's the one given. Keep a pipeline you add
stages with in a variable, such as in a loop, rather than making it in
the call, and it's joined once. The function holds the last one given
until it's given another.

To pull values through it from a source, use the pipeline itself:
C<< pipeline('name')->iterator($source) >>.

=head1 METHODS

=head2 import_into

    Ekorn::Pipeline::Sugar->import_into($package, pipeline => {...});

Does what C<use> does, for C<$package> in place of its caller: for a
module whose own sugar takes pipelines, and hands them on, so they're
named in, and given to, the package that uses that module. The names
are read in C<$package>, as is a string naming a pipeline.

The names, and the functions the package has already, are checked
before any pipeline is defined. A stage that isn't one, or a name
another pipeline has, is found only as its definition is made, so the
definitions made before it stay made. For C<use>, that doesn't matter,
as the program stops; a module calling this inside an C<eval> should
know it.

=head1 DIAGNOSTICS

=over

=item Expected pipeline, not %s

C<use> was given something other than C<pipeline> and its
definitions.

=item Expected the pipelines after pipeline in a HASH or an ARRAY of pairs

C<pipeline> was followed by something else.

=item Expected the pipelines after pipeline in pairs of a name and an ARRAY

An array of definitions had an odd number of items.

=item Expected a name for a pipeline (%s)

A name can't be a function's: it's a word, of letters, digits and
underscores, not starting with a digit.

=item Expected a pipeline defined once (%s)

An array of definitions gave the name twice.

=item Expected the pipeline %s in an ARRAY

A definition wasn't an array reference of stages.

=item Expected no function of the name in %s already (%s)

The package has a function of that name already, its own or one it
inherits.

=item Expected pipelines that don't name each other in a circle (%s)

The definitions named, those left undefined, name each other, through
others or not, so none can be defined first.

=back

L<Ekorn::Pipeline>'s messages for stages and names are raised for a
definition as for C<pipeline>, such as "No pipeline named %s", for a
name defined nowhere, and "A pipeline named %s is already defined".

=head1 SEE ALSO

L<Ekorn::Pipeline>, whose C<named> names a pipeline as the program
runs; L<Ekorn::Pipeline::Factories>, whose C<pipeline> fetches one by
its name; and L<DBIx::Squirrel::Sugar>, which names databases and
statements the same way.

=head1 AUTHOR

Iain Campbell E<lt>cpanic@cpan.orgE<gt>

=head1 LICENSE

Copyright (c) 2026 by Iain Campbell.

This is free software; you can redistribute it and/or modify it under the
same terms as the Perl 5 programming language system itself.

=cut
