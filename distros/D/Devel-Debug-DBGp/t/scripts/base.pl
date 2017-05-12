my $i = 0;

for (1 .. 5) {
    $i += $_;
}

print STDOUT "STDOUT $i\n";
print STDERR "STDERR $i\n";
