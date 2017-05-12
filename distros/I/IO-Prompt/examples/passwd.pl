#! /usr/bin/perl -w

# Change what prompt echos for each input character
# (except <return> -- use the -nl flag for that)...

use IO::Prompt;

if (prompt "next: ", -echo => '*') {
    use Data::Dumper 'Dumper';
    warn Dumper [$_];
}

if (prompt "next: ", -echo => '.') {
    use Data::Dumper 'Dumper';
    warn Dumper [$_];
}

if (prompt "next: ", -echo => '') {
    use Data::Dumper 'Dumper';
    warn Dumper [$_];
}

if (prompt "next: ", -echo => '(*)') {
    use Data::Dumper 'Dumper';
    warn Dumper [$_];
}

