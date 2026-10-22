package EO::Ops;
use strict;
use warnings;
use B::Concise ();

sub import {
    my $caller = caller;
    no strict 'refs';
    *{"${caller}::op_calls"} = \&op_calls;
}

# How many calls in the sub are op calls, and how many are ordinary.
sub op_calls {
    my ($name) = @_;
    my $out = '';
    B::Concise::walk_output(\$out);
    B::Concise::compile('-exec', $name)->();
    my $ops  = () = $out =~ /\bexop_call\b/g;
    my $subs = () = $out =~ /\bentersub\b/g;
    return [$ops, $subs];
}

1;
