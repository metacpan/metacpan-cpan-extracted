package TestModel::DocumentTypeC;

use Moose;
use Elasticsearch::Model::Document;
use MooseX::Types::Moose
    qw/ArrayRef ScalarRef Undef Defined Str Object Int HashRef Maybe Num Bool/;
use MooseX::Types::Structured qw/Dict Optional/;
use Moose::Util::TypeConstraints;
use DateTime;

use MooseX::Types -declare => [
    qw(
        CrowsNest
        MaybeCrowsNest
        Kudzu
        Note
        MyDateTime
        TreeStump
        )
];
subtype MyDateTime, as class_type('DateTime');

subtype CrowsNest, as Dict [
    crows_nest_id => Int,
    topology      => Num,
    display_name  => Str,
    num_birds     => Maybe [Int],
];

subtype Kudzu, as Dict [
    root_length => Int,
    knots       => Num,
    anthills    => Bool,
    color       => Str,
    crows_nest  => CrowsNest,
];

subtype MaybeCrowsNest, as maybe_type(CrowsNest);

subtype Note, as Dict [
    max         => Optional [Str],
    note_id     => Maybe    [Int],
    note_radius => Maybe    [Num],
];

subtype TreeStump, as Maybe [
    Dict [
        tree_name     => Optional [Str],
        tree_id       => Optional [Int],
        tree_diameter => Optional [Num],
    ]
];

has stump => (
    is  => 'ro',
    isa => TreeStump,
);

has crows_nest => (
    is  => 'ro',
    isa => CrowsNest,
);

has bird_house => (
    is  => 'ro',
    isa => MaybeCrowsNest,
);

has grass_field => (
    is  => 'ro',
    isa => 'Maybe[' . Kudzu . ']',
);

has comments => (
    is  => 'ro',
    isa => Note,
);

has start_date => (
    is     => 'ro',
    isa    => MyDateTime,
    format => 'YYYY-mm-dd',
);

has grassname => (
    is  => 'ro',
    isa => ScalarRef,
);

has redundant_thing => (
    is   => 'ro',
    isa  => Note,
    type => 'object',
);

has grass_name_list => (
    is  => 'ro',
    isa => 'ArrayRef[Str]',
);

has grass_id_list => (
    is  => 'ro',
    isa => 'ArrayRef[Int]',
);

has_non_attribute_mapping {
    _source => {
        excludes => [qw/
            grass_field
        /],
    },
};

__PACKAGE__->meta->make_immutable;

1;

