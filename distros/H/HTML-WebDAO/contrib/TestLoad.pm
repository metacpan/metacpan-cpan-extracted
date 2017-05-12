package TestLoad;
use strict;
use warnings;
use Test::More;
use Data::Dumper;
use HTML::WebDAO::Container;
use HTML::WebDAO::Component;
use base ( 'HTML::WebDAO::Container','HTML::WebDAO::Component' );

sub __get_objects_by_path {
    my $self = shift;
    my ( $path, $session ) = @_;
#    diag "PATH :".Dumper($path);
    my $eng =  $self->getEngine;
    my $name = $path->[0];
    if ( $name eq 'test.html') {
        diag $self->_obj_name .": detect self handler";
        shift @$path;
        unshift @$path,"view", $name;
        return $self;
    }
    my $autoload_obj = $eng->_createObj( $name,$name);
#    diag $session;
#    diag "return $autoload_obj";
    return $autoload_obj;# default return undef
}

sub view {
    return 1
}
1;
