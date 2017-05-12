use 5.004;
use ExtUtils::MakeMaker;

die <<__mswin32 if $^O =~ /^MSWin32$/i;
Windows does not offer a native fnmatch implementation, and this
version of File::FnMatch does not supply one.
__mswin32

#
# $Id: Makefile.PL,v 1.2 2005/03/30 05:34:57 mjp Exp $
#
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'File::FnMatch',
    'VERSION_FROM'	=> 'FnMatch.pm', # finds $VERSION
    'PREREQ_PM'		=> {}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (AUTHOR     => 'Michael J. Pomraning <mjp-perl@pilcrow.madison.wi.us>') : ()),
    'LIBS'		=> [''], # e.g., '-lm'
    'DEFINE'		=> '', # e.g., '-DHAVE_SOMETHING'
    'INC'		=> '-I.', # e.g., '-I. -I/usr/include/other'
	# Un-comment this if you add C files to link with later:
    # 'OBJECT'		=> '$(O_FILES)', # link all the C files too
);
