use strict;
use Test::More tests => 24;

use Devel::Hints qw(cop_file cop_line);

{
    my $sub = sub {
        warn 'foo';
        warn 'foo';
#line 234 "something else"
        warn 'foo';
        warn 'foo';
#line 14 "t/4-file-line.t"
        warn 'foo';
        warn 'foo';
    };

    {
        my @files = (
            ('t/4-file-line.t') x 2,
            ('something else') x 2,
            ('t/4-file-line.t') x 2,
        );
        my $i = 0;
        local $SIG{__WARN__} = sub { like($_[0], qr/at $files[$i++] line/) };
        $sub->();
    }

    cop_file($sub, "set by cop_file");

    {
        my @files = (
            ('set by cop_file') x 2,
            ('something else') x 2,
            ('set by cop_file') x 2,
        );
        my $i = 0;
        local $SIG{__WARN__} = sub { like($_[0], qr/at $files[$i++] line/) };
        $sub->();
    }
}

{
    my $sub = sub {
        warn 'foo';
        warn 'foo';
#line 234 "something else"
        warn 'foo';
        warn 'foo';
#line 51 "t/4-file-line.t"
        warn 'foo';
        warn 'foo';
    };

    {
        my @lines = qw(45 46 234 235 51 52);
        my $i = 0;
        local $SIG{__WARN__} = sub { like($_[0], qr/line $lines[$i++]\b/) };
        $sub->();
    }

    cop_line($sub, 1234);

    {
        # XXX: this is somewhat questionable, but it's not really possible to
        # do it any other way (the information that a #line thing happened is
        # lost after the sub is compiled), and it's probably going to be what
        # the person means anyway
        my @lines = qw(1234 1235 234 235 1240 1241);
        my $i = 0;
        local $SIG{__WARN__} = sub { like($_[0], qr/line $lines[$i++]\b/) };
        $sub->();
    }
}
