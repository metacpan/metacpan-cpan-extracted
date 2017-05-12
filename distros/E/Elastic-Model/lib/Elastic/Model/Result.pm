package Elastic::Model::Result;
$Elastic::Model::Result::VERSION = '0.52';
use Moose;

use Carp;
use Elastic::Model::Types qw(UID);
use MooseX::Types::Moose qw(HashRef Maybe Num Bool);

use namespace::autoclean;

#===================================
has 'result' => (
#===================================
    isa      => HashRef,
    is       => 'ro',
    required => 1,
);

#===================================
has 'is_partial' => (
#===================================
    isa      => Bool,
    is       => 'ro',
    required => 1,
);

#===================================
has 'uid' => (
#===================================
    isa     => UID,
    is      => 'ro',
    lazy    => 1,
    builder => '_build_uid',
    handles => [ 'index', 'type', 'id', 'routing' ]
);

#===================================
has 'source' => (
#===================================
    is      => 'ro',
    isa     => Maybe [HashRef],
    lazy    => 1,
    builder => '_build_source',
);

#===================================
has 'score' => (
#===================================
    is      => 'ro',
    isa     => Num,
    lazy    => 1,
    builder => '_build_score'
);

#===================================
has 'fields' => (
#===================================
    is      => 'ro',
    isa     => HashRef,
    traits  => ['Hash'],
    lazy    => 1,
    builder => '_build_fields',
    handles => { field => 'get' }
);

#===================================
has 'highlights' => (
#===================================
    is      => 'ro',
    isa     => HashRef,
    lazy    => 1,
    builder => '_build_highlights'
);

#===================================
has 'object' => (
#===================================
    is      => 'ro',
    does    => 'Elastic::Model::Role::Doc',
    lazy    => 1,
    builder => '_build_object'
);

#===================================
has 'partial' => (
#===================================
    is      => 'ro',
    does    => 'Elastic::Model::Role::Doc',
    lazy    => 1,
    builder => '_build_partial'
);

no Moose;

#===================================
sub _build_uid    { Elastic::Model::UID->new_from_store( shift()->result ) }
sub _build_score  { shift->result->{_score} }
sub _build_fields { shift->result->{fields} || {} }
sub _build_highlights { shift->result->{highlight} || {} }
#===================================

#===================================
sub _build_source {
#===================================
    my $self = shift;
    return undef if $self->is_partial;
    return $self->result->{_source};
}

#===================================
sub _build_object {
#===================================
    my $self = shift;
    $self->result->{_object} ||= $self->model->get_doc(
        uid    => $self->uid,
        source => $self->source
    );
}

#===================================
sub _build_partial {
#===================================
    my $self = shift;
    $self->result->{_partial} ||= $self->model->new_partial_doc(
        uid            => Elastic::Model::UID->new_partial( $self->result ),
        partial_source => $self->result->{_source}
    );
}

#===================================
sub highlight {
#===================================
    my $self       = shift;
    my $field      = shift() or croak "Missing (field) name";
    my $highlights = $self->highlights->{$field} or return;
    return @{$highlights};
}

