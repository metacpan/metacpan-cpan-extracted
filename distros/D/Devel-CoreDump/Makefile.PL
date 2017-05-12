use strict;
use warnings;
use inc::Module::Install;

name 'Devel-CoreDump';
all_from 'lib/Devel/CoreDump.pm';

extra_tests;

my @OBJECT = map { "${_}.o" } qw(
    CoreDump
    src/coredumper
    src/thread_lister
    src/elfcore
    src/linuxthreads
);

makemaker_args(
    INC    => '-Isrc',
    clean  => { FILES => join(q{ }, @OBJECT) },
    OBJECT => join(q{ }, @OBJECT),
);

WriteAll;

package MY;

sub const_cccmd {
    my $self = shift;
    my $orig = $self->SUPER::const_cccmd(@_);

    return '' unless $orig;

    $orig .= ' -o $@';
    return $orig;
}

1;
