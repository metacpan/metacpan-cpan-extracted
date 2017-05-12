

unless(-e "t/multiplicity") {
    print "1..0\n";
    warn "skipping multiplicity tests\n" if $] < 5.00328; 
    exit();
}

print "1..2\n";
%Seen = ();

for (split /\n/, `t/multiplicity`) {
    $n++;
    die "already seen" unless /\b(\w+)_perl\b/ and not $Seen{$1}++;
    print "$_\n";
    print "ok $n\n"; 
}
