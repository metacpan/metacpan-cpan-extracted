package Elasticsearch::Model::Document::Role::Metaclass;

use Moose::Role;


has shortname => (
    is      => 'ro',
    builder => '_build_shortname',
    lazy    => 1,
);

sub _build_shortname {
    my $self = shift;
    ( my $name = $self->name ) =~ s/^.*:://;
    return lc($name);
}

has _all_properties => (
    is      => 'ro',
    lazy    => 1,
    builder => '_build_all_properties',
);

sub _build_all_properties {
    return [
        grep { $_->does('Elasticsearch::Model::Document::Attribute::Role::MappingParameters') }
            shift->get_all_attributes
    ];
}

has _isa_arrayref => (
    is      => 'ro',
    lazy    => 1,
    builder => '_build_isa_arrayref',
);

sub _build_isa_arrayref {
    return {
        map {
            $_->name => $_->isa_arrayref
        } @{shift->_all_properties}
    };
}

sub mapping {
    my $self   = shift;
    my $props  = { map { $_->mapping } $self->get_all_properties };
    return {
        properties => $props,
        map { $_->type_mapping } $self->get_all_properties,
    };
}

sub add_property {
    my ( $self, $name ) = ( shift, shift );
    Moose->throw_error('Usage: has \'name\' => ( key => value, ... )')
        if @_ % 2 == 1;
    my %options = ( definition_context => _caller_info(), @_ );
    $options{traits} //= [];
    push(
        @{ $options{traits} },
        'Elasticsearch::Model::Document::Attribute::Role::MappingParameters'
    );
    my $attrs = ( ref($name) eq 'ARRAY' ) ? $name : [ ($name) ];
    $self->add_attribute( $_, %options ) for @$attrs;
}

sub _caller_info {
    my $level = @_ ? ( $_[0] + 1 ) : 2;
    my %info;
    @info{qw(package file line)} = caller($level);
    return \%info;
}

sub get_all_properties {
    my $self = shift;
    return @{$self->_all_properties}
        if ($self->is_immutable);
    return @{$self->_build_all_properties};
}

1;
