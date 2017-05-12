package Gapp::Object;
{
  $Gapp::Object::VERSION = '0.60';
}

use Moose;
use MooseX::LazyRequire;
use MooseX::SemiAffordanceAccessor;
use MooseX::StrictConstructor;

use MooseX::Types::Moose qw( ArrayRef HashRef Str Undef );

use Gtk2;
use Gapp::Layout::Default;
use Gapp::Types qw( GappAction GappLayout );


# passed to gobject constructor

has 'args' => (
    is => 'rw',
    isa => 'Maybe[ArrayRef]',
);


# signals to connect to
has 'signal_connect' => (
    is => 'ro',
    isa => 'ArrayRef',
    default => sub { [ ] },
    reader => 'connected_signals',
);


# the method/function used to construct the gobject
has 'constructor' => (
    is => 'rw',
    isa => 'Str',
    default => 'new',
);

# allow user to customize widget, called after gobject is built
has 'customize' => (
    is => 'rw',
    isa => 'CodeRef|Undef',
);

# gobject class
has 'gclass' => (
    is => 'rw',
    isa => 'Str',
    lazy_required => 1,
);

# the actual gtk-widget
has 'gobject' => (
    is => 'rw',
    isa => 'Object',
    lazy_build => 1,
    predicate => 'has_gobject',
);

# explicitly set the layout
has 'layout' => (
    is => 'rw',
    isa => GappLayout|Undef,
    predicate => 'has_layout',
    coerce => 1,
);

# the layout to use (parent layout if not explicitly set for this widget)
has '_used_layout' => (
    is => 'rw',
    isa => GappLayout|Undef,
    clearer => '_clear_used_layout',
);



has '_gapp_signals' => (
    is => 'rw',
    isa => 'HashRef',
    default => sub { { } },
);


sub find_layout {
    my ( $self, $default ) = @_;
    return $self->_used_layout if $self->_used_layout;
    
    if ( $self->layout ) {
        $self->_set_used_layout( $self->layout );
    }
    else {
        if ( $self->can('parent') && $self->parent ) {
            $self->_set_used_layout( $self->parent->find_layout );
        }
        else {
            no warnings;
            $self->_set_used_layout( $default || $Gapp::Layout || Gapp::Layout::Default->Layout );
        }
    }
    return $self->_used_layout;
}

sub _forget_layout {
    my ( $self ) = @_;
    $self->_clear_used_layout;
    
    if ( $self->can('children') ) {
        $_->_forget_layout for $self->children;
    }
}

# for subclassing
sub _on_set_layout {
    
}



# properties to apply to the widget
has 'properties' => (
    is => 'ro',
    isa => 'HashRef',
    traits => [qw( Hash )],
    default => sub { { } },
    handles => {
        get_property => 'get',
        set_property => 'set',
    }
);

# gapp traits to apply
has 'traits' => (
    is => 'rw',
    isa => 'ArrayRef',
    default => sub { [ ] },
);

# we replace the new method with our own which applies any
# traits that may have been passed in
sub new {
    my ( $class, %args ) = @_;
    my ( $new_class, @traits ) = $class->interpolate_class(\%args);
    $new_class->_new( %args, ( scalar(@traits) ? ( traits => \@traits ) : () ) );
}

# access to Moose's new
sub _new {
    my ( $class, @args ) = @_;
    $class->SUPER::new( @args );
}


# create an anonamous class with the traits applied
# copied and modified from Moose::Meta::Attribute
sub interpolate_class {
    my ( $class, $options ) = @_;

    $class = ref( $class ) || $class;

    my @traits;
    if ( my $traits = $options->{traits} ) {
        
        my $i = 0;
        
        while ( $i < @$traits ) {
            
            my $trait = $traits->[$i++];
            
            next if ref($trait); # options to a trait we discarded
            
            # resolve short trait names
            $trait = Gapp::Util::resolve_gapp_trait_alias( Widget => $trait )
                  || $trait;
            
            next if $class->does( $trait );
            
            push @traits, $trait;
                
            # are there options?
            push @traits, $traits->[$i++]
                if $traits->[$i] && ref($traits->[$i]);
                
        }
        
        # apply the traits
        if ( @traits ) {
            $class = Moose::Util::with_traits( $class, @traits );
        }
    }

    return ( wantarray ? ( $class, @traits ) : $class );
}

# returns widgets higher in the heirarchy
sub find_ancestors {
    my ( $self ) = @_;
    my $parent = $self->parent;
    return $parent ? ( $parent, $parent->find_ancestors ) : ();
}

# returns the top-most widget in the heirarchy
sub find_toplevel {
    my ( $self ) = @_;
    my @ancestors = $self->find_ancestors;   
    return @ancestors ? $ancestors[-1] : $self;
}


# connect signals to the g-object
# connects the signal immediately if the g-object exists
# otherwise stores signal info to connect once g-object is constructed
sub signal_connect {
    my ( $self, $name, $code, @args ) = @_;
    

    
    # attach the signal if the gtk widget has been constructed
    if ( $self->has_gobject ) {
        $self->_apply_signal( [ $name, $code, @args ] );
    }
    else {
        push @{ $self->connected_signals }, [ $name, $code, @args ];
    }
}



# call customize code-ref if set
sub _apply_customize {
    my ( $self ) = @_;
    $self->customize->( $self, $self->gobject ) if $self->customize;
}

# call builder method from layout
sub _apply_builders {
    my ( $self ) = @_;
    no warnings;
    $self->find_layout->build_widget( $self );
}

