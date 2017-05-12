package mock;

use strict;

use vars qw/ @calls /;

@calls = ();

sub reset { @calls = (); }
sub get_calls { @calls }


1;
__END__
