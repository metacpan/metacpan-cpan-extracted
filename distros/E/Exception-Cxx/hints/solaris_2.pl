# Different C++ compilers on the same architecture are (most likely)
# not binary compatible.  This poses difficulties in writing hints for
# MakeMaker.  Suggestions welcome.

$self->{CC}="CC -vdelx -pta";
$self->{LD}="CC -ztext";
$self->{CCCDLFLAGS}="-KPIC";
$self->{clean} = {FILES => 'Templates.DB'};
$self->{LIBS} = ["-lC"];