#===================================
sub explain {
#===================================
    my $self = shift;

    my $result  = $self->result;
    my $explain = $result->{_explanation}
        || return "No explanation\n";

    my $text = sprintf "Doc: [%s|%s|%s], Shard: [%s|%d]:\n",
        map { defined $_ ? $_ : 'undef' }
        @{$result}{qw(_index _type _id _node _shard)};

    my $indent = 0;
    my @stack  = [$explain];

    while (@stack) {
        my @current = @{ shift @stack };
        while ( my $next = shift @current ) {
            my $spaces = ( ' ' x $indent ) . ' - ';
            my $max    = 67 - $indent;
            $max = 30 if $max < 30;
            my $desc = $next->{description};
            while ( length($desc) > $max ) {
                $desc =~ s/^(.{30,${max}\b|.{${max}})\s*//;
                $text .= sprintf "%-70s |\n", $spaces . $1;
            }
            $text .= sprintf "%-70s | % 9.4f\n", $spaces . $desc,
                $next->{value};
            if ( my $details = $next->{details} ) {
                unshift @stack, [@current];
                @current = @{$details};
                $indent += 2;
            }
        }
        $indent -= 2;
    }
    return $text;
}

1;

=pod

=encoding UTF-8

=head1 NAME

Elastic::Model::Result - A wrapper for individual search results

=head1 VERSION

version 0.52

=head1 SYNOPSIS

    $result             = $results->next_result;

    $object             = $result->object;
    $uid                = $result->uid;
    $partial_obj        = $result->partial;

    \%all_highlights    = $result->highlights;
    @field_highlights   = $result->highlight('field_name');

    \%all_fields        = $result->fields;
    $field_value        = $result->field('field_name');
    $script_field_value = $result->field('script_field_name');

    $explain            = $result->explain;
    $score              = $result->score;
    \%source_field      = $result->source;
    \%raw_result        = $result->result;

=head1 DESCRIPTION

L<Elastic::Model::Result> wraps the individual result returned from
L<Elastic::Model::Results>, L<Elastic::Model::Results::Cached>
or L<Elastic::Model::Results::Scrolled>.

=head1 ATTRIBUTES

=head2 object

    $object = $result->object();

The object associated with the result.  By default, the L</source> field is
returned in search results, meaning that we can inflate the object directly from
the search results.  B<Note:> If you set L<Elastic::Model::View/fields> and you
don't include C<'_source'> then you will be unable to inflate your object
without a separate (but automatic) step to retrieve it from Elasticsearch.

Also see L<Elastic::Manual::Scoping>.

=head2 uid

=head2 index, type, id, routing

    $uid     = $result->uid;
    $index   = $result->index   | $result->uid->index;
    $type    = $result->type    | $result->uid->type;
    $id      = $result->id      | $result->uid->id;
    $routing = $result->routing | $result->uid->routing;

The L<uid|Elastic::Model::UID> of the doc.  L<index|Elastic::Model::UID/index>,
L<type|Elastic::Model::UID/type>, L<id|Elastic::Model::UID/id>
and L<routing|Elastic::Model::UID/routing> are provided for convenience.

=head2 partial

    $partial_obj = $result->partial_object();

If your objects are large, you may want to load only part of the object in your
search results. You can specify which parts of the object to include or exclude
using L<Elastic::Model::View/"include_paths / exclude_paths">.

The partial objects returned by L</partial> function exactly as real objects,
except that they cannot be saved.

=head2 is_partial

    $bool = $result->is_partial;

Return C<true> or C<false> to indicate whether the currently loaded
C<_source> field is partial or not.

=head2 highlights

=head2 highlight

    \%all_highlights  = $result->highlights;
    @field_highlights = $result->highlight('field_name');

The snippets from the L<highlighted fields|Elastic::Model::View/highlight>
in your L<view|Elastic::Model::View>. L</highlights> returns a hash ref
containing snippets from all the highlighted fields, while L</highlight> returns
a list of the snippets for the named field.

=head2 fields

=head2 field

    \%all_fields        = $result->fields;
    $field_value        = $result->field('field_name');
    $script_field_value = $result->field('script_field_name');

The values of any L<fields|Elastic::Model::View/fields> or
L<script_fields|Elastic::Model::View/script_fields> specified in your
L<view|Elastic::Model::View>.

=head2 score

    $score = $result->score;

The relevance score of the result. Note: if you L<sort|Elastic::Model::View/sort>
on any value other than C<_score> then the L</score> will be zero, unless you
also set L<Elastic::Model::View/track_scores> to a true value.

=head2 explain

    $explanation = $result->explain;

If L<Elastic::Model::View/explain> is set to true, then you can retrieve
the text explanation using L</explain>, for instance:

    print $result->explain;

    Doc: [myapp|user|BS8mmGFhRdS5YcpeLkdw_g], Shard: [a7gbLmJWQE2EdIaP_Rnnew|4]:
     - product of:                                                 |    1.1442
       - sum of:                                                   |    2.2885
         - weight(name:aardwolf in 0), product of:                 |    2.2885
           - queryWeight(name:aardwolf), product of:               |    0.6419
             - idf(docFreq=1, maxDocs=26)                          |    3.5649
             - queryNorm                                           |    0.1801
           - fieldWeight(name:aardwolf in 0), product of:          |    3.5649
             - tf(termFreq(name:aardwolf)=1)                       |    1.0000
             - idf(docFreq=1, maxDocs=26)                          |    3.5649
             - fieldNorm(field=name, doc=0)                        |    1.0000
       - coord(1/2)                                                |    0.5000

And here's a brief explanation of what these numbers mean:
L<http://www.lucenetutorial.com/advanced-topics/scoring.html>.

=head2 result

    \%raw_result = $result->result

The raw result hashref as returned by Elasticsearch.

=head2 source

    \%source_field = $result->source

The C<_source> field (ie the hashref which represents your object in
Elasticsearch). This value is returned by default with any search, and is
used to inflate your L</object> without having to retrieve it in a separate
step. B<Note:> If you set L<Elastic::Model::View/fields> and you don't include
C<'_source'> then you will be unable to inflate your object without a separate
(but automatic) step to retrieve it from Elasticsearch.

=head1 AUTHOR

Clinton Gormley <drtech@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Clinton Gormley.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__

# ABSTRACT: A wrapper for individual search results

