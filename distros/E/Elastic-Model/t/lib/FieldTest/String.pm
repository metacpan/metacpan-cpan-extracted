package FieldTest::String;

use Elastic::Doc;

#===================================
has 'basic_attr' => (
#===================================
    is  => 'ro',
    isa => 'Str',
);

#===================================
has 'options_attr' => (
#===================================
    is                    => 'ro',
    type                  => 'string',
    index                 => 'not_analyzed',
    index_name            => 'foo',
    store                 => 1,
    term_vector           => 'with_positions_offsets',
    boost                 => 2,
    null_value            => 'nothing',
    index_analyzer        => 'my_index_analyzer',
    search_analyzer       => 'my_search_analyzer',
    analyzer              => 'my_analyzer',
    search_quote_analyzer => 'my_quoted_analyzer',
    include_in_all        => 0
);

#===================================
has 'index_analyzer_attr' => (
#===================================
    is             => 'ro',
    isa            => 'Str',
    index_analyzer => 'my_index_analyzer',
    analyzer       => 'my_analyzer',
);

#===================================
has 'search_analyzer_attr' => (
#===================================
    is              => 'ro',
    isa             => 'Str',
    search_analyzer => 'my_search_analyzer',
    analyzer        => 'my_analyzer',
);

#===================================
has 'multi_attr' => (
#===================================
    is             => 'ro',
    isa            => 'Str',
    boost          => 2,
    analyzer       => 'foo',
    index_analyzer => 'bar',
    multi          => {
        one => {
            boost           => 1,
            search_analyzer => 'baz',
            index_analyzer  => 'bar',
            analyzer        => 'foo',
        },
        two => {
            type           => 'date',
            precision_step => 2,
        }
    }
);

#===================================
has 'mapping_attr' => (
#===================================
    is      => 'ro',
    isa     => 'Str',
    type    => 'integer',
    mapping => { store => 1 }
);

#===================================
has 'bad_opt_attr' => (
#===================================
    is             => 'ro',
    isa            => 'Str',
    precision_step => 1,
);

#===================================
has 'bad_multi_attr' => (
#===================================
    is    => 'ro',
    isa   => 'Str',
    multi => { one => { format => 'foo' } }
);

1;
