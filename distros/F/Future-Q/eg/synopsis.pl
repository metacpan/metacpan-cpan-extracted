use strict;
use warnings;

our $result_of_func = "on_success";

sub other_async_func {
    my (%args) = @_;
    warn "--- other_async_func\n";
    @_ = ("failure");
    goto $args{$result_of_func};
}

sub bad_func {
    die "something terrible happened.";
}

sub do_some_processing {
    return @_;
}


foreach my $this_result_of_func (qw(on_success on_failure)) {
    local $result_of_func = $this_result_of_func;
    warn "------ case: $this_result_of_func\n";

    
    use Future::Q;

    sub async_func_future {
        my @args = @_;
        my $f = Future::Q->new;
        other_async_func(   ## This is a regular callback-style async function
            args => \@args,
            on_success => sub { $f->fulfill(@_) },
            on_failure => sub { $f->reject(@_) },
        );
        return $f;
    }

    async_func_future()->then(sub {
        my @results = @_;
        my @processed_values = do_some_processing(@results);
        return @processed_values;
    })->then(sub {
        my @values = @_;   ## same values as @processed_values
        return async_func_future(@values);
    })->then(sub {
        warn "Operation finished.\n";
    })->catch(sub {
        ## failure handler
        my $error = shift;
        warn "Error: $error\n";
    });

}
