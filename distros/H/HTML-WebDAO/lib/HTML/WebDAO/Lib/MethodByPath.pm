#$Id: MethodByPath.pm 212 2007-11-02 09:32:29Z zag $

package HTML::WebDAO::Lib::MethodByPath;
use HTML::WebDAO::Base;
use Data::Dumper;
use base qw(HTML::WebDAO::Component);
__PACKAGE__->attributes qw( _path _args );

sub init {
    my $self = shift;
    my ( $path, @args ) = @_;
    $self->_path($path);
    $self->_args( \@args );
    1;
}

sub fetch {
    my $self = shift;
    my $sess = shift;

    #first get object;
    my @path   = @{ $sess->call_path( $self->_path ) };
    my $method = pop @path;

    #try get object by path
    if ( my $object = $self->getEngine->_get_object_by_path( \@path ) ) {
        unless ($method) {
            _log1 $self "Method not found by path " . $self->_path;
            return;
        }
        else {

            #check and call method
            if ( UNIVERSAL::can( $object, $method ) ) {
                return $object->$method( @{ $self->_args } );
            }
            else {
                _log1 $self "Method: $method not found at class $object";
                return;
            }
        }

    }
    else {
        _log1 $self "ERRR: Not found object for path " . $self->_path;
    }
    return undef;
}

1;
