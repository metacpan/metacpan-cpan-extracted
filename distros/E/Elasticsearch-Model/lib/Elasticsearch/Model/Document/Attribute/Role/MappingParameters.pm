package Elasticsearch::Model::Document::Attribute::Role::MappingParameters;

use Moose::Role;
use Moose::Util::TypeConstraints;
use MooseX::Types::Moose qw(ArrayRef HashRef);
use Elasticsearch::Model::Document::Mapper;
use Data::Printer;

has basic_serialization => (
    is      => 'ro',
    lazy    => 1,
    isa     => 'HashRef',
    builder => '_build_basic_serialization',
);

sub _build_basic_serialization {
    my $self = shift;
    my %basic_serialization =
        map {
            # Ensure that Bools get turned into words, i.e., true/false
            my $is_bool = $self->meta->get_attribute($_)->type_constraint->name =~ /Bool/;
            $_ => $is_bool ? ($self->$_ ? 'true' : 'false') : $self->$_;
        }
        grep { length $self->$_ }
        grep { defined $self->$_ }
    @{$self->mapping_parameters};
    return \%basic_serialization;
}

has mapping_parameters => (
    is => 'ro',
    isa => 'ArrayRef[Str]',
    default => sub {[qw/
        analyzer
        coerce
        copy_to
        doc_values
        dynamic
        eager_global_ordinals
        enabled
        fielddata
        fields
        format
        ignore_above
        ignore_malformed
        index
        normalizer
        null_value
        position_increment_gap
        search_analyzer
        search_quote_analyzer
        similarity
        store
        term_vector
        type
    /]},
);

has [
    qw/
        copy_to
        format
        null_value
        /
    ] => (
    is  => 'ro',
    isa => 'Maybe[Str]',
);

has position_increment_gap => (
    is  => 'ro',
    isa => 'Maybe[Int]',
);

has [
    qw/
        analyzer
        search_analyzer
        search_quote_analyzer
        normalizer
        /
] => (
    is  => 'ro',
    isa => 'Maybe[Str]',
);

has ignore_above => (
    is  => 'ro',
    isa => 'Maybe[Int]',
);

has similarity => (
    is  => 'ro',
    isa => enum(
        [
            '', qw/
                classic
                boolean
                BM25
                /
        ]
    ),
    default => '',
);

has dynamic => (
    is      => 'ro',
    isa => enum(
        [
            '', qw/
                strict
                true
                false
            /
        ]
    ),
    default => '',
);

has [qw/
    coerce
    enabled
    fielddata
    eager_global_ordinals
    ignore_malformed
    doc_values
    index
    store
/] => (
    is => 'ro',
    isa => 'Maybe[Bool]',
);

has type => (
    is  => 'ro',
    isa => enum(
        [
            '', qw/
                binary
                boolean
                byte
                circle
                completion
                date
                date_range
                double
                double_range
                envelope
                float
                float_range
                geo_point
                geo_shape
                geometrycollection
                half_float
                integer
                integer_range
                ip
                ip_range
                join
                keyword
                linestring
                long
                long_range
                multilinestring
                multipoint
                multipolygon
                murmur3
                nested
                object
                percolator
                point
                polygon
                scaled_float
                short
                text
                token_count
                /
        ]
    ),
    default => '',
);

has fields => (
    is  => 'ro',
    isa => 'Maybe[HashRef]',
);
has term_vector => (
    is  => 'ro',
    isa => enum(
        [
            '', qw/
                no
                yes
                with_positions
                with_offsets
                with_positions_offsets
                /
        ]
    ),
    default => '',
);
has field_name => (
    is      => 'ro',
    isa     => 'Str',
    lazy    => 1,
    default => sub { shift->name },
);

has isa_arrayref => (
    is      => 'ro',
    lazy    => 1,
    isa     => 'Bool',
    builder => '_build_isa_arrayref'
);

sub _build_isa_arrayref {
    my $self = shift;
    my $tc   = $self->type_constraint;
    return 0 unless $tc;
    return $tc->is_a_type_of("ArrayRef");
}

sub build_property {
    my $self = shift;
    return Elasticsearch::Model::Document::Mapper::maptc(
        $self, $self->type_constraint
    );
}

before _process_options => sub {
    my ($self, $name, $options) = @_;
    %$options = (
        builder => 'build_id',
        lazy    => 1,
        %$options
    ) if (
            $options->{id}
        and ref $options->{id} eq 'ARRAY'
    );

    $options->{traits} //= [];
};

after _process_options => sub {
    my ($class, $name, $options) = @_;
    if (
            $options->{required}
        and not $options->{builder}
        and not defined $options->{default}
    ) {
        $options->{lazy}     = 1;
        $options->{required} = 1;
        $options->{default}  = sub {
            confess "Attribute $name is required";
        };
    }
};

sub mapping {
    my $self = shift;
    return ($self->name => { $self->build_property });
}

sub type_mapping { () }

1;
