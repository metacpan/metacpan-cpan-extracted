package Elastic::Model::Meta::Class::Model;
$Elastic::Model::Meta::Class::Model::VERSION = '0.52';
use Moose::Role;
use List::Util ();
use MooseX::Types::Moose qw(HashRef Str);
use Carp;
use Data::Dump qw(pp);
use namespace::autoclean;

my %defaults = (
    analyzer  => {},
    tokenizer => {},
);

for my $k (qw(namespace char_filter analyzer filter tokenizer)) {
    my %default = %{ $defaults{$k} || {} };

#===================================
    has "${k}s" => (
#===================================
        is      => 'ro',
        traits  => ['Hash'],
        isa     => HashRef,
        default => sub { +{%default} },
        handles => {
            $k          => 'get',
            "add_${k}"  => 'set',
            "has_${k}"  => 'exists',
            "all_${k}s" => 'keys',
        }
    );
    next if $k eq 'namespace';

#===================================
    before "add_$k" => sub {
#===================================
        my $class = shift;
        my %params = ref $_[0] ? { shift() } : @_;
        for my $defn ( values %params ) {
            my $type = $defn->{type} || 'custom';
            return if $type eq 'custom' and $k eq 'analyzer';
            croak "Unknown type ($type) in $k:\n" . pp( \%params ) . "\n"
                unless $class->is_default( $k, $type );
        }
    };
}

#===================================
has 'classes' => (
#===================================
    is      => 'ro',
    isa     => HashRef [Str],
    traits  => ['Hash'],
    default => sub {
        +{  typemap          => 'Elastic::Model::TypeMap::Default',
            domain           => 'Elastic::Model::Domain',
            namespace        => 'Elastic::Model::Namespace',
            store            => 'Elastic::Model::Store',
            view             => 'Elastic::Model::View',
            scope            => 'Elastic::Model::Scope',
            results          => 'Elastic::Model::Results',
            cached_results   => 'Elastic::Model::Results::Cached',
            scrolled_results => 'Elastic::Model::Results::Scrolled',
            result           => 'Elastic::Model::Result',
            bulk             => 'Elastic::Model::Bulk'
        };
    },
    handles => {
        set_class => 'set',
        get_class => 'get',
    }
);

#===================================
has 'unique_index' => (
#===================================
    is      => 'rw',
    isa     => 'Str',
    default => sub {'unique_key'}
);

no Moose;

our %DefaultAnalysis = (
    char_filter => { map { $_ => 1 } qw(html_strip mapping) },
    filter      => +{
        map { $_ => 1 }
            qw(
            standard asciifolding length lowercase ngram edge_ngram
            porterStem shingle stop word_delimiter snowball kstem phonetic
            synonym dictionary_decompounder hyphenation_decompounder
            reverse elision trim truncate unique pattern_replace
            icu_normalizer icu_folding icu_collation
            )
    },
    tokenizer => {
        map { $_ => 1 }
            qw(
            edge_ngram keyword letter lowercase ngram standard
            whitespace pattern uax_url_email path_hierarchy
            )
    },
    analyzer => {
        map { $_ => 1 }
            qw(
            standard simple whitespace stop keyword pattern snowball
            arabic armenian basque brazilian bulgarian catalan chinese
            cjk czech danish dutch english finnish french galician german
            greek hindi hungarian indonesian italian latvian
            norwegian persian portuguese romanian russian spanish swedish
            turkish thai
            )
    }
);

#===================================
sub is_default {
#===================================
    my $self = shift;
    my $type = shift || '';
    croak "Unknown type ($type) passed to is_default()"
        unless exists $DefaultAnalysis{$type};
    my $name = shift or croak "No $type name passed to is_default";
    return exists $DefaultAnalysis{$type}{$name};
}

