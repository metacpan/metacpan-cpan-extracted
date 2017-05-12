package JS::jQuery::Loader::Source::Internet;

use JS::jQuery::Loader;
use JS::jQuery::Loader::Source::URI;
use JS::jQuery::Loader::Carp;

sub new {
    my $class = shift;
#    my $uri = "http://jqueryjs.googlecode.com/files/\%j";
    my $uri = "http://ajax.googleapis.com/ajax/libs/jquery/\%v/jquery\%.f.js";
    return JS::jQuery::Loader::Source::URI->new(uri => $uri, @_);
}

1;
