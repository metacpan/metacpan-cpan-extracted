use strict;
use warnings;
use Test::More;

# The SIGPIPE caveat is a documentation-only promise (P15): make sure it
# cannot be silently lost from the POD.

open my $fh, '<', 'lib/EV/Kafka.pm' or die "cannot open lib/EV/Kafka.pm: $!";
my $pod = do { local $/; <$fh> };

plan tests => 3;

like $pod, qr/^=head1 CAVEATS/m, 'CAVEATS section present';
like $pod, qr/SIGPIPE/, 'SIGPIPE hazard documented';
like $pod, qr/\$SIG\{PIPE\} = 'IGNORE'/, 'IGNORE recommendation documented';
