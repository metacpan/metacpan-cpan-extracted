package FormValidator::Simple::Constants;
use strict;
use base qw/Exporter/;
our @EXPORT = qw/SUCCESS FAIL TRUE FALSE/;

sub SUCCESS { 1 }
sub FAIL    { !SUCCESS }
sub TRUE    { 1 }
sub FALSE   { !TRUE }

1;
__END__

