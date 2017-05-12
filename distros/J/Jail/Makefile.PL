# -*- mode: perl -*-
use ExtUtils::MakeMaker;

$uname = `uname -a`;
if ($uname !~ /^IRIX/) {
    print "Sorry, this Perl extension is for SGI IRIX systems only.\n";
    exit;
}

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'Jail',
    'VERSION_FROM' => 'Jail.pm', # finds $VERSION
    'LIBS'	=> ['-lvl -lil -lX11'],   # e.g., '-lm' 
    'DEFINE'	=> '',     # e.g., '-DHAVE_SOMETHING' 
    'INC'	=> '',     # e.g., '-I/usr/include/other' 
    'CC'        => 'CC',
    'CCFLAGS'   => '-n32 -nostdlib',
    'OPTIMIZE'  => '',
    'LD'        => 'CC',
    'OBJECT'    => 'Jail.o imgArray.o imgProcess.o smpVideo.o imgDisplay.o imgGlyph.o Font.o Glyph.o',
);

sub MY::test {
    my $self = shift;
    local *test;
    my $old=$self->MM::test;

    # dont know what PERL_DL_NONLAZY does, but without setting to 0
    # the rld requests some misterious methods to declare in the il lib
    $old =~ s/PERL_DL_NONLAZY=1/PERL_DL_NONLAZY=0/g;
    return $old;
}

sub MY::c_o {
    my $self = shift;
    local *c_o;
    my $old=$self->MM::c_o;

    return "$old\n\nCXXFLAGS = -n32 -nostdlib";
}
