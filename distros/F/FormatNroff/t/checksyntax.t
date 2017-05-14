my @modules = glob("*.pm");
my $modcount = @modules;

print STDERR "\n\n";
print "1..$modcount\n";
foreach $mod ( @modules ) {
    system("perl -cw $mod");
    print "ok\n";
}

1;

