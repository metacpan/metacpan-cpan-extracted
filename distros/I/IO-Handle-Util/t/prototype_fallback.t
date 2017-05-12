#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use ok 'IO::Handle::Prototype::Fallback';

sub check_write_fh {
    my ( $fh, $buf ) = @_;

    isa_ok( $fh, "IO::Handle::Prototype::Fallback" );
    isa_ok( $fh, "IO::Handle::Prototype" );
    isa_ok( $fh, "IO::Handle" );

    can_ok( $fh, qw(getline read print write) );

    eval { $fh->getline };
    like( $@, qr/getline/, "dies on missing callback" );

    eval { $fh->getc };
    like( $@, qr/getc/, "dies on missing callback" );

    eval { $fh->read };
    like( $@, qr/read/, "dies on missing callback" );

    eval { $fh->print("foo") };
    is( $@, '', "no error" );
    is( $$buf, "foo", "print worked" );

    local $\ = "\n";
    local $, = " ";

    eval { $fh->print("foo", "bar") };
    is( $@, '', "no error" );
    is( $$buf, "foofoo bar\n", "print worked" );

    eval { $fh->write("foo") };
    is( $@, '', "no error" );
    is( $$buf, "foofoo bar\nfoo", "write worked" );

    eval { $fh->syswrite("foo", 1, 1) };
    is( $@, '', "no error" );
    is( $$buf, "foofoo bar\nfooo", "write worked" );

    eval { $fh->printf("%d hens", 5) };
    is( $@, '', "no error" );
    is( $$buf, "foofoo bar\nfooo5 hens\n", "printf worked" );

    $\ = "%%";

    eval { $fh->print("foo") };
    is( $@, '', "no error" );
    is( $$buf, "foofoo bar\nfooo5 hens\nfoo%%", "print worked" );

    eval { $fh->say("Hello, World!") };
    is( $@, '', "no error" );
    is( $$buf, "foofoo bar\nfooo5 hens\nfoo%%Hello, World!\n", "say worked" );
}

{
    my $buf = '';

    my $fh = IO::Handle::Prototype::Fallback->new(
        print => sub {
            my ( $self, @stuff ) = @_;
            no warnings 'uninitialized';
            $buf .= join($,, @stuff) . $\;
        },
    );

    check_write_fh($fh, \$buf);
}

foreach my $write (qw(write syswrite)) {
    my $buf = '';

    my $fh = IO::Handle::Prototype::Fallback->new(
        $write => sub {
            my ( $self, $str, $length, $offset ) = @_;
            $buf .= substr($str, $offset || 0, $length || length($str));
        },
    );

    check_write_fh($fh, \$buf);
}

{
    my $buf = '';

    my $fh = IO::Handle::Prototype::Fallback->new(
        __write => sub { $buf .= $_[1] },
    );
}

my $str = <<'EOF';
OH HAI
I am a file
with
several lines

it's fun to read me

using
methods
EOF

sub check_read_fh {
    my $make = shift;

    {
        my $fh = $make->($str);

        isa_ok( $fh, "IO::Handle::Prototype::Fallback" );
        isa_ok( $fh, "IO::Handle::Prototype" );
        isa_ok( $fh, "IO::Handle" );

        can_ok( $fh, qw(getline read print write) );

        eval { $fh->print("foo") };
        like( $@, qr/print/, "dies on missing callback" );

        eval { $fh->say("foo") };
        like( $@, qr/say/, "dies on missing callback" );

        local $/ = "\n";

        ok( !$fh->eof, "not eof" );

        my $line = <$fh>;

        is( $line, "OH HAI\n", "getline" );

        is( $fh->read(my $buf, 4), 4, "read 4 chars" );

        is($buf, "I am", "read with length");

        is( $fh->read($buf, 4, 4), 4, "read 4 more chars" );

        is( $buf, "I am a f", "read with offset" );

        ok( !$fh->eof, "not eof" );

        $buf .= $fh->getline;

        is( $buf, "I am a file\n", "getline interleaved with read" );

        $/ = \10;

        $buf = $fh->getline;

        is( length($buf), ${ $/ }, "getline with ref in IRS" );
        is( $buf, "with\nsever", "correct data" );

        is( $fh->getc(), 'a', "getc" );

        $fh->ungetc(ord('%'));
        is( $fh->getc(), '%', 'ungetc' );

        $buf .= 'a';

        $/ = "\n";

        $buf .= $fh->getline;

        is( $buf, "with\nseveral lines\n", "with undef IRS" );

        ok( !$fh->eof, "not eof" );

        my @lines = <$fh>;

        ok( $fh->eof, "eof reached" );

        is_deeply(
            \@lines,
            [
                "\n",
                "it's fun to read me\n",
                "\n",
                "using\n",
                "methods\n",
            ],
            "getlines",
        );

        is( $fh->getline, undef, "getline at EOF" );
    }

    {
        my $fh = $make->(join "\n", qw(foo bar gorch baz));

        ok( !$fh->eof, "not eof" );

        is( $fh->getline, "foo\n", "getline" );

        ok( !$fh->eof, "not eof" );

        local $/;

        is( $fh->getline, "bar\ngorch\nbaz", "slurp" );

        ok( $fh->eof, "eof" );
    }

    {
        my $fh = $make->("foobar");

        ok( !$fh->eof, "not eof" );

        is( $fh->read(my $buf, 4), 4, "read" );
        is( $buf, "foob" );

        ok( !$fh->eof, "not eof" );

        is( $fh->read($buf, 4), 2, "read to EOF" );
        is( $buf, 'ar' );

        ok( $fh->eof, "eof" );
    }
}

foreach my $cb ( qw(__read getline) ) {
    check_read_fh(sub {
        my $str = shift;

        IO::Handle::Prototype::Fallback->new(
            $cb => sub {
                if ( defined $str ) {
                    my $ret = $str;
                    undef $str;
                    return $ret;
                } else {
                    return;
                }
            },
        );
    });

    check_read_fh(sub {
        my $str = shift;

        my @array = split //, $str;

        IO::Handle::Prototype::Fallback->new(
            $cb => sub {
                if ( @array ) {
                    return shift @array;
                } else {
                    return;
                }
            },
        );
    });
}

check_read_fh(sub {
    my $str = shift;

    IO::Handle::Prototype::Fallback->new(
        read => sub {
            my ( $self, undef, $length ) = @_;

            if ( length($str) > $length ) {
                $_[1] = substr($str, 0, $length, '');
            } else {
                $_[1] = $str;
                $str = '';
            }

            return length($_[1]);
        },
    );
});

done_testing;

# ex: set sw=4 et:
