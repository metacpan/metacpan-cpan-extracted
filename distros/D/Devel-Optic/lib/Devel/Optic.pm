use strict;
use warnings;
package Devel::Optic;
# ABSTRACT: Production safe data inspector

use Carp qw(croak);
use Scalar::Util qw(looks_like_number);
use Ref::Util qw(is_ref is_arrayref is_hashref is_scalarref is_coderef is_regexpref);

use Sub::Info qw(sub_info);
use Devel::Size qw(total_size);
use PadWalker qw(peek_my);

use Devel::Optic::Lens::Perlish;

use constant {
    EXEMPLAR => [ map { { a => [1, 2, 3, qw(foo bar baz)] } } 1 .. 5 ],
};

use constant {
    # ~3kb on x86_64, and ~160 bytes JSON encoded
    DEFAULT_MAX_SIZE_BYTES => total_size(EXEMPLAR),

    DEFAULT_SCALAR_TRUNCATION_SIZE => 256,
    DEFAULT_SCALAR_SAMPLE_SIZE => 64,
    DEFAULT_SAMPLE_COUNT => 4,
};

sub new {
    my ($class, %params) = @_;
    my $uplevel = $params{uplevel} // 1;

    if (!$uplevel || !looks_like_number($uplevel) || $uplevel < 1) {
        croak "uplevel should be integer >= 1, not '$uplevel'";
    }

    my $self = {
        uplevel => $uplevel,

        # data structures larger than this value (bytes) will be compressed into a sample
        max_size => $params{max_size} // DEFAULT_MAX_SIZE_BYTES,

        # if our over-size entity is a scalar, how much of the scalar should we export.
        # assumption is that this is a "simple" data structure and trimming it much
        # more aggressively probably won't hurt understanding that much.
        scalar_truncation_size => $params{scalar_truncation_size} // DEFAULT_SCALAR_TRUNCATION_SIZE,

        # when building a sample, how much of each scalar child to substr
        scalar_sample_size => $params{scalar_sample_size} // DEFAULT_SCALAR_SAMPLE_SIZE,

        # how many keys or indicies to display in a sample from an over-size
        # hashref/arrayref
        sample_count => $params{sample_count} // DEFAULT_SAMPLE_COUNT,

        lens => $params{lens} // Devel::Optic::Lens::Perlish->new,
    };

    bless $self, $class;
}

sub inspect {
    my ($self, $query) = @_;
    my $scope = peek_my($self->{uplevel});
    my $full_picture = $self->{lens}->inspect($scope, $query);
    return $self->fit_to_view($full_picture);
}

