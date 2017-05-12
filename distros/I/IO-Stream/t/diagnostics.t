use warnings;
use strict;
use t::share;

plan tests => 19;

throws_ok { IO::Stream->new()                                   } qr/usage:/;
throws_ok { IO::Stream->new(undef)                              } qr/usage:/;
throws_ok { IO::Stream->new(1)                                  } qr/usage:/;
throws_ok { IO::Stream->new({})                                 } qr/usage:/;
throws_ok { IO::Stream->new({'cb'=>undef,fh=>1})                } qr/usage:/;
throws_ok { IO::Stream->new({'cb'=>sub{}})                      } qr/usage:/;
throws_ok { IO::Stream->new({'cb'=>sub{},fh=>undef})            } qr/usage:/;
throws_ok { IO::Stream->new({'cb'=>sub{},host=>undef})          } qr/usage:/;
throws_ok { IO::Stream->new({'cb'=>sub{},host=>1})              } qr/usage:/;
throws_ok { IO::Stream->new({'cb'=>sub{},host=>1,port=>undef})  } qr/usage:/;
throws_ok { IO::Stream->new({'cb'=>sub{},fh=>1,host=>1})        } qr/usage:/;

my ($io, $fh, $tmp);

socketpair $fh, $tmp, AF_UNIX, SOCK_STREAM, PF_UNSPEC or die "socketpair: $!";
lives_ok  { $io=IO::Stream->new({cb=>sub{},fh=>$fh}) };
throws_ok { IO::Stream->new({cb=>sub{},fh=>$fh})                } qr/same fh/;
throws_ok { IO::Stream->new({cb=>sub{},fh=>$fh})                } qr/same fh/;
close $fh;
throws_ok { IO::Stream->new({cb=>sub{},fh=>$fh})                } qr/descriptor/;
socketpair $fh, $tmp, AF_UNIX, SOCK_STREAM, PF_UNSPEC or die "socketpair: $!";
throws_ok { IO::Stream->new({cb=>sub{},fh=>$fh})                } qr/same fh/;
$io->close();   # will close current $fh because they've same fileno()!
throws_ok { IO::Stream->new({cb=>sub{},fh=>$fh})                } qr/descriptor/;
socketpair $fh, $tmp, AF_UNIX, SOCK_STREAM, PF_UNSPEC or die "socketpair: $!";
lives_ok  { IO::Stream->new({'cb'=>sub{},fh=>$fh})->close() };
throws_ok { IO::Stream->new({'cb'=>sub{},fh=>$fh})              } qr/descriptor/;

