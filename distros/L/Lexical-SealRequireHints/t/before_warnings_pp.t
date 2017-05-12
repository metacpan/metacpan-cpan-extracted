# No "use warnings" here because of the unique requirements of
# before_warnings.t.

do "t/setup_pp.pl" or die $@ || $!;
do "t/before_warnings.t" or die $@ || $!;

1;
