package builder::MyBuilder;
use strict;
use warnings;
use utf8;
use 5.010_001;
use parent qw(Module::Build);
use Devel::CheckCompiler 0.04;

sub new {
    my $self = shift;
    if ($^O ne 'linux' and $^O ne 'freebsd') {
        print "This module only supports linux or FreeBSD.\n";
        exit 0;
    }
    if (check_compile(<<'...', executable => 1) != 1) {
#ifndef _GNU_SOURCE
#define _GNU_SOURCE
#endif
#include <sys/socket.h>

int main(void)
{
    return accept4(0, (void*)0, (void*)0, 0);
}
...
        print "This module only supports linux 2.6.28+ and glibc 2.10+ or FreeBSD 10.0+.\n";
        exit 0;
    }
    $self->SUPER::new(@_);
}


1;