# call builder method from layout
sub _apply_stylers {
    my ( $self ) = @_;
    no warnings;
    $self->find_layout->style_widget( $self );
}

# call builder method from layout
sub _apply_painters {
    my ( $self ) = @_;
    no warnings;
    $self->find_layout->paint_widget( $self ) if $self->can('action') && $self->action;
}

# apply any properties to the gobject
sub _apply_properties {
    my ( $self ) = @_;
    for my $p ( keys %{ $self->properties } ) {
        my $value = $self->properties->{$p};
        $self->gobject->set( $p, $self->properties->{$p} );
    }
}

# apply any signals to the gobject
sub _apply_signals {
    my ( $self ) = @_;
    map { $self->_apply_signal( $_ ) } @{ $self->connected_signals };
}

sub _apply_signal {
    my ( $self, $signal ) = @_;
    my ( $name, $action, @args ) = @$signal;
    
    return if $name =~ /^gapp/;
    
    if ( is_GappAction( $action ) ) {
        $self->gobject->signal_connect( $name => sub {
            my ( $gtkw, @gtkargs ) = @_;
            return $action->perform( $self, \@args, $gtkw,  \@gtkargs );
        });
    }
    else {
        $self->gobject->signal_connect( $name => sub {
            my ( $gtkw, @gtkargs ) = @_;
            return $action->( $self, \@args, $gtkw,  \@gtkargs );
        });
    }
}

# construct and format the widget
sub _build_gobject {
    my ( $self ) = @_;

    $self->_apply_stylers;
    
    my $w = $self->_construct_gobject( @_ );
    $self->_apply_properties;
    $self->_apply_builders;
    $self->_apply_painters;
    $self->_apply_signals;
    $self->_apply_customize;

    return $w;
}


# create and set the actual gobject
sub _construct_gobject {
    my ( $self ) = @_;
    
    my $gclass = $self->gclass;
    my $gconstructor = $self->constructor;
    
    # use any build-arguments if they exist
    my $w = $gclass->$gconstructor( $self->args ? @{$self->args} : ( ) );
    $self->set_gobject( $w );
    return $w;
}



1;

__END__

=pod

=head1 NAME

Gapp::Widget - The base class for all Gapp widgets

=head1 OBJECT HIERARCHY

=over 4

=item L<Gapp::Widget>

=back

=head1 DESCRIPTION

All Gapp widgets inherit from L<Gapp::Widget>.

=head1 PROVIDED ATTRIBUTES

=over 4

=item B<args>

=over 4

=item isa: ArrayRef|Undef

=item default: undef

=back

If C<args> is set, the contents of the ArrayRef will be passed into the
constructor when the Gtk+ widget is instantiated. The example below will create
a popup window instead of a standard toplevel window.

 Gapp::Window->new( args => [ 'popup' ] );

=item B<gclass>

=over 4

=item isa: ClassName

=item required: lazy

=back

This is the class of the CGObject> to be created. Most Gapp widgets provide
this in their class definition, but you can override it by passing in your own
value.

 Gapp::Window->new( gclass => 'Gtk2::Ex::CustomWindow' );

=item B<constructor>

=over 4

=item isa: Str|CodeRef

=item default: new

=back

This constructor is called on the C<gclass> to instantiate a Gtk+ widget. Change
the constructor if you want to use the helpers provided by Gtk+ like
C<new_with_label> or C<new_with_mnemonic>.

=item B<customize>

=over 4

=item isa: CodeRef|Undef

=item default: undef

=back

Setting the C<customize> attribute allows you to tweak the Gtk+ widget after it
has been instantiated. Use this sparingly, you should define the appearnce of
your widgets using L<Gapp::Layout>.

If you find you need to use C<customize> because parts of Gapp are incomplete,
or could be remedied by more robustness, please file a bug or submit a patch.

=item B<expand>

=over 4

=item isa: Bool

=item default: 0

=back

If the widget should expand inside it's container. (Table widgets ignore this
value because widget expansion is determind by the L<Gapp::TableMap>)

=item B<fill>

=over 4

=item isa: Bool

=item default: 0

=back

If the widget should fill it's container. (Table widgets ignore this value
because widget layout is determind by the L<Gapp::TableMap>)

=back

=item B<gobject>

=over 4

=item isa: Object

=item default: 0

=back

The actual C<GObject> instance. The C<GObject> will be constructed the first time it
is requested. After the object has been constructed, changes you make to the
Gapp layer will not be reflected in the Gtk+ widget.

=item B<layout>

=over 4

=item isa: L<Gapp::Layout::Object>

=item default: L<Gapp::Layout::Default>

=back

The layout used to determine widget positioning.

=item B<padding>

=over 4

=item isa: Int

=item default: 0

=back

Padding around the widget.

=item B<parent>

=over 4

=item isa: L<Gapp::Widget>|Undef

=item default: undef

=back

The parent widget.

=item B<properties>

=over 4

=item isa: HashRef

=item handles:

=over 4

=item get:

get_property

=item set:

set_property

=back

=item B<traits>

=over 4

=item isa: ArrayRef

=item default: []

=back

The traits to apply to the widget.

=back

=head1 AUTHORS

Jeffrey Ray Hallock E<lt>jeffrey.hallock at gmail dot comE<gt>

=head1 COPYRIGHT & LICENSE

    Copyright (c) 2011-2012 Jeffrey Ray Hallock.

    This program is free software; you can redistribute it and/or
    modify it under the same terms as Perl itself.

=cut

