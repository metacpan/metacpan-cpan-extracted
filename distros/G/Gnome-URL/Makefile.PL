use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

my $INC  = `gnome-config --cflags gnome`;
my $LIBS = `gnome-config --libs gnome`;

WriteMakefile(
    'NAME'		=> 'Gnome::URL',
    'VERSION_FROM'	=> 'URL.pm',
    'PREREQ_PM'		=> {},
    ($] >= 5.005 ?
      (ABSTRACT_FROM => 'URL.pm',
       AUTHOR     => 'Mark A. Stratman <mark@sporkstorms.org>') : ()),
    'LIBS'		=> [ $LIBS ],
    'DEFINE'		=> '',
    'INC'		=> $INC,
	# Un-comment this if you add C files to link with later:
    # 'OBJECT'		=> '$(O_FILES)', # link all the C files too
);

