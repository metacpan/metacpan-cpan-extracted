use v5.36;

package Ekorn::Pipeline::Operators;

use experimental            qw(builtin);
use builtin                 qw(blessed);
use Ekorn::Pipeline         qw(is_sink is_stage);
use Ekorn::Pipeline::Errors qw(croakf);
use Ekorn::Pipeline::Gather qw();
use Ekorn::Pipeline::Sink   qw();
use Ekorn::Pipeline::Source qw();
use Ekorn::Pipeline::Stage  qw();
use namespace::clean;

# Croak at the line that called Ekorn::Pipeline.
our @CARP_NOT = @Ekorn::Pipeline::Errors::INTERNAL;

# The key in %^H marking the scopes where the operators are in force.
my $IN_FORCE = 'Ekorn::Pipeline::Operators';

# Put the operators in force for the rest of the scope being compiled:
# they work on Ekorn's types only in code that says so.
sub import ($class, @) {
    $^H{$IN_FORCE} = 1;    ## no critic (Variables::RequireLocalizedPunctuationVars): a pragma's import sets %^H for the scope being compiled
    return;
}


# Take the operators out of force for the rest of the scope.
sub unimport ($class, @) {
    delete $^H{$IN_FORCE};
    return;
}


# Croak unless the operators are in force where the line that used one
# was compiled.
sub _check_in_force ($operator) {
    my $hints = (caller 1)[10];
    croakf 'Expected use Ekorn::Pipeline::Operators in scope, for %s', $operator
        unless $hints && $hints->{$IN_FORCE};
    return;
}

# The | of two parts. From a source: with a scalar sink, the sink's
# result, at once; with a list sink, its list, as an array reference;
# with a stage, a chain, a source of the values through it. From a
# stage: a chain of stages, a pipeline with |. A class of sources of its
# own can overload | with this, to chain as Ekorn's do.
sub chain ($before, $after, $swapped = undef, @) {
    _check_in_force('|');
    ($before, $after) = ($after, $before) if $swapped;
    croakf 'Expected a source, or a stage made with a word, on the left of |'
        unless blessed($before) && (_is_source($before) || is_stage($before));
    # A pipeline made with new has no operators, though Perl swaps the
    # sides to call one for a typed part on its right.
    croakf 'Expected a source, or a stage made with a word, on the left of |'
        if $before isa 'Ekorn::Pipeline'
        && !($before isa 'Ekorn::Pipeline::Operators::Stages');
    croakf 'Expected a stage or a sink on the right of |' unless is_stage($after);
    unless (_is_source($before)) {
        return Ekorn::Pipeline::Operators::Stages->new($before, $after);
    }
    my($source, @stages) = _parts($before);
    my $sink = is_sink($after);
    return _chain($source, @stages, $after) unless $sink;
    my $next = Ekorn::Pipeline->new(@stages, $after)->iterator($source);
    my @results;
    while (my($result) = $next->()) { push @results, $result }
    return $sink eq 'many' ? \@results : $results[0];
}


# Return a reference to an array of every value the source gives. A
# class of sources of its own can overload @{} with this.
sub drain ($source, @) {
    _check_in_force('@{}');
    my $next = Ekorn::Pipeline->new->iterator($source);
    my @values;
    while (my($value) = $next->()) { push @values, $value }
    return \@values;
}


# Return true if the object given offers a source's role method.
sub _is_source ($object) {
    return !!$object->can('EKORN_SOURCE');
}


# Return what a chain was made of, a source and stages; or, given a
# source that isn't a chain, the source.
sub _parts ($source) {
    return $source isa 'Ekorn::Pipeline::Operators::Chain'
        ? @{ $source->{parts} }
        : $source;
}


# Return a chain: a source of the values from $source through the
# stages, which keeps them, so that more can be added to it.
sub _chain ($source, @stages) {
    my $pipeline = Ekorn::Pipeline->new(@stages);
    my $chain    = Ekorn::Pipeline::Operators::Chain->new(sub {
        my $next = $pipeline->iterator($source);
        return (
            sub () { $next->() }, sub ($how) { $next->finish },
            $next->{context},
        );
    });
    $chain->{parts} = [$source, @stages];
    return $chain;
}

