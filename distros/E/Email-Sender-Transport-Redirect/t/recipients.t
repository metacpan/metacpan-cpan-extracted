#perl

use strict;
use warnings;
use Test::More tests => 14;
use Email::Sender::Transport::Redirect::Recipients;
use Data::Dumper;

{
    my $str = 'pippo@example.com';
    my $rec = Email::Sender::Transport::Redirect::Recipients->new($str);
    is $rec->to, $str, "to is $str";
    is_deeply $rec->exclude, [], "No exclusion";
}

{
    my %hash = (to => 'pippo@example.com', exclude => ['racke@example.com', '*@linuxia.de']);
    my $rec = Email::Sender::Transport::Redirect::Recipients->new(\%hash);
    foreach my $f (qw/to exclude/) {
        is_deeply $rec->$f, $hash{$f}, "$f is ok";
    }
    is $rec->replace('racke@example.com'), 'racke@example.com';
    is $rec->replace('racke@linuxia.de'), 'racke@linuxia.de';
    is $rec->replace('Racke <racke@example.com>'), 'racke@example.com';
    is $rec->replace('racke <racke@linuxia.de>'), 'racke@linuxia.de';
    # diag Dumper($rec);
    is $rec->replace(), 'pippo@example.com';
    is $rec->replace('melmothx@gmail.com'), 'pippo@example.com';
    is $rec->replace('Marco <melmothx@gmail.com>'), 'pippo@example.com';
}

{
    my @dummy = ('racke@example.com', '*@linuxia.de');
    my $rec = eval { Email::Sender::Transport::Redirect::Recipients->new(@dummy) };
    ok !$rec, "Bad arguments trigger an exception: $@";
}

{
    my @dummy = ('racke@example.com', '*@linuxia.de');
    my $rec = eval { Email::Sender::Transport::Redirect::Recipients->new(\@dummy) };
    ok !$rec, "Bad arguments trigger an exception: $@";
}


{
    my %hash = (to => 'pippo@example.com', exclude => ['racke@example.com', '*@linuxia.de'],
                dummy => 'adfa');
    my $rec = eval { Email::Sender::Transport::Redirect::Recipients->new(\%hash) };
    ok !$rec, "Extra arguments trigger an exception: $@";
}
