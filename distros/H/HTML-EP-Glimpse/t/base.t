# -*- perl -*-

print "1..3\n";

my $i = 0;
foreach my $p (qw(HTML::EP::Glimpse::Config HTML::EP::Glimpse::Install
                  HTML::EP::Glimpse)) {
    ++$i;
    eval "use $p";
    if (my $status = $@) {
	print STDERR $@;
	print "not ok $i\n";
    } else {
	print "ok $i\n";
    }
}
