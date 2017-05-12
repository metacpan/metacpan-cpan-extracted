package DocRaptor::DocOptions;

use Moose;
use Moose::Util::TypeConstraints;

has 'document_content' => (
    is  => 'rw',
    isa => 'Str',
);

has 'document_url' => (
    is  => 'rw',
    isa => 'Str',
);

has 'is_test' => (
    traits  => ['Bool'],
    is      => 'rw',
    isa     => 'Bool',
    default => 1,
);

enum 'DocumentType' => [qw( pdf xls xlsx )];
has 'document_type' => (
    is       => 'rw',
    isa      => 'DocumentType',
    required => 1,
);

has 'document_name' => (
    is       => 'rw',
    isa      => 'Str',
    required => 1,
);

my $VERSION = '0.002000';

1;
