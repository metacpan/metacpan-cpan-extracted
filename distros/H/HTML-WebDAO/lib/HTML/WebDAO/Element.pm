#$Id: Element.pm 216 2007-11-13 08:48:37Z zag $

package HTML::WebDAO::Element;
use Data::Dumper;
use HTML::WebDAO::Base;
use base qw/ HTML::WebDAO::Base/;
use strict 'vars';
__PACKAGE__->attributes
  qw/ _format_subs __attribute_names __my_name __parent __path2me  __engine  __extra_path /;

sub _init {
    my $self = shift;
    $self->_sysinit( \@_ );    #For system internal inherites
    $self->init(@_);           # if (@_);
    return 1;
}

sub RegEvent {
    my $self    = shift;
    my $ref_eng = $self->getEngine;
    $ref_eng->RegEvent( $self, @_ );
}

#
sub _sysinit {
    my $self = shift;

    #get init hash reference
    my $ref_init_hash = shift( @{ $_[0] } );

    #_engine - reference to engine
    $self->__engine( $ref_init_hash->{ref_engine} );

    #_my_name - name of this object
    $self->__my_name( $ref_init_hash->{name_obj} );

    #init hash of attribute_names
    my $ref_names_hash = {};
    map { $ref_names_hash->{$_} = 1 } $self->get_attribute_names();

    #        _attribute_names $self $ref_names_hash;
    $self->__attribute_names($ref_names_hash);

    #init array of _format sub's references
    #    $self->_format_subs(
    #        [
    #            sub { $self->pre_format(@_) },
    #            sub { $self->format(@_) },
    #            sub { $self->post_format(@_) },
    #        ]
    #    );

}

sub init {

    #Public Init metod for modules;
}

sub _get_vars {
    my $self = shift;
    my $res;
    for my $key ( keys %{ $self->__attribute_names } ) {
        my $val = $self->get_attribute($key);
        no strict 'vars';
        $res->{$key} = $val if ( defined($val) );
        use strict 'vars';
    }
    return $res;
}

=head3 _get_childs()

Return ref to childs array

=cut

sub _get_childs {
    return [];
}

sub call_path {
    my $self = shift;
    my $path = shift;
    $path = [ grep { $_ } split( /\//, $path ) ];
    return $self->getEngine->_call_method( $path, @_ );
}

sub _call_method {
    my $self = shift;
    my ( $method, @path ) = @{ shift @_ };
    if ( scalar @path ) {

        #_log4 $self "Extra path @path $self";
        return;
    }
    unless ( $self->can($method) ) {
        _log4 $self $self->_obj_name . ": don't have method $method";
        return;
    }
    else {
        $self->$method(@_);
    }
}

sub __get_self_refs {
    return $_[0];
}

sub _set_parent {
    my ( $self, $parent ) = @_;
    $self->__parent($parent);
    $self->_set_path2me();
}

sub _set_path2me {
    my $self   = shift;
    my $parent = $self->__parent;
    if ( $self != $parent ) {
        ( my $parents_path = $parent->__path2me ) ||= "";
        my $extr = $parent->__extra_path;
        $extr = [] unless defined $extr;
        $extr = [$extr] unless ( ref($extr) eq 'ARRAY' );
        my $my_path = join "/", $parents_path, @$extr, $self->__my_name;
        $self->__path2me($my_path);
    }
    else {
        $self->__path2me('');
    }
}

sub _obj_name {
    return $_[0]->__my_name;
}

sub getEngine {
    my $self = shift;
    return $self->__engine;
}

sub SendEvent {
    my $self   = shift;
    my $parent = __parent $self;
    $self->_log1( "Not def parent $self name:"
          . ( $self->__my_name )
          . Dumper( \@_ )
          . Dumper( [ map { [ caller($_) ] } ( 1 .. 10 ) ] ) )
      unless $parent;
    $parent->SendEvent(@_);
}

sub pre_format {
    my $self = shift;
    return [];
}

sub _format {
    my $self = shift;
    my @res;
    push( @res, @{ $self->pre_format(@_) } );    #for compat
    if ( my $result = $self->fetch(@_) ) {
        push @res, ( ref($result) eq 'ARRAY' ? @{$result} : $result );
    }
    push( @res, @{ $self->post_format(@_) } );    #for compat

    \@res;
}

sub format {
    my $self = shift;
    return shift;
}

sub post_format {
    my $self = shift;
    return [];
}

sub fetch { my $self = shift; return [] }

sub _destroy {
    my $self = shift;
    $self->__parent(undef);
    $self->__engine(undef);
    $self->_format_subs(undef);
}

sub _set_vars {
    my ( $self, $ref, $names ) = @_;
    $names = $self->__attribute_names;
    for my $key ( keys %{$ref} ) {
        if ( exists( $names->{$key} ) ) {
            $self ->${key}( $ref->{$key} );
        }
        else {

            # Uknown attribute ???

        }
    }
}

=head2 __get_objects_by_path [path], $session

Check if exist method in $path and return $self or undef

=cut

sub __get_objects_by_path {
    my $self = shift;
    return;
}
1;
