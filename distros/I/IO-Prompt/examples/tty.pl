#! /usr/bin/perl -w

# The -tty flag ensures that the prompt is sent to the tty, no matter what...

use IO::Prompt;

if (prompt -tty, "tty> ") {
    use Data::Dumper 'Dumper';
    warn Dumper [$_];
}

open $fh, ">/dev/null";

if (prompt -tty, $fh, "tty> ") {
    use Data::Dumper 'Dumper';
    warn Dumper [$_];
}

if (prompt "in> ") {
    use Data::Dumper 'Dumper';
    warn Dumper [$_];
}

if (prompt $fh, "in> ") {
    use Data::Dumper 'Dumper';
    warn Dumper [$_];
}
