package EO::Ops;
use strict;
use warnings;
use B::Concise ();

sub import {
    my $caller = caller;
    no strict 'refs';
    *{"${caller}::op_calls"} = \&op_calls;
}

# B names a custom op by its registered name from 5.14. Before that every
# custom op is "custom", and Ex::Op's is the only one here.
our $XOP = $] < 5.014 ? qr/\bcustom\b/ : qr/\bexop_call\b/;

# How many calls in the sub are op calls, and how many are ordinary.
sub op_calls {
    my ($name) = @_;
    my $out = '';
    B::Concise::walk_output(\$out);
    B::Concise::compile('-exec', $name)->();
    my $ops  = () = $out =~ /$XOP/g;
    my $subs = () = $out =~ /\bentersub\b/g;
    return [$ops, $subs];
}

1;
