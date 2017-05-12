use IO::Prompt;

# This example demostrates how prompt autosets $_ when appropriate

# Case 1...
undef $_;
my $first = prompt "1> ";
print defined() ? "(\$_ was '$_')\n" : "(\$_ was undef)\n";
print "Got: $first\n";

# Case 2...
undef $_;
prompt "2> ";
print defined() ? "(\$_ was '$_')\n" : "(\$_ was undef)\n";
print "Got: [$_]\n";

# Case 3...
undef $_;
while (prompt "3> ") {
    print defined() ? "(\$_ was '$_')\n" : "(\$_ was undef)\n";
    print "Got: [$_]\n";
    last if $_ ne "\n";
}

# Case 4...
undef $_;
while (my $next = prompt "4> ") {
    print defined() ? "(\$_ was '$_')\n" : "(\$_ was undef)\n";
    print "Got: $next\n";
    last if $next ne "\n";
}
