######################################################################
#
# 1016_io_threadsafe.t
#
# Copyright (c) 2019 INABA Hitoshi <ina@cpan.org> in a CPAN
######################################################################

# This file is encoded in UTF-8.
die "This file is not encoded in UTF-8.\n" if 'あ' ne "\xe3\x81\x82";
die "This script is for perl only. You are using $^X.\n" if $^X =~ /jperl/i;

use strict;
use FindBin;
use lib "$FindBin::Bin/../lib";
use IOas::CP932X;
use vars qw(@test);

@test = (
# 1 source: 1012_getc.t
    sub { open(FH,'>a'); print FH "\x82\xA0\x82\xA2"; close(FH); open(FH,'a');                      my $got = IOas::CP932X::getc(FH); close(FH); unlink('a'); $got eq 'あ' },
    sub { open(FH,'>a'); print FH "\x82\xA0\x82\xA2"; close(FH); open(FH,'a'); local(*STDIN) = *FH; my $got = IOas::CP932X::getc();   close(FH); unlink('a'); $got eq 'あ' },
    sub { open(FH,'>a'); print FH "\x9C\x5A\x9C\x5A"; close(FH); open(FH,'a');                      my $got = IOas::CP932X::getc(FH); close(FH); unlink('a'); $got eq '彁' },
    sub { open(FH,'>a'); print FH "\x9C\x5A\x9C\x5A"; close(FH); open(FH,'a'); local(*STDIN) = *FH; my $got = IOas::CP932X::getc();   close(FH); unlink('a'); $got eq '彁' },
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
# 11 source: 1013_readline.t
    sub { open(FH,'>a'); print FH "\x82\xA0\x82\xA2\n\x82\xA4\x82\xA6\n\x82\xA8\x82\xA9\n"; close(FH); open(FH,'a');                    my $got = IOas::CP932X::readline(FH); close(FH); unlink('a');  $got  eq "あい\n"               },
    sub { open(FH,'>a'); print FH "\x82\xA0\x82\xA2\n\x82\xA4\x82\xA6\n\x82\xA8\x82\xA9\n"; close(FH); open(FH,'a');                    my @got = IOas::CP932X::readline(FH); close(FH); unlink('a'); "@got" eq "あい\n うえ\n おか\n" },
    sub { open(FH,'>a'); print FH "\x82\xA0\x82\xA2\n\x82\xA4\x82\xA6\n\x82\xA8\x82\xA9\n"; close(FH); open(FH,'a'); local(*ARGV)= *FH; my $got = IOas::CP932X::readline();   close(FH); unlink('a');  $got  eq "あい\n"               },
    sub { open(FH,'>a'); print FH "\x82\xA0\x82\xA2\n\x82\xA4\x82\xA6\n\x82\xA8\x82\xA9\n"; close(FH); open(FH,'a'); local(*ARGV)= *FH; my @got = IOas::CP932X::readline();   close(FH); unlink('a'); "@got" eq "あい\n うえ\n おか\n" },
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
# 21 source: 1014_print.t
    sub { open(FH,'>a');                                     IOas::CP932X::print(FH,"あい\n"); close(FH);                  open(FH,'a'); my $got = <FH>; close(FH); unlink('a'); $got eq "\x82\xA0\x82\xA2\n" },
    sub { open(FH,'>a'); $_="あい\n";                        IOas::CP932X::print(FH);          close(FH);                  open(FH,'a'); my $got = <FH>; close(FH); unlink('a'); $got eq "\x82\xA0\x82\xA2\n" },
    sub { open(FH,'>a');              my $select=select(FH); IOas::CP932X::print("あい\n");    close(FH); select($select); open(FH,'a'); my $got = <FH>; close(FH); unlink('a'); $got eq "\x82\xA0\x82\xA2\n" },
    sub { open(FH,'>a'); $_="あい\n"; my $select=select(FH); IOas::CP932X::print();            close(FH); select($select); open(FH,'a'); my $got = <FH>; close(FH); unlink('a'); $got eq "\x82\xA0\x82\xA2\n" },
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
# 31 source: 1015_printf.t
    sub { open(FH,'>a');                        IOas::CP932X::printf(FH,'あ');               close(FH);                  open(FH,'a'); my $got = IOas::CP932X::readline(FH); close(FH); unlink('a'); $got eq 'あ'        },
    sub { open(FH,'>a');                        IOas::CP932X::printf(FH,'あ%04d', 1);        close(FH);                  open(FH,'a'); my $got = IOas::CP932X::readline(FH); close(FH); unlink('a'); $got eq 'あ0001'    },
    sub { open(FH,'>a');                        IOas::CP932X::printf(FH,'あ%sう', 'い');     close(FH);                  open(FH,'a'); my $got = IOas::CP932X::readline(FH); close(FH); unlink('a'); $got eq 'あいう'    },
    sub { open(FH,'>a');                        IOas::CP932X::printf(FH,'あ%1sう', 'い');    close(FH);                  open(FH,'a'); my $got = IOas::CP932X::readline(FH); close(FH); unlink('a'); $got eq 'あいう'    },
    sub { open(FH,'>a');                        IOas::CP932X::printf(FH,'あ%2sう', 'い');    close(FH);                  open(FH,'a'); my $got = IOas::CP932X::readline(FH); close(FH); unlink('a'); $got eq 'あいう'    },
    sub { open(FH,'>a');                        IOas::CP932X::printf(FH,'あ%3sう', 'い');    close(FH);                  open(FH,'a'); my $got = IOas::CP932X::readline(FH); close(FH); unlink('a'); $got eq 'あ いう'   },
    sub { open(FH,'>a');                        IOas::CP932X::printf(FH,'あ%-3sう', 'い');   close(FH);                  open(FH,'a'); my $got = IOas::CP932X::readline(FH); close(FH); unlink('a'); $got eq 'あい う'   },
    sub { open(FH,'>a');                        IOas::CP932X::printf(FH,'あ%-3sえ', 'いう'); close(FH);                  open(FH,'a'); my $got = IOas::CP932X::readline(FH); close(FH); unlink('a'); $got eq 'あいうえ'  },
    sub { open(FH,'>a');                        IOas::CP932X::printf(FH,'あ%-4sえ', 'いう'); close(FH);                  open(FH,'a'); my $got = IOas::CP932X::readline(FH); close(FH); unlink('a'); $got eq 'あいうえ'  },
    sub { open(FH,'>a');                        IOas::CP932X::printf(FH,'あ%-5sえ', 'いう'); close(FH);                  open(FH,'a'); my $got = IOas::CP932X::readline(FH); close(FH); unlink('a'); $got eq 'あいう え' },
# 41
    sub { open(FH,'>a'); my $select=select(FH); IOas::CP932X::printf('あ');                  close(FH); select($select); open(FH,'a'); my $got = IOas::CP932X::readline(FH); close(FH); unlink('a'); $got eq 'あ'        },
    sub { open(FH,'>a'); my $select=select(FH); IOas::CP932X::printf('あ%04d', 1);           close(FH); select($select); open(FH,'a'); my $got = IOas::CP932X::readline(FH); close(FH); unlink('a'); $got eq 'あ0001'    },
    sub { open(FH,'>a'); my $select=select(FH); IOas::CP932X::printf('あ%sう', 'い');        close(FH); select($select); open(FH,'a'); my $got = IOas::CP932X::readline(FH); close(FH); unlink('a'); $got eq 'あいう'    },
    sub { open(FH,'>a'); my $select=select(FH); IOas::CP932X::printf('あ%1sう', 'い');       close(FH); select($select); open(FH,'a'); my $got = IOas::CP932X::readline(FH); close(FH); unlink('a'); $got eq 'あいう'    },
    sub { open(FH,'>a'); my $select=select(FH); IOas::CP932X::printf('あ%2sう', 'い');       close(FH); select($select); open(FH,'a'); my $got = IOas::CP932X::readline(FH); close(FH); unlink('a'); $got eq 'あいう'    },
    sub { open(FH,'>a'); my $select=select(FH); IOas::CP932X::printf('あ%3sう', 'い');       close(FH); select($select); open(FH,'a'); my $got = IOas::CP932X::readline(FH); close(FH); unlink('a'); $got eq 'あ いう'   },
    sub { open(FH,'>a'); my $select=select(FH); IOas::CP932X::printf('あ%-3sう', 'い');      close(FH); select($select); open(FH,'a'); my $got = IOas::CP932X::readline(FH); close(FH); unlink('a'); $got eq 'あい う'   },
    sub { open(FH,'>a'); my $select=select(FH); IOas::CP932X::printf('あ%-3sえ', 'いう');    close(FH); select($select); open(FH,'a'); my $got = IOas::CP932X::readline(FH); close(FH); unlink('a'); $got eq 'あいうえ'  },
    sub { open(FH,'>a'); my $select=select(FH); IOas::CP932X::printf('あ%-4sえ', 'いう');    close(FH); select($select); open(FH,'a'); my $got = IOas::CP932X::readline(FH); close(FH); unlink('a'); $got eq 'あいうえ'  },
    sub { open(FH,'>a'); my $select=select(FH); IOas::CP932X::printf('あ%-5sえ', 'いう');    close(FH); select($select); open(FH,'a'); my $got = IOas::CP932X::readline(FH); close(FH); unlink('a'); $got eq 'あいう え' },
#
);

$|=1; print "1..",scalar(@test),"\n"; my $testno=1; sub ok { print $_[0]?'ok ':'not ok ',$testno++,$_[1]?" - $_[1]\n":"\n" } ok($_->()) for @test;

__END__
