package Elasticsearch::Model::Role;

use Moose::Role;
use Module::Find;

use Class::Load;
use Search::Elasticsearch 6.00;
use Try::Tiny;

has es => (
    is      => 'ro',
    lazy    => 1,
    builder => '_build_es',
);

sub _build_es {
    my $self = shift;
    return Search::Elasticsearch->new(
        nodes => $ENV{ES} || '127.0.0.1:9200',
        cxn   => 'HTTPTiny',
    );
}

has document_types => (
    is      => 'ro',
    isa     => 'Maybe[ArrayRef]',
    lazy    => 1,
    builder => '_build_document_types',
);

sub _build_document_types {
    my $self = shift;
    my @found =
        grep { $_->isa('Moose::Object') }
        map  { Class::Load::load_class($_) }
        findallmod($self->document_namespace);
    return \@found;
}

has document_namespace => (
    is      => 'ro',
    isa     => 'Str',
    lazy    => 1,
    builder => '_build_document_namespace',
);

sub _build_document_namespace {
    my $self = shift;
    return $self->meta->document_namespace // ref $self;
}

sub deploy {
    my ($self, %params) = @_;

    my $t = $self->es->transport;

    foreach my $original_name ($self->meta->get_index_list) {
        my $name =
            $self->meta->namespaced_name_for_original_name->{$original_name};
        my $index_obj = $self->index($original_name);
        if ($params{delete}) {
            $self->es->indices->delete(index => $name, ignore_unavailable => 'true');
        }
        $index_obj->deploy_to(index_name => $name);
    }
    return 1;
}

1;
