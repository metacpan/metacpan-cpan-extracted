#hashref.pl

use strict;

sub My::subroutine {
    my $hashref = shift;

    while(my($k,$v) = each %$hashref) {
	print "in Perl: $k=`$v'\n"; 
    }

    $hashref->{foo} = "bar";
    $hashref->{willi} = "nilli";
}

__END__
