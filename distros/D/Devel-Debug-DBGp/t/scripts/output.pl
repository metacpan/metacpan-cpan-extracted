my $i = 0;

for (1 .. 3) {
    $i += $_;
    print STDOUT "i = $i, ";
    print STDERR "I = $i, ";
}

print STDOUT "done\n";
print STDERR "DONE\n";
