use IO::Prompt;

# The -require flag allows you to specify conditions that must be met by
# the input string...
#
# Each key of the hash is the error message to be printed if the corresponding
# value doesn't match the input. A %s in the error message is replaced with
# the current prompt.
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

