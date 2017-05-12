use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => 'Git::Hooks::RubyNoDebugger',
    VERSION_FROM => 'lib/Git/Hooks/RubyNoDebugger.pm',
    ABSTRACT_FROM => 'lib/Git/Hooks/RubyNoDebugger.pm',
    AUTHOR       => 'Skye Shaw <skye.shaw [AT] gmail.com>',
    PREREQ_PM    => { 'Git::Hooks' => 0 },
    LICENSE      => 'perl',
    test         => {TESTS => 't/*.t'},
    (eval { ExtUtils::MakeMaker->VERSION(6.46) } ?
     (META_MERGE  => { resources => { bugtracker => 'http://github.com/sshaw/Git-Hooks-RubyNoDebugger/issues',
				      repository => 'http://github.com/sshaw/Git-Hooks-RubyNoDebugger',
				      homepage   => 'http://github.com/sshaw/Git-Hooks-RubyNoDebugger'} }) : ())
    );

# Create README.pod for a repo's GitHub page. Unlike CPAN, GitHub won't
# display the module's POD, it looks for a README.*
sub MY::postamble
{
    my $self = shift;
    return if -r 'README' or ! -r $self->{VERSION_FROM};
    return<<END_MAKE;
README.pod: $self->{VERSION_FROM}
	\@perldoc -uT $self->{VERSION_FROM} > README.pod
END_MAKE
}

# Include test helpers and/or libs
sub MY::test
{
  package MY;
  my $make = shift->SUPER::test(@_);
  $make .= 'FULLPERLRUN = $(FULLPERL) -I t -I t/lib';
  return $make;
}