#===================================
sub analysis_for_mappings {
#===================================
    my $self     = shift;
    my $mappings = shift;

    my %analyzers;
    for my $type ( keys %$mappings ) {
        for my $name ( _required_analyzers( $mappings->{$type} ) ) {
            next
                if exists $analyzers{$name}
                || $self->is_default( 'analyzer', $name );
            $analyzers{$name} = $self->analyzer($name)
                or die "Unknown analyzer ($name) required by type ($type)";
        }
    }
    return unless %analyzers;

    my %analysis = ( analyzer => \%analyzers );
    for my $type (qw(tokenizer filter char_filter )) {
        my %defn;
        for my $analyzer_name ( keys %analyzers ) {
            my $vals = $analyzers{$analyzer_name}{$type} or next;
            for my $name ( ref $vals ? @$vals : $vals ) {
                next
                    if exists $defn{$name}
                    || $self->is_default( $type, $name );
                $defn{$name} = $self->$type($name)
                    or die
                    "Unknown $type ($name) required by analyzer '$analyzer_name'";
            }
        }
        $analysis{$type} = \%defn if %defn;
    }
    return \%analysis;
}

#===================================
sub _required_analyzers {
#===================================
    my @analyzers;
    while (@_) {
        my $mapping = shift or next;
        my @sub = (
            values %{ $mapping->{fields} || {} },
            values %{ $mapping->{properties} || {} }
        );

        push @analyzers, _required_analyzers(@sub),
            map { $mapping->{$_} } grep /analyzer/, keys %$mapping;
    }

    return @analyzers;
}

our $Counter = 1;
#===================================
sub wrapped_class_name {
#===================================
    return 'Elastic::Model::__WRAPPED_' . $Counter++ . '_::' . $_[1];
}

1;

=pod

=encoding UTF-8

=head1 NAME

Elastic::Model::Meta::Class::Model - A meta-class for Models

=head1 VERSION

version 0.52

=head1 DESCRIPTION

Holds static information about your model: namespaces and their types,
and char_filters, tokenizers, filters and analyzers for analysis.

You shouldn't need to use this class directly. Everything you need should
be accessible via L<Elastic::Model> or L<Elastic::Model::Role::Model>.

=head1 METHODS

=head2 is_default()

    $bool = $meta->is_default($type => $name);

Returns C<true> if C<$name> is a C<$type> (analyzer, tokenizer,
filter, char_filter) available in Elasticsearch by default.

=head3 Default analyzers

L<standard|http://www.elasticsearch.org/guide/en/elasticsearch/reference/current/analysis-standard-analyzer.html>,
L<simple|http://www.elasticsearch.org/guide/en/elasticsearch/reference/current/analysis-simple-analyzer.html>,
L<whitespace|http://www.elasticsearch.org/guide/en/elasticsearch/reference/current/analysis-whitespace-analyzer.html>,
L<stop|http://www.elasticsearch.org/guide/en/elasticsearch/reference/current/analysis-stop-analyzer.html>,
L<keyword|http://www.elasticsearch.org/guide/en/elasticsearch/reference/current/analysis-keyword-analyzer.html>,
L<pattern|http://www.elasticsearch.org/guide/en/elasticsearch/reference/current/analysis-pattern-analyzer.html>,
L<snowball|http://www.elasticsearch.org/guide/en/elasticsearch/reference/current/analysis-snowball-analyzer.html>,
and the L<language|http://www.elasticsearch.org/guide/en/elasticsearch/reference/current/analysis-lang-analyzer.html>
analyzers:  C<arabic>, C<armenian>, C<basque>, C<brazilian>, C<bulgarian>,
C<catalan>, C<chinese>, C<cjk>, C<czech>, C<danish>, C<dutch>, C<english>,
C<finnish>, C<french>, C<galician>, C<german>, C<greek>, C<hindi>, C<hungarian>,
C<indonesian>, C<italian>, C<latvian>, C<norwegian>, C<persian>,
C<portuguese>, C<romanian>, C<russian>, C<spanish>, C<swedish>,
C<thai>, C<turkish>

=head3 Default tokenizers

