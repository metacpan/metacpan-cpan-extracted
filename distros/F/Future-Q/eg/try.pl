use strict;
use warnings;

{
    use Future::Q;

    ## Values returned from try() callback are transformed into a
    ## fulfilled Future::Q
    Future::Q->try(sub {
        return (1,2,3);
    })->then(sub {
        print join(",", @_), "\n"; ## -> 1,2,3
    });

    ## Exception thrown from try() callback is transformed into a
    ## rejected Future::Q
    Future::Q->try(sub {
        die "oops!";
    })->catch(sub {
        my $e = shift;
        print $e;       ## -> oops! at eg/try.pl line XX.
    });

    ## A Future returned from try() callback is returned as is.
    my $f = Future::Q->new;
    Future::Q->try(sub {
        return $f;
    })->then(sub {
        print "This is not executed.";
    }, sub {
        print join(",", @_), "\n";  ## -> a,b,c
    });
    $f->reject("a", "b", "c");
}