sub fit_to_view {
    my ($self, $subject) = @_;

    my $max_size = $self->{max_size};
    # The sizing is a bit hand-wavy: please ping me if you have a cool idea in
    # this area. I was hesitant to serialize the data structure just to
    # find the size (seems like a lot of work if it is huge), but maybe that's
    # the way to go. total_size also does work proportional to the depth of the
    # data structure, but it's likely much lighter than serialization.
    my $size = total_size($subject);
    if ($size < $max_size) {
        return $subject;
    }

    my $ref = ref $subject;
    my $reasonably_summarized_with_substr = !is_ref($subject) || is_regexpref($subject) || is_scalarref($subject);

    # now we're in too-big territory, so we need to come up with a way to get
    # some useful data to the user without showing the whole structure
    if ($reasonably_summarized_with_substr) {
        $subject = $$subject if is_scalarref($subject);
        my $scalar_truncation_size = $self->{scalar_truncation_size};
        my $len = length $subject;

        # simple scalars we can truncate (PadWalker always returns refs, so
        # this is pretty safe from accidentally substr-ing an array or hash).
        # Also, once we know we're dealing with a gigantic string (or
        # number...), we can trim much more aggressively without hurting user
        # understanding too much.

        if ($len <= $scalar_truncation_size) {
            return sprintf(
                "%s%s (len %d / %d bytes)",
                $ref ? "$ref " : "",
                $subject,
                $len, $size,
            );
        }

        return sprintf(
            "%s%s (truncated to len %d; len %d / %d bytes in full)",
            $ref ? "$ref " : "",
            substr($subject, 0, $scalar_truncation_size) . "...",
            $scalar_truncation_size,
            $len, $size
        );
    }

    my $sample_count = $self->{sample_count};
    my $scalar_sample_size = $self->{scalar_sample_size};
    my $sample_text = "$size bytes";
    if (is_hashref($subject)) {
        my @sample;
        my @keys = keys %$subject;
        my $key_count = scalar @keys;
        $sample_count = $key_count > $sample_count ? $sample_count : $key_count;
        my @sample_keys = @keys[0 .. $sample_count - 1];
        for my $key (@sample_keys) {
            my $val = $subject->{$key};
            my $val_chunk;
            if (ref $val) {
                $val_chunk = ref $val;
            } else {
                $val_chunk = substr($val, 0, $scalar_sample_size);
                $val_chunk .= '...' if length($val_chunk) < length($val);
            }
            my $key_chunk = substr($key, 0, $scalar_sample_size);
            $key_chunk .= '...' if length($key_chunk) < length($key);
            push @sample, sprintf("%s => %s", $key_chunk, $val_chunk);
        }
        $sample_text = sprintf("{%s%s} (%d keys / %d bytes)",
            join(', ', @sample),
            $key_count > $sample_count ? ' ...' : '',
            $key_count, $size
        );
    } elsif (is_arrayref($subject)) {
        my @sample;
        my $total_len = scalar @$subject;
        $sample_count = $total_len > $sample_count ? $sample_count : $total_len;
        for (my $i = 0; $i < $sample_count; $i++) {
            my $val = $subject->[$i];
            my $val_chunk;
            if (ref $val) {
                $val_chunk = ref $val;
            } else {
                $val_chunk = substr($val, 0, $scalar_sample_size);
                $val_chunk .= '...' if length($val_chunk) < length($val);
            }
            push @sample, $val_chunk;
        }
        $sample_text = sprintf("[%s%s] (len %d / %d bytes)",
            join(', ', @sample),
            $total_len > $sample_count ? ' ...' : '',
            $total_len, $size
        );
    } elsif (is_coderef($subject)) {
        my $info = sub_info($subject);
        $sample_text = sprintf("sub %s { ... } (L%d-%d in %s (%s))",
            $info->{name},
            $info->{start_line},
            $info->{end_line},
            $info->{package},
            $info->{file},
        );
    }

    return "$ref: $sample_text";
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Devel::Optic - Production safe data inspector

=head1 VERSION

version 0.010

=head1 SYNOPSIS

  use Devel::Optic;
  my $optic = Devel::Optic->new(max_size => 100);
  my $foo = { bar => ['baz', 'blorg', { clang => 'pop' }] };

  # 'pop'
  $optic->inspect(q|$foo->{'bar'}->[-1]->{'clang'}|);

  # 'HASH: { bar => ARRAY ...} (1 total keys / 738 bytes). Exceeds viewing size (100 bytes)"
  $optic->inspect('$foo');

=head1 DESCRIPTION

L<Devel::Optic> is a L<fiberscope|https://en.wikipedia.org/wiki/Fiberscope> for
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

=head1 NAME

Devel::Optic - Production safe variable inspector

=head1 METHODS

=head2 new

  my $o = Devel::Optic->new(%options);

C<%options> may be empty, or contain any of the following keys:

=over 4

=item C<uplevel>

Which Perl scope to view. Default: 1 (scope that C<Devel::Optic> is called from)

=item C<max_size>

Max size, in bytes, of a data structure that can be viewed without
summarization. This is a little hairy across different architectures, so this
is best expressed in terms of Perl data structures if specified. The goal is to
avoid spitting out subjectively 'big' Perl data structures to a debugger or
log. If you're tuning this value, keep in mind that CODE refs are I<enormous>
(~33kb on C<x86_64>), so basically any data structure with CODE refs inside
will be summarized.

Default: Platform dependent. The value is calculated by

    Devel::Size::total_size([ map { { a => [1, 2, 3, qw(foo bar baz)] } } 1 .. 5 ])

... which is ~3kb on C<x86_64>, and ~160 bytes JSON encoded. This is an
estimate on my part for the size of data structure that makes sense to export
in raw format when viewed. To my entirely personal taste, larger data
structures than this are too big to reasonably export to logs in their
entirety.

=item C<scalar_truncation_size>

Size, in C<substr> length terms, that scalar values are truncated to for
viewing. Default: 256.

=item C<scalar_sample_size>

Size, in C<substr> length terms, that scalar children of a summarized data
structure are trimmed to for inclusion in the summary. Default: 64.

=item C<sample_count>

Number of keys/indices to display when summarizing a hash or arrayref. Default: 4.

=back

=head2 inspect

  my $stuff = { foo => ['a', 'b', 'c'] };
  my $o = Devel::Optic->new;
  # 'a'
  $o->inspect(q|$stuff->{'foo'}->[0]|);

This is the primary method. Given a query, It will either return the requested
data structure, or, if it is too big, return a summary of the data structure
found at that path.

=head2 fit_to_view

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

=head2 full_picture

This method takes a 'query' and uses it to extract a data structure from the
L<Devel::Optic>'s C<uplevel>. If the query points to a variable that does not
exist, L<Devel::Optic> will croak.

=head3 QUERY SYNTAX

L<Devel::Optic> uses a Perl-ish data access syntax for queries.

A query always starts with a variable name in the scope being picked, and
uses C<-E<gt>> to indicate deeper access to that variable. At each level, the
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

=head4 QUERY SYNTAX ALTNERATIVES

The query syntax attempts to provide a reasonable amount of power
for navigating Perl data structures without risking the stability of the system
under inspection.

In other words, while C<eval '$my_cool_hash{a}-E<gt>[1]-E<gt>{needle}'> would
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

=over 4

=item Simple query model

As a debugging tool, you have enough on your brain just debugging your system.
Second-guessing your query syntax when you get unexpected results is a major
distraction and leads to loss of trust in the tool (I'm looking at you,
ElasticSearch).

=item O(1), not O(n) (or worse)

I'd like to avoid globs or matching syntax that might end up iterating over
unbounded chunks of a data structure. Traversing a small, fixed number of keys
in 'parallel' sounds like a sane extension, but anything which requires
iterating over the entire set of hash keys or array indicies is likely to
surprise when debugging systems with unexpectedly large data structures.

=back

=head1 SEE ALSO

=over 4

=item *

L<PadWalker>

=item *

L<Devel::Probe>

=back

=head1 AUTHOR

Ben Tyler <btyler@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Ben Tyler.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
