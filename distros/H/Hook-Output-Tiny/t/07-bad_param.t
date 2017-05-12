#!/usr/bin/perl
use strict;
use warnings;

use Hook::Output::Tiny;
use Test::More;

my $mod = 'Hook::Output::Tiny';

{ # hook
    my $h = $mod->new;

    eval { $h->hook('bad'); 1; };
    like ($@, qr/\Qhook() either takes\E/, "hook() with bad param dies");
}
{ # unhook
    my $h = $mod->new;

    eval { $h->unhook('bad'); 1; };
    like ($@, qr/\Qunhook() either takes\E/, "unhook() with bad param dies");
}
{ # flush
    my $h = $mod->new;

    eval { $h->flush('bad'); };
    like ($@, qr/\Qflush() either takes\E/, "flush() with bad param dies");
}
{ # write
    my $h = $mod->new;

    eval { $h->write('file.txt', 'bad'); };
    like ($@, qr/\Qwrite() either takes\E/, "write() with bad param dies");
}
{ # write filename
    my $h = $mod->new;

    eval { $h->write('stdout'); };
    like ($@, qr/\Qwrite() requires a file\E/, "write() requires a file");
}
done_testing();

