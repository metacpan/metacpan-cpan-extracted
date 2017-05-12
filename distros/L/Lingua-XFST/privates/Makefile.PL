use strict;
use warnings;

use ExtUtils::MakeMaker;
use ExtUtils::Liblist;

my $ld_path = 'LD_LIBRARY_PATH';
$ld_path = 'DY' . $ld_path if $^O eq 'darwin'; # $^O is OS type
$ld_path = $ENV{$ld_path};
$ld_path = '' if not defined $ld_path;

my $extra_paths = join q{ }, map { "-L$_" } $ld_path;
my $LIBS = (ExtUtils::Liblist->ext("$extra_paths -lxfsm", 0, 0))[2];

WriteMakefile(
    NAME => 'Lingua::XFST::Privates',
    INST_LIB => '../blib/lib',
    INST_ARCHLIB => '../blib/arch',
    LIBS => $LIBS,
    OBJECT => 'xfsm_wrap.o',
);
