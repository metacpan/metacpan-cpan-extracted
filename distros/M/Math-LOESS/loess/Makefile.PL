use ExtUtils::MakeMaker;
use ExtUtils::F77;

my @C      = ( glob("*.c"), glob("*.f") );
my $object = join(" ", map { s/\.(c|f)$/\$(OBJ_EXT)/; $_ } @C);

my $ccflags = '-I. -I./loess -D_LARGEFILE64_SOURCE';
my $libs    = [ join(' ', '-lm', ExtUtils::F77->runtime) ];

WriteMakefile(
    NAME    => 'Math::LOESS::_swig',
    OBJECT  => $object,
    INC     => '-I.',
    CCFLAGS => $ccflags,
    LIBS    => $libs,
);

package MY;
use ExtUtils::F77;

# Don't make .bs files
sub dynamic {
    my $self = shift;
    my $res  = $self->SUPER::dynamic(@_);
    $res =~ s/\s*\$\(INST_BOOT\)//;
    $res;
}

sub postamble {
    my $compiler = ExtUtils::F77->compiler();
    my $cflags   = '-O -fPIC';

    my $str = "";
    $str .= ".f.o :\n";
    $str .= "\t$compiler $cflags -c \$<";
    $str;
}