# A chain from a source is a source that keeps what it was made of.
package Ekorn::Pipeline::Operators::Chain {    ## no critic (Modules::ProhibitMultiplePackages)
    use parent -norequire, 'Ekorn::Pipeline::Source';
}

# A chain of stages is a pipeline, of this class, which has |.
package Ekorn::Pipeline::Operators::Stages {    ## no critic (Modules::ProhibitMultiplePackages)
    use parent -norequire, 'Ekorn::Pipeline';
    use overload '|' => \&Ekorn::Pipeline::Operators::chain, fallback => 1;
}

# Loading this module gives Ekorn's sources and iterators | and @{},
# and its stages, gathers and sinks |, and only then.
package Ekorn::Pipeline::Source {    ## no critic (Modules::ProhibitMultiplePackages)
    use overload
        '|'      => \&Ekorn::Pipeline::Operators::chain,
        '@{}'    => \&Ekorn::Pipeline::Operators::drain,
        fallback => 1;
}

package Ekorn::Pipeline::Iterator {    ## no critic (Modules::ProhibitMultiplePackages)
    use overload
        '|'      => \&Ekorn::Pipeline::Operators::chain,
        '@{}'    => \&Ekorn::Pipeline::Operators::drain,
        fallback => 1;
}

package Ekorn::Pipeline::Stage {    ## no critic (Modules::ProhibitMultiplePackages)
    use overload '|' => \&Ekorn::Pipeline::Operators::chain, fallback => 1;
}

package Ekorn::Pipeline::Gather {    ## no critic (Modules::ProhibitMultiplePackages)
    use overload '|' => \&Ekorn::Pipeline::Operators::chain, fallback => 1;
}

package Ekorn::Pipeline::Sink {    ## no critic (Modules::ProhibitMultiplePackages)
    use overload '|' => \&Ekorn::Pipeline::Operators::chain, fallback => 1;
}

1;

__END__

=encoding utf8

=for stopwords bitwise dereferencing

=head1 NAME

Ekorn::Pipeline::Operators - C<|>, C<|=> and C<@{}> for Ekorn's types

=head1 SYNOPSIS

    use Ekorn::Pipeline::Operators;
    use Ekorn::Pipeline::Factories qw(stage);
    use Ekorn::Pipeline::Sources   qw(from_array);
    use Ekorn::Pipeline::Sinks     qw(keep_all count_items);

    my $blur = stage { $_->{artist} eq 'Blur' ? $_ : () };

    my $n = from_array(@tracks)
        | $blur
        | count_items;    # a number
    my $titles = from_array(@tracks)
        | $blur
        | stage { $_->{title} }
        | keep_all;    # an array reference
    my @all = @{ from_array(@tracks) | $blur };    # every value, read through

=head1 DESCRIPTION

It puts C<|>, C<|=> and C<@{}> in force for Ekorn's sources, stages,
gathers, sinks and chains, for the rest of the scope it's used in;
C<no Ekorn::Pipeline::Operators> takes them out again. Written where
they're not in force, they croak. They're a shorthand for the
commonest shapes, not the whole of Ekorn: a pipeline made with
L<Ekorn::Pipeline/new> can have stages after a sink, give a list as a
list, and, pulled with C<iterator>, be a source that gives a sink's
result, none of which a chain can.

=over

=item * C<$stage | $stage> gives a chain of both stages: a pipeline,
which C<|> can extend, and which goes wherever a pipeline does.

=item * C<$source | $stage> gives a source: the source's values,
through the stage.

=item * C<$source | ... | $sink> gives the sink's result, at once, not
a source. For a source of the result, use C<iterator>.

=item * C<$chain |= $stage> makes a new chain with the stage added, and
puts it in the variable. Nothing made is changed.

=item * C<@{ $source }> gives every value the source gives, read
through anew each time (see L</READING A SOURCE THROUGH>).

=back

=head2 Start a chain with one of Ekorn's types

A chain starts with a source, or a stage made with a word, such as
C<stage { uc }>, or a ready-made one, such as C<take(5)>. What follows
can be anything that goes where a stage goes, a plain code reference
or a package's own part included.

