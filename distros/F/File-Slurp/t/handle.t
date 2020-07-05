use strict;
use warnings;

use File::Slurp qw(read_file write_file);

use IO::Handle ();
use Socket;
use Symbol;
use Test::More;

my @pipe_data = (
    '',
    'abc',
    'abc' x 100,
    'abc' x 1000,
);

plan tests => scalar(@pipe_data);

foreach my $data ( @pipe_data ) {
    my $size = length( $data );
    my $read_fh = gensym;
    my $write_fh = gensym;
    my $value;
    my $error;
    { # catch block
        local $@;
        $error = $@ || 'Error' unless eval {
            $value = socketpair($read_fh, $write_fh, AF_UNIX, SOCK_STREAM, PF_UNSPEC);
            1;
        }; # try
    }
    SKIP: {
        skip "Can't use socketpair", 1 unless $value;
        if (fork()) {
            $write_fh->close();
            my $res = read_file($read_fh);
            is($res, $data, "read_file: socketpair of $size bytes");
        }
        else {
            $read_fh->close();
            write_file($write_fh, $data);
            exit();
        }
    };
}
