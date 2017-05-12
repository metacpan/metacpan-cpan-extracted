#regex.pl

use strict;
use vars qw(@Matches);

sub regex {
    my($string, $operation) = @_;
    my $n;
    #hold matches in an array that our C program can access
    @Matches = ();

    #we use eval here so we can interpolate m//, s/// and tr///

    #if we are trying to match something with m//  
    if($operation =~ m:^m:) {
	eval "\@Matches = (\$\$string =~ $operation)";
	$n = scalar @Matches;
    }
    else {
	eval "\$n = (\$\$string =~ $operation)";
    }
    return $n;
}

1;
