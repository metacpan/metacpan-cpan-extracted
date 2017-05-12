package Gapp::Layout::Object;
{
  $Gapp::Layout::Object::VERSION = '0.60';
}

use Moose;
use MooseX::StrictConstructor;
use MooseX::SemiAffordanceAccessor;

use MooseX::Types::Moose qw( :all );

has 'parent' => (
    is => 'rw',
    isa => Object,
    weak_ref => 1,
    predicate => 'has_parent',
    clearer => 'clear_parent',
);

has '_builders' => (
    is => 'ro',
    isa => HashRef,
    default => sub { { } },
    init_arg => undef,
    traits => [qw( Hash )],
    handles => {
        add_builder => 'set',
        get_builder => 'get',
        has_builder => 'exists',
    }
);

has '_stylers' => (
    is => 'ro',
    isa => HashRef,
    default => sub { { } },
    init_arg => undef,
    traits => [qw( Hash )],
    handles => {
        add_styler => 'set',
        get_styler => 'get',
        has_styler => 'exists',
    }
);

has '_painters' => (
    is => 'ro',
    isa => HashRef,
    default => sub { { } },
    init_arg => undef,
    traits => [qw( Hash )],
    handles => {
        add_painter => 'set',
        get_painter => 'get',
        has_painter => 'exists',
    }
);

has '_packers' => (
    is       => 'ro',
    isa      => 'HashRef[HashRef]',
    default  => sub { { } },
    init_arg => undef,
    traits   => [ 'Hash' ],
);

# the "packer" is a code ref that is called to
# add a widget to a container 
sub add_packer {
    my ( $self, $widget, $container, $code_ref ) = @_;
    $self->_packers->{$widget}{$container} = $code_ref;
}

sub build_widget {
    my ( $self, $widget, $opts ) = @_;
    my $builder = $self->find_builder( $widget );
    
    return if ! $builder;
    
    $builder->( $self, $widget );
}




# search this layout and parent layouts for a builder that will DWIM
sub find_builder {
    my ( $self, $w, $opts ) = @_;
    $w = $w->meta->name if ref $w;

    # work around for dealing with classes that have traits applied
    if ( $w =~ /__ANON__/ ) {
        my ( $super ) = ( $w->meta->superclasses )[0];
        $w = $super->meta->name;
    }
    
    # widget superclasses ( minus Moose stuff )
    my @wisa = $w->meta->linearized_isa;
    splice @wisa,-1,1;
    
    for my $wclass ( @wisa ) {
        my $builder = $self->lookup_builder( $wclass );
        return $builder if $builder;
    }
}

#sub find_builder {
#    my ( $self, $w ) = @_;
#    $w = $w->meta->name if ref $w;
#    $w = ($w->meta->superclasses)[0]->meta->name if $w->meta->name =~ /__ANON__/;
#    return $self->get_builder( $w->meta->name ) if $self->get_builder( $w->meta->name );
#    return $self->parent ? $self->parent->find_builder( $w ) : undef;
#}


# search this layout and parent layouts for a packer that will DWIM
sub find_packer {
    my ( $self, $widget, $container ) = @_;
    $widget = $widget->meta->name if ref $widget;
    $container = $container->meta->name if ref $container;
    
    # work around for dealing with classes that have traits applied
    if ( $widget->meta->name =~ /__ANON__/ ) {
        my ( $super ) = ( $widget->meta->superclasses )[0];
        $widget = $super->meta->name;
    }
    if ( $container->meta->name =~ /__ANON__/ ) {
        my ( $super ) = ( $container->meta->superclasses );
        $container = $super->meta->name;
    }
    
    # widget superclasses ( minus Moose stuff )
    my @wisa = $widget->meta->linearized_isa;
    splice @wisa,-1,1;
    
    
    # container superclasses ( minus Moose stuff, minus non-container classes )
    my @cisa = $container->meta->linearized_isa;
    splice @cisa,-1,1;
    @cisa = grep { $_->isa('Gapp::Container') } @cisa; 
    
    for my $cclass ( @cisa ) {
        
        for my $wclass ( @wisa ) {
            my $packer = $self->lookup_packer( $wclass, $cclass );
            return $packer if $packer;
        }
        
    }
}

sub find_painter {
    my ( $self, $w ) = @_;
    $w = $w->meta->name if ref $w;
    
    $w = ($w->meta->superclasses)[0]->meta->name if $w =~ /__ANON__/;
    return $self->get_painter( $w->meta->name ) if $self->get_painter( $w->meta->name );
    return $self->parent ? $self->parent->find_painter( $w ) : undef;
}

# search this layout and parent layouts for a builder that will DWIM
sub find_styler {
    my ( $self, $w, $opts ) = @_;
    $w = $w->meta->name if ref $w;

    # work around for dealing with classes that have traits applied
    if ( $w =~ /__ANON__/ ) {
        my ( $super ) = ( $w->meta->superclasses )[0];
        $w = $super->meta->name;
    }
    
    # widget superclasses ( minus Moose stuff )
    my @wisa = $w->meta->linearized_isa;
    splice @wisa,-1,1;
    
    for my $wclass ( @wisa ) {
        my $styler = $self->lookup_styler( $wclass );
        return $styler if $styler;
    }
}


sub get_packer {
    my ( $self, $widget, $container ) = @_;
    $self->_packers->{$widget}{$container};
}

sub has_packer {
    my ( $self, $widget, $container ) = @_;
    exists $self->_packers->{$widget}{$container};
}


sub lookup_builder {
    my ( $self, $w ) = @_;
    
    if ( $self->has_builder( $w ) ) {
        return $self->get_builder( $w );
    }
    else {
        return $self->parent ?
        $self->parent->lookup_builder( $w ) :
        undef;
    }
}

# search this layout and parent layouts for specific packer
sub lookup_packer {
    my ( $self, $widget, $container ) = @_;
    
    if ( $self->has_packer( $widget, $container ) ) {
        return $self->get_packer( $widget, $container );
    }
    else {
        return $self->parent ?
        $self->parent->lookup_packer( $widget, $container ) :
        undef;
    }
}

sub lookup_styler {
    my ( $self, $w ) = @_;
    
    if ( $self->has_styler( $w ) ) {
        return $self->get_styler( $w );
    }
    else {
        return $self->parent ?
        $self->parent->lookup_styler( $w ) :
        undef;
    }
}




# pack a widget inside a container
sub pack_widget {
    my ( $self, $widget, $container ) = @_;

    my $packer = $self->find_packer( $widget , $container );
    
    # warn if cannot find packer
    if ( ! $packer ) {
        warn
            qq[could not pack ] . $widget->meta->name .
            qq[ into ] . $container->meta->name . qq[: ] .
            qq[no packer found in ]  .$self->meta->name;
        return;
    }
    
    # pack the widget
    $packer->( $self, $widget, $container );   
}

sub paint_widget {
    my ( $self, $widget, $opts ) = @_;
    my $painter = $self->find_painter( $opts->{as} ||  $widget );
    return if ! $painter;
    
    $painter->( $self, $widget );
}

sub style_widget {
    my ( $self, $widget, $opts ) = @_;
    my $builder = $self->find_styler( $opts->{as} ||  $widget );
    return if ! $builder;
    
    $builder->( $self, $widget );
}



no Moose;
__PACKAGE__->meta()->make_immutable();
1;
