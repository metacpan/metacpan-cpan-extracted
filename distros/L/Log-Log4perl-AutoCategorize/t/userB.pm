
package userB;

sub import {
    my @args = @_;
    my @caller = (caller(0))[0..2];
    print "importing into: @caller, with: @args\n";
}

1;
