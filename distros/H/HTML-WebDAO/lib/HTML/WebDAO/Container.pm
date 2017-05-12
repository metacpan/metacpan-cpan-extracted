#$Id: Container.pm 215 2007-11-13 08:44:47Z zag $

package HTML::WebDAO::Container;
use HTML::WebDAO::Element;
use Data::Dumper;
use base qw(HTML::WebDAO::Element);
use strict 'vars';

#no strict 'refs';
__PACKAGE__->attributes qw/ __childs/;

sub _sysinit {
    my $self = shift;

    #First invoke parent _init;
    $self->SUPER::_sysinit(@_);

    #initalize "childs" array for this container
    $self->__childs( [] );

}

sub _get_vars {
    my $self = shift;
    my ( $res, $ref );
    $res = $self->SUPER::_get_vars;
    return $res;
}

sub _set_vars {
    my ( $self, $ref ) = @_;
    my $chld_name;
    $self->SUPER::_set_vars($ref);
}

=head3 _get_childs()

Return ref to childs array

=cut

sub _get_childs {
    return $_[0]->__childs;
}

=head3 _add_childs($object1[, $object2])

Insert set of objects into container

=cut

sub _add_childs {
    my $self   = shift;
    my @childs =
      grep { ref $_ }
      map { ref($_) eq 'ARRAY' ? @$_ : $_ }
      map { $_->__get_self_refs }
      grep { ref($_) && $_->can('__get_self_refs') } @_;
    return unless @childs;
    if ( $self->__parent ) {
        $_->_set_parent($self) for @childs;
        $self->getEngine->__restore_session_attributes(@childs);
    }
    push( @{ $self->__childs }, @childs );
}

#it for container
sub _set_parent {
    my ( $self, $par ) = @_;
    $self->SUPER::_set_parent($par);
    foreach my $ref ( @{ $self->__childs } ) {
        $ref->_set_parent($self);
    }
}

sub _call_method {
    my $self = shift;
    my ( $name, @path ) = @{ shift @_ };
    return $self->SUPER::_call_method( [ $name, @path ], @_ ) || do {
        if ( my $obj = $self->_get_obj_by_name($name) ) {
            if ( ref($obj) eq 'HASH' ) {
                LOG $self Dumper( [ map { [ caller($_) ] } ( 1 .. 6 ) ] );
                $self->LOG( " got $obj for $name" . Dumper($obj) );
            }
            $obj->_call_method( \@path, @_ );
        }
        else {
            _log4 $self "Cant find obj for name $name in "
              . $self->__my_name() . ":"
              . Dumper( [ map { $_->__my_name } @{ $self->_get_childs } ] );
            return;
        }
      }
}

sub _get_obj_by_name {
    my $self = shift;
    my $name = shift;
    return unless defined $name;
    my $res;
    foreach my $obj ( $self, @{ $self->__childs } ) {
        if ( $obj->_obj_name eq $name ) {
            return $obj;
        }
    }
    return;
}

=head2 fetch(@_), default call by webdao: fetch( $session )

Interate call fetch(@_) on childs

=cut

sub fetch {
    my $self = shift;
    my @res;
    for my $a ( @{ $self->__childs } ) {
        push( @res, @{ $a->_format(@_) } );
    }
    return \@res;

}

sub _destroy {
    my $self = shift;
    my @res;
    for my $a ( @{ $self->__childs } ) {
        $a->_destroy;
    }
    $self->__childs( [] );
    $self->SUPER::_destroy;
}

=head2 _get_object_by_path <$path>, [$session]

Return first Element object for path.
Try to load objects for current object.

=cut

sub _get_object_by_path {
    my $self        = shift;
    my $path        = shift;
    my $session     = shift;
#    _log1 $self Dumper {'$self'=>ref($self), path=>$path};
    my @backup_path = @$path;
    my $next_name   = $path->[0];
    #first try get by name
    if ( my $obj = $self->_get_obj_by_name($next_name) ) {
        shift @$path;    #skip first name
                         #ok got it
                         #check if it container
                         #skip extra path
        if ( UNIVERSAL::can( $obj, '__extra_path' ) ) {
            my $extra_path = $obj->__extra_path;

            #if extra path defined and not ref convert to ref
            if ( defined $extra_path ) {
                $extra_path = [$extra_path] unless ref($extra_path);
            }
            if ( ref($extra_path) ) {
                my @extra = @$extra_path;

                #now skip extra
                for (@extra) {
                    if ( $path->[0] eq $_ ) {
                        shift @$path;
                    }
                    else {
                        _log2 $self "Break __extra_path "
                          . $path->[0] . " <> "
                          . $_
                          . " for : $obj";
                        last;
                    }
                }
            }
        }
        if ( $obj->isa('HTML::WebDAO::Container') ) {
            return $obj unless @$path;    # return object if end of path
            return $obj->_get_object_by_path( $path, $session );
        }
        else {

            #if element return point in any way
            return $obj

              #            my $method = $path->[0] || 'index_html';
              #            #if it element try to can method
              #            return $obj->can($method) ? $obj : undef;
        }
    }
    else {

        #try get objects by special methods
        my $dyn = $self->__get_objects_by_path( $path, $session )
          || return;    #break search

        #handle self controlled objects
        if ( $dyn eq $self ) {
            return $self;
        }
        $dyn = [$dyn] unless ref($dyn) eq 'ARRAY';

        #now try find object in returned array
        my $next;
        foreach (@$dyn) {

            #skip non objects
            next unless $_->_obj_name eq $next_name;
            $next = $_;
            last;    #exit from loop loop
        }
        unless ($next) {
            return    # return undef unless find objects
        }
        else {

            # yes, from returned object present traverse continue
            #if defined $session ( load scene)
            if ($session) {
                $self->_add_childs(@$dyn);
                return $self->_get_object_by_path( $path, $session );
            }
            else {

                #if query without session
                #try to find  by name
                #ok got it
                #check if it container
                if ( $next->isa('HTML::WebDAO::Container') ) {
                    return $next->_get_object_by_path( $path, $session );
                }
                else {

                    #return object referense in any way
                    return $next;
                }
            }

        }
    }
}

=head2 __get_objects_by_path [path], $session

Return next object for path 

=cut

sub __get_objects_by_path {
    my $self = shift;
    my ( $path, $session ) = @_;
    # check if path point to method
    return $self if $self->can($path->[0]);
    return;    # default return undef
}

1;
