package Elasticsearch::Model::Index;

use Moose;
use Class::Load;

has namespace => (
    is => 'ro',
    isa => 'Maybe[Str]',
);

has [qw/namespaced_name name/]=> (
    is  => 'ro',
    isa => 'Str',
);

has refresh_interval => (
    is => 'ro',
    default => '1s',
);

has [
    qw(
        shards
        replicas
        )
    ] => (
    is      => 'ro',
    isa     => 'Int',
    default => 1,
    );

has model => (
    is       => 'ro',
    does     => 'Elasticsearch::Model::Role',
    required => 1,
    handles  => [qw(es document_namespace)],
);

has type => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has type_meta => (
    is      => 'ro',
    isa     => 'Object',
    lazy    => 1,
    builder => '_build_type_meta',
);

sub _build_type_meta {
    my $self       = shift;
    my $type_class = $self->document_namespace . "::" . $self->type;
    Class::Load::load_class($type_class);
    return $type_class->meta;
}

has traits => (
    isa     => 'ArrayRef',
    is      => 'ro',
    default => sub { [] },
);

sub BUILD {
    my $self = shift;
    foreach my $trait (@{$self->traits}) {
        Moose::Util::ensure_all_roles($self, $trait);
    }
    return $self;
}

sub deployment_statement {
    my $self   = shift;
    my $deploy = {};
    $deploy->{mappings}{_doc} = $self->type_meta->mapping;
    my $model_meta = $self->model->meta;
    for (qw(filter analyzer tokenizer normalizer)) {
        my $method = "get_${_}_list";
        foreach my $name ($model_meta->$method) {
            my $get = "get_$_";
            $deploy->{settings}{analysis}{$_}{$name} =
                $model_meta->$get($name);
        }
    }
    $deploy->{settings}{index} = {
        number_of_shards   => $self->shards,
        number_of_replicas => $self->replicas,
        refresh_interval   => $self->refresh_interval,
        blocks => {
            read_only_allow_delete => 'false',
        },
    };

    return $deploy;
}

sub _deploy {
    my ($self, %args) = @_;
    my $index_name = $args{index_name} // $self->namespaced_name;
    my $delete = $args{delete};

    if ($delete) {
        $self->es->indices->delete(index => $index_name, ignore_unavailable => 'true');
    }

    my $t = $self->es->transport;

    my $dep     = $self->deployment_statement;
    my $mapping = delete $dep->{mappings};

    # Settings, like analyzers and filters
    $t->perform_request(
        {
            method => 'PUT',
            path   => "/$index_name",
            body   => $dep,
        }
    );
    sleep(1);

    # Mappings, like whatever fields
    while (my ($k, $v) = each %$mapping) {
        $t->perform_request(
            {
                method => 'PUT',
                path   => "/$index_name/$k/_mapping",
                body   => {$k => $v},
            }
        );
    }
    return 1;
}

sub deploy {
    my ($self, %args) = @_;
    $self->_deploy(%args);
}

sub deploy_to {
    my ($self, %args) = @_;
    $self->_deploy(%args);
}

sub refresh {
    my $self = shift;
    $self->es->indices->refresh(index => $self->namespaced_name, ignore_unavailable => 'true');
}

sub delete {
    my ($self, %args) = @_;
    my $index_name = $args{index} // $self->namespaced_name;
    $self->es->indices->delete(index => $index_name, ignore_unavailable => 'true');
}

__PACKAGE__->meta->make_immutable;

1;