L<edge_ngram|http://www.elasticsearch.org/guide/en/elasticsearch/reference/current/analysis-edgengram-tokenizer.html>,
L<keyword|http://www.elasticsearch.org/guide/en/elasticsearch/reference/current/analysis-keyword-tokenizer.html>,
L<letter|http://www.elasticsearch.org/guide/en/elasticsearch/reference/current/analysis-letter-tokenizer.html>,
L<lowercase|http://www.elasticsearch.org/guide/en/elasticsearch/reference/current/analysis-lowercase-tokenizer.html>,
L<ngram|http://www.elasticsearch.org/guide/en/elasticsearch/reference/current/analysis-ngram-tokenizer.html>,
L<path_hierarchy|http://www.elasticsearch.org/guide/en/elasticsearch/reference/current/analysis-pathhierarchy-tokenizer.html>,
L<pattern|http://www.elasticsearch.org/guide/en/elasticsearch/reference/current/analysis-pattern-tokenizer.html>,
L<standard|http://www.elasticsearch.org/guide/en/elasticsearch/reference/current/analysis-standard-tokenizer.html>,
L<uax_url_email|http://www.elasticsearch.org/guide/en/elasticsearch/reference/current/analysis-uaxurlemail-tokenizer.html>,
L<whitespace|http://www.elasticsearch.org/guide/en/elasticsearch/reference/current/analysis-whitespace-tokenizer.html>

=head3 Default token filters

L<asciifolding|http://www.elasticsearch.org/guide/en/elasticsearch/reference/current/analysis-asciifolding-tokenfilter.html>,
L<dictionary_decompounder|http://www.elasticsearch.org/guide/en/elasticsearch/reference/current/analysis-compound-word-tokenfilter.html>,
L<edge_ngram|http://www.elasticsearch.org/guide/en/elasticsearch/reference/current/analysis-edgengram-tokenfilter.html>,
L<elision|http://www.elasticsearch.org/guide/en/elasticsearch/reference/current/analysis-elision-tokenfilter.html>,
L<hyphenation_decompounder|http://www.elasticsearch.org/guide/en/elasticsearch/reference/current/analysis-compound-word-tokenfilter.html>,
L<icu_collation|http://www.elasticsearch.org/guide/en/elasticsearch/reference/current/analysis-icu-plugin.html>,
L<icu_folding|http://www.elasticsearch.org/guide/en/elasticsearch/reference/current/analysis-icu-plugin.html>,
L<icu_normalizer|http://www.elasticsearch.org/guide/en/elasticsearch/reference/current/analysis-icu-plugin.html>,
L<kstem|http://www.elasticsearch.org/guide/en/elasticsearch/reference/current/analysis-kstem-tokenfilter.html>,
L<length|http://www.elasticsearch.org/guide/en/elasticsearch/reference/current/analysis-length-tokenfilter.html>,
L<lowercase|http://www.elasticsearch.org/guide/en/elasticsearch/reference/current/analysis-lowercase-tokenfilter.html>,
L<ngram|http://www.elasticsearch.org/guide/en/elasticsearch/reference/current/analysis-ngram-tokenfilter.html>,
L<pattern_replace|http://www.elasticsearch.org/guide/en/elasticsearch/reference/current/analysis-pattern_replace-tokenfilter.html>,
L<phonetic|http://www.elasticsearch.org/guide/en/elasticsearch/reference/current/analysis-phonetic-tokenfilter.html>,
L<porterStem|http://www.elasticsearch.org/guide/en/elasticsearch/reference/current/analysis-porterstem-tokenfilter.html>,
L<reverse|http://www.elasticsearch.org/guide/en/elasticsearch/reference/current/analysis-reverse-tokenfilter.html>,
L<shingle|http://www.elasticsearch.org/guide/en/elasticsearch/reference/current/analysis-shingle-tokenfilter.html>,
L<snowball|http://www.elasticsearch.org/guide/en/elasticsearch/reference/current/analysis-snowball-tokenfilter.html>,
L<standard|http://www.elasticsearch.org/guide/en/elasticsearch/reference/current/analysis-standard-tokenfilter.html>,
L<stop|http://www.elasticsearch.org/guide/en/elasticsearch/reference/current/analysis-stop-tokenfilter.html>,
L<synonym|http://www.elasticsearch.org/guide/en/elasticsearch/reference/current/analysis-synonym-tokenfilter.html>,
L<trim|http://www.elasticsearch.org/guide/en/elasticsearch/reference/current/analysis-trim-tokenfilter.html>,
L<truncate|http://www.elasticsearch.org/guide/en/elasticsearch/reference/current/analysis-truncate-tokenfilter.html>,
L<unique|http://www.elasticsearch.org/guide/en/elasticsearch/reference/current/analysis-word-delimiter-tokenfilter.html>,
L<word_delimiter|http://www.elasticsearch.org/guide/en/elasticsearch/reference/current/analysis-word-delimiter-tokenfilter.html>

