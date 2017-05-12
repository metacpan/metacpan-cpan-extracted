use strict;

use Test::More;
use HTTP::Exception;

my @tests = (100,200,300,400,500);

for my $status_code (@tests) {
    my $e = HTTP::Exception->new($status_code);

    # no real testing, i think Exception::Class has enough tests
    # so just checking, whether there is something or not
    ok defined $e->message()     , '$e->message()      is "'.$e->message()     .qq~" ($status_code)~;
    ok defined $e->error()       , '$e->error()        is "'.$e->error()       .qq~" ($status_code)~;
    ok defined $e->pid()         , '$e->pid()          is "'.$e->pid()         .qq~" ($status_code)~;
    ok defined $e->uid()         , '$e->uid()          is "'.$e->uid()         .qq~" ($status_code)~;
    ok defined $e->gid()         , '$e->gid()          is "'.$e->gid()         .qq~" ($status_code)~;
    ok defined $e->euid()        , '$e->euid()         is "'.$e->euid()        .qq~" ($status_code)~;
    ok defined $e->egid()        , '$e->egid()         is "'.$e->egid()        .qq~" ($status_code)~;
    ok defined $e->time()        , '$e->time()         is "'.$e->time()        .qq~" ($status_code)~;
    ok defined $e->package()     , '$e->package()      is "'.$e->package()     .qq~" ($status_code)~;
    ok defined $e->file()        , '$e->file()         is "'.$e->file()        .qq~" ($status_code)~;
    ok defined $e->line()        , '$e->line()         is "'.$e->line()        .qq~" ($status_code)~;
    ok defined $e->trace()       , '$e->trace()        is "'.$e->trace()       .qq~" ($status_code)~;
    ok defined $e->as_string()   , '$e->as_string()    is "'.$e->as_string()   .qq~" ($status_code)~;
    ok defined $e->full_message(), '$e->full_message() is "'.$e->full_message().qq~" ($status_code)~;
}

done_testing;