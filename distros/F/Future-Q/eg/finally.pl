use strict;
use warnings;

package Some::Resource;
use Future::Q;

sub new {
    my $class = shift;
    return bless {}, $class;
}

sub open { return Future::Q->new->fulfill(Some::Resource->new) }

sub read_data {
    return @ARGV ? Future::Q->new->reject("error!!!") : Future::Q->new->fulfill("success!!!");
}

sub close { print "Closed\n" }


package main;




use Future::Q;

my $handle;

## Suppose Some::Resource->open() returns a handle to a resource (like
## database) wrapped in a Future

Some::Resource->open()->then(sub {
    $handle = shift;
    return $handle->read_data(); ## Read data asynchronously
})->then(sub {
    my $data = shift;
    print "Got data: $data\n";
})->finally(sub {
    ## Ensure closing the resource handle. This callback is called
    ## even when open() or read_data() fails.
    $handle->close() if $handle; 
});