=head3 Default character filters

L<html_strip|http://www.elasticsearch.org/guide/en/elasticsearch/reference/current/analysis-htmlstrip-charfilter.html>,
L<mapping|http://www.elasticsearch.org/guide/en/elasticsearch/reference/current/analysis-mapping-charfilter.html>

=head2 analysis_for_mappings()

    $analysis = $meta->analysis_for_mappings($mappings)

Used to generate the C<analysis> settings for an index, based on which
analyzers are used in the C<mappings> for all C<types> in the index.

=head2 wrapped_class_name()

    $new_class = $meta->wrapped_class_name($old_class);

Generates a semi-anonymous classname with the format
C<Elastic::Model::__WRAPPED_::$n>

=head1 ATTRIBUTES

=head2 namespaces

    \%namespaces    = $meta->namespaces;
    \%namespace     = $meta->namespace($name);
    $bool           = $meta->has_namespace($name);
    @names          = $meta->all_namespaces;

A hash ref containing all namespaces plus their configuration, eg:

    {
        myapp => {
            types => {
                user => 'MyApp::User'
            }
        }
    }

=head2 unique_index

    $index = $meta->unique_index

The name of the index where unique keys will be stored, which defaults
to C<unique_key>.  A different value can be specified with
L<has_unique_index|Elastic::Model/Custom unique key index>.

See L<Elastic::Manual::Attributes::Unique> for more.

=head2 analyzers

    \%analyzers     = $meta->analyzers;
    \%analyzer      = $meta->analyzer($name);
    $bool           = $meta->has_analyzer($name);
    @names          = $meta->all_analyzers;

A hash ref containing all analyzers plus their configuration, eg:

    {
        my_analyzer => {
            type        => 'custom',
            tokenizer   => 'standard',
            filter      => ['lower']
        }
    }

=head2 tokenizers

    \%tokenizers    = $meta->tokenizers;
    \%tokenizer     = $meta->tokenizer($name);
    $bool           = $meta->has_tokenizer($name);
    @names          = $meta->all_tokenizers;

A hash ref containing all tokenizers plus their configuration, eg:

    {
        my_tokenizer => {
            type    => 'pattern',
            pattern => '\W'
        }
    }

=head2 filters

    \%filters       = $meta->filters;
    \%filter        = $meta->filter($name);
    $bool           = $meta->has_filter($name);
    @names          = $meta->all_filters;

A hash ref containing all filters plus their configuration, eg:

    {
        my_filter => {
            type        => 'edge_ngram',
            min_gram    => 1,
            max_gram    => 20
        }
    }

=head2 char_filters

    \%char_filters  = $meta->char_filters;
    \%char_filter   = $meta->char_filter($name);
    $bool           = $meta->has_char_filter($name);
    @names          = $meta->all_char_filters;

A hash ref containing all char_filters plus their configuration, eg:

    {
        my_char_filter => {
            type        => 'mapping',
            mappings    => ['ph=>f','qu=>q']
        }
    }

=head1 AUTHOR

Clinton Gormley <drtech@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Clinton Gormley.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__

# ABSTRACT: A meta-class for Models

