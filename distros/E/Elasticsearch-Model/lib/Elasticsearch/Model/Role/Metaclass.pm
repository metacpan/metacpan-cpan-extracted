package Elasticsearch::Model::Role::Metaclass;

use Moose::Role;

sub _handles {
    my ($s, $p) = @_;
    return {
        "get_$s"        => 'get',
        "get_$p"        => 'values',
        "get_${s}_list" => 'keys',
        "remove_$s"     => 'delete',
        "add_$s"        => 'set',
    };
}

my %features = (
    analyzer   => 'analyzers',
    tokenizer  => 'tokenizers',
    filter     => 'filters',
    normalizer => 'normalizers'
);

while (my ($s, $p) = each %features) {
    has $p => (
        traits  => ['Hash'],
        isa     => 'HashRef',
        default => sub { {} },
        handles => _handles($s, $p)
    );
}

has indices => (
    traits  => ['Hash'],
    isa     => 'HashRef',
    default => sub { {default => {}} },
    handles => (_handles('index', 'indices')),
);

sub namespaced_name_for_original_name {
    my $self    = shift;
    my @indices = $self->get_indices;
    my %namespaced_names = map {
        $_->{name} => $_->{namespaced_name}
    } @indices;
    return \%namespaced_names;
}

before add_index => sub {
    my ($self, $name, $index) = @_;
    $self->remove_index('default');
};

has document_namespace => (
    is      => 'rw',
    isa     => 'Maybe[Str]',
);

1;
