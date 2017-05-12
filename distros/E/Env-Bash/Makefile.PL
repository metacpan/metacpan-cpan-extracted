use 5.008;
use ExtUtils::MakeMaker;

unless( _have_bash() ) {
    print <<"*EOF*";
====================================================
You seem to be running on the '$^O' platform, and
I am unable to find a bash executable. While this
module will work, it becomes a rather worthless
wrapper for the built-in \$ENV{..} hash. I advise
you not to use it without bash.  Aloha => Beau.
====================================================
*EOF*
    sleep 5;
}

WriteMakefile(
    NAME              => 'Env::Bash',
    VERSION_FROM      => 'lib/Env/Bash.pm', # finds $VERSION
    PREREQ_PM         =>
              {
                  Test::More  => 0.47,
                },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Env/Bash.pm', # retrieve abstract from module
       AUTHOR         => 'Beau E. Cox <beaucox@hawaii.rr.com>') : ()),
);


sub _have_bash
{
    my $bash;
    $HAVEBASH = 1;
    $bash = $ENV{SHELL};
    return $bash if $bash && -f $bash && -x _;
    return 'bash' if system( 'bash', '-c', '' ) == 0;
    $bash = $ENV{BASH};
    return $bash if $bash && -f $bash && -x _;
    warn "No bash executable found, running as \$ENV{...}\n" if $HAVEBASH;
    $HAVEBASH = 0;
    '';
}
