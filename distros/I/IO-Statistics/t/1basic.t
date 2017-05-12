#!/usr/bin/perl -w
use Test::More tests => 4;
use IO::Statistics;
use IO::Handle;

my $write;
eval { IO::Statistics->count (undef, \$write, \*STDOUT, \*STDIN) };
ok ($@ =~ m/not supported/);

sub test_fh {
    my $fh = IO::Handle->new_from_fd (fileno (STDOUT), 'w');
    my $write = 0;
    IO::Statistics->count (undef, \$write, $fh);

    print $fh "fooo\n";
    is ($write, 5);

    print $fh "bkzlfdlkf\n";
    is ($write, 15);
}

sub test_scalar {
    my $scalar = 'foobarfnord';
    local $/;
    open my $fh, '<', \$scalar;
    my $read = 0;
    IO::Statistics->count (\$read, undef, $fh);
    <$fh>;
    is ($read, length($scalar));
}

&test_fh;
&test_scalar;
