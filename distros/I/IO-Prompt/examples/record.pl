use IO::Prompt -record;

# Loading the module with the -record flag causes it to record all inputs
# which are written to a file named ./__PROMPT__
#
# The contents of ./__PROMPT__ are suitable for appending as your __DATA__
# section to recreate the input process that was recorded (but don't forget to
# remove the -record flag first!)
#

prompt "next: ", -integer, -require => {
    'next (must be > 0):' => sub { $_ > 0 }
};
print "[$_]\n";

prompt "base: ", -i, -req => {
    '%s(an even number, please) ' => sub { $_ % 2 == 0 }
};
print "[$_]\n";

prompt "base: ", -req => { 'base [ACGT]: ' => qr/^[ACGT]$/ };
print "[$_]\n";

prompt "base: ", -req => { 'base [ACGT]: ' => [qw(A C G T skip)] };
print "[$_]\n";