B<Never start a chain with a plain code reference.> Perl calls an
overload only when one side is an object, so C<sub { ... } | sub { ...
}> is Perl's bitwise OR of two addresses: a meaningless number, with
no error. Write C<stage { uc }>, never C<sub { uc }>, first. A
pipeline made with C<new> has no operators.

=head2 What a chain gives

An operator gives one scalar, so a chain ending in a sink gives one
value: the result of a sink of one, such as C<count_items>, or the
list of a sink of many, such as C<keep_all>, as an array reference. So
C<my @titles = $source | keep_all> gets one element, the reference:
write C<my @titles = @{ $source | keep_all }>. Nothing can be chained
after a sink that ends a chain from a source: the chain has run, and
given its result.

C<|> binds more loosely than C<.> and C<+>, so put a chain inside a
larger expression in parentheses: C<'Blur: ' . ($source | $blur |
count_items)>.

Keep a chain's result, even one run for what its sink does:
C<my $copied = $source | to_file($path)>. Written as a statement of its
own, the chain runs, but Perl warns "Useless use of numeric bitwise or
(|) in void context" as it compiles the line, which Ekorn can't stop.

=head1 READING A SOURCE THROUGH

C<@{ $source }> gives every value a source gives, with no sink. It
looks like a dereference, but a source holds no array: Operators gives
sources an C<@{}> that runs the source from its start, collects every
value into a new array, and hands Perl a reference to it. So:

=over

=item * each use is a run of its own, reading the source to its end:
C<< $source->[0] >>, C<scalar @$source> and C<$#$source> read every
value, to give one value, a count or an index;

=item * C<for (@$source)> reads every value before the loop starts:
pull from an iterator to take each as it comes;

=item * an iterator is one run, so it's read through once, and croaks
the second time;

=item * only a source has it: on a stage, or a chain of stages, Perl
says "Not an ARRAY reference", and a chain ending in a sink is already
its result;

=item * in C<@{ $source | keep_all }>, the braces are Perl's own,
dereferencing the array reference the sink gave.

=back

For the first value, use C<keep_first>, which reads only one; for how
many, C<count_items>; for the first few, C<take(5) | keep_all>.

=head1 FUNCTIONS

For a package whose own source class should chain as Ekorn's do. It
loads Operators with an empty import list, which defines these without
putting the operators in force in its own scope, and overloads with
them:

    use Ekorn::Pipeline::Operators ();
    use overload
        '|'   => \&Ekorn::Pipeline::Operators::chain,
        '@{}' => \&Ekorn::Pipeline::Operators::drain;

Each reads the hints of the line that used the operator, so it croaks
where the operators aren't in force there.

=head2 chain

    Ekorn::Pipeline::Operators::chain($before, $after, $swapped)

The C<|> of two parts, as L</DESCRIPTION> describes. C<$swapped> is
true when Perl swapped them, as it does to call the overload of the
right side.

=head2 drain

    Ekorn::Pipeline::Operators::drain($source)

A reference to an array of every value the source gives, as
L</READING A SOURCE THROUGH> describes.

=head1 DIAGNOSTICS

=over

=item Expected use Ekorn::Pipeline::Operators in scope, for %s

C<|> or C<@{}> was used on Ekorn's types where Operators isn't in
force.

=item Expected a source, or a stage made with a word, on the left of |

A chain started with something else, such as a pipeline made with
C<new>, or an object of another class.

=item Expected a stage or a sink on the right of |

What followed C<|> can't go where a stage goes.

=back

=head1 SEE ALSO

L<Ekorn::Pipeline>, L<Ekorn::Pipeline::Factories>,
L<Ekorn::Pipeline::Sources>, L<Ekorn::Pipeline::Sinks>

=head1 AUTHOR

Iain Campbell E<lt>cpanic@cpan.orgE<gt>

=head1 LICENSE

Copyright (c) 2024-2026 by Iain Campbell.

This is free software; you can redistribute it and/or modify it under the
same terms as the Perl 5 programming language system itself.

=cut
