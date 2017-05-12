package MyApp::MultiUser;

use Elastic::Doc;

use MooseX::Types::Moose qw(ArrayRef Str);
use MooseX::Types::Structured qw(Dict);
use MooseX::Types -declare => [qw(Entry)];

subtype Entry, as ArrayRef [
    Dict [
        first => Str,
        last  => Str,
    ]
];

#===================================
has 'entry' => (
#===================================
    is   => 'rw',
    isa  => Entry,
    type => 'nested',
);

no Elastic::Doc;

1;
