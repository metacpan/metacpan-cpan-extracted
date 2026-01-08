package Local::Mitey::MOP;

use Moose ();
use Moose::Util ();
use Moose::Util::MetaRole ();
use Moose::Util::TypeConstraints ();
use constant { true => !!1, false => !!0 };

my $META_CLASS = do {
    package Local::Mitey::MOP::Meta::Class;
    use Moose;
    extends 'Moose::Meta::Class';
    around _immutable_options => sub {
        my ( $next, $self, @args ) = ( shift, shift, @_ );
        return $self->$next( replace_constructor => 1, @args );
    };
    __PACKAGE__->meta->make_immutable;

    __PACKAGE__;
};

my $META_ROLE = do {
    package Local::Mitey::MOP::Meta::Role;
    use Moose;
    extends 'Moose::Meta::Role';
    my $built_ins = qr/\A( DOES | does | __META__ | __FINALIZE_APPLICATION__ |
        CREATE_CLASS | APPLY_TO )\z/x;
    around get_method => sub {
        my ( $next, $self, $method_name ) = ( shift, shift, @_ );
        return if $method_name =~ $built_ins;
        return $self->$next( @_ );
    };
    around get_method_list => sub {
        my ( $next, $self ) = ( shift, shift );
        return grep !/$built_ins/, $self->$next( @_ );
    };
    around _get_local_methods => sub {
        my ( $next, $self ) = ( shift, shift );
        my %map = %{ $self->_full_method_map };
        return map $map{$_}, $self->get_method_list;
    };
    __PACKAGE__->meta->make_immutable;

    __PACKAGE__;
};

require "Local/Mitey.pm";

{
    my $PACKAGE = $META_CLASS->initialize( "Local::Mitey", package => "Local::Mitey" );
    my %ATTR;
    $ATTR{"foo"} = Moose::Meta::Attribute->new( "foo",
        __hack_no_process_options => true,
        associated_class => $PACKAGE,
        definition_context => { context => "has declaration", file => "lib/Local/Mitey.pm", line => "5", package => "Local::Mitey", toolkit => "Mite", type => "class" },
        is => "ro",
        weak_ref => false,
        init_arg => "foo",
        required => false,
        type_constraint => do { require Types::Standard; Types::Standard::Str() },
        reader => "foo",
        default => "Foo",
        lazy => false,
    );
    {
        my $ACCESSOR = Moose::Meta::Method::Accessor->new(
            accessor_type => 'reader',
            attribute => $ATTR{"foo"},
            name => "foo",
            body => \&Local::Mitey::foo,
            package_name => "Local::Mitey",
            definition_context => { context => "has declaration", description => "reader Local::Mitey::foo", file => "lib/Local/Mitey.pm", line => "5", package => "Local::Mitey", toolkit => "Mite", type => "class" },
        );
        $ATTR{"foo"}->associate_method( $ACCESSOR );
        $PACKAGE->add_method( $ACCESSOR->name, $ACCESSOR );
    }
    do {
        no warnings 'redefine';
        local *Moose::Meta::Attribute::install_accessors = sub {};
        $PACKAGE->add_attribute( $ATTR{"foo"} );
    };
    $PACKAGE->add_method(
        "meta" => Moose::Meta::Method::Meta->_new(
            name => "meta",
            body => \&Local::Mitey::meta,
            package_name => "Local::Mitey",
        ),
    );
    Moose::Util::TypeConstraints::find_or_create_isa_type_constraint( "Local::Mitey" );
}


true;

