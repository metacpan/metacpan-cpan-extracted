# vim:ft=perl
use strict;
use warnings;

use Test::More 'no_plan';
BEGIN { use_ok('Email::MIME::ContentType'); }

my %cd_tests = (
    'inline' => { type => 'inline', attributes => {} },
    'attachment' => { type => 'attachment', attributes => {} },

    'attachment; filename=genome.jpeg; modification-date="Wed, 12 Feb 1997 16:29:51 -0500"' => {
        type => 'attachment',
        attributes => {
            filename => 'genome.jpeg',
            'modification-date' => 'Wed, 12 Feb 1997 16:29:51 -0500'
        }
    },

    q(attachment; filename*=UTF-8''genom%C3%A9.jpeg; filename=genome.jpeg; modification-date="Wed, 12 Feb 1997 16:29:51 -0500") => {
        type => 'attachment',
        attributes => {
            filename => "genom\x{E9}.jpeg",
            'modification-date' => 'Wed, 12 Feb 1997 16:29:51 -0500'
        }
    },

    q(attachment; filename=loooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooong; modification-date="Wed, 12 Feb 1997 16:29:51 -0500") => {
        type => 'attachment',
        attributes => {
            filename => 'loooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooong',
            'modification-date' => 'Wed, 12 Feb 1997 16:29:51 -0500'
        }
    },

    q(attachment; filename*0=loooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooo; filename*1=ong; filename=looooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooo...; modification-date="Wed, 12 Feb 1997 16:29:51 -0500") => {
        type => 'attachment',
        attributes => {
            filename => 'looooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooong',
            'modification-date' => 'Wed, 12 Feb 1997 16:29:51 -0500'
        }
    },

    q(attachment; filename="l\\"oooooooooooooooooooooooooooooooooooooooooooooooooooooooooooong"; modification-date="Wed, 12 Feb 1997 16:29:51 -0500") => {
        type => 'attachment',
        attributes => {
            filename => 'l"oooooooooooooooooooooooooooooooooooooooooooooooooooooooooooong',
            'modification-date' => 'Wed, 12 Feb 1997 16:29:51 -0500'
        }
    },

    q(attachment; filename*0="l\\"oooooooooooooooooooooooooooooooooooooooooooooooooooooooooooo"; filename*1="ong"; filename="l\"ooooooooooooooooooooooooooooooooooooooooooooooooooooooooooo..."; modification-date="Wed, 12 Feb 1997 16:29:51 -0500") => {
        type => 'attachment',
        attributes => {
            filename => 'l"ooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooong',
            'modification-date' => 'Wed, 12 Feb 1997 16:29:51 -0500'
        }
    },

    q(attachment; filename*=UTF-8''%C3%A9loooooooooooooooooooooooooooooooooooooooooooooooooong; filename=eloooooooooooooooooooooooooooooooooooooooooooooooooong; modification-date="Wed, 12 Feb 1997 16:29:51 -0500") => {
        type => 'attachment',
        attributes => {
            filename => "\x{E9}loooooooooooooooooooooooooooooooooooooooooooooooooong",
            'modification-date' => 'Wed, 12 Feb 1997 16:29:51 -0500'
        }
    },

    q(attachment; filename*0*=UTF-8''%C3%A9loooooooooooooooooooooooooooooooooooooooooooooooooo; filename*1*=ong; filename=elooooooooooooooooooooooooooooooooooooooooooooooooooong; modification-date="Wed, 12 Feb 1997 16:29:51 -0500") => {
        type => 'attachment',
        attributes => {
            filename => "\x{E9}looooooooooooooooooooooooooooooooooooooooooooooooooong",
            'modification-date' => 'Wed, 12 Feb 1997 16:29:51 -0500'
        }
    },

    q(attachment; filename*=UTF-8''%C3%A9%C3%A9%C3%A9%C3%A9%C3%A9%C3%A9%C3%A9%C3%A9%C3%A9; filename=eeeeeeeee) => {
        type => 'attachment',
        attributes => {
            filename => "\x{E9}\x{E9}\x{E9}\x{E9}\x{E9}\x{E9}\x{E9}\x{E9}\x{E9}"
        }
    },

    q(attachment; filename*0*=UTF-8''%C3%A9%C3%A9%C3%A9%C3%A9%C3%A9%C3%A9%C3%A9%C3%A9%C3%A9; filename*1*=%C3%A9; filename=eeeeeeeeee) => {
        type => 'attachment',
        attributes => {
            filename => "\x{E9}\x{E9}\x{E9}\x{E9}\x{E9}\x{E9}\x{E9}\x{E9}\x{E9}\x{E9}"
        }
    },

    q(attachment; filename="UTF-8''name") => {
        type => 'attachment',
        attributes => {
            filename => "UTF-8''name"
        }
    },
);

sub test {
    my ($expect, $struct) = @_;
    local $_;
    my $info = $expect;
    $info =~ s/\r/\\r/g;
    $info =~ s/\n/\\n/g;
    my $got = build_content_disposition($struct);
    is($got, $expect, "Can build C-D <$info>");
    my $parsed = parse_content_disposition($got);
    is_deeply($parsed, $struct, "Can parse C-D <$info>");
}

for (sort keys %cd_tests) {
    test($_, $cd_tests{$_});
}
