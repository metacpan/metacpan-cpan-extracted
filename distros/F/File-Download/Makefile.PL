use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'File::Download',
    'VERSION_FROM'	=> 'lib/File/Download.pm',
    'ABSTRACT'  => "A simple module for file downloading",
    'AUTHOR'    => 'Byrne Reese <byrne@majordojo.com>',
    'DISTNAME'  => 'File-Download',
#    'LICENSE'   => 'perl',
    'LIBS'	=> [''],   # e.g., '-lm' 
    'DEFINE'	=> '',     # e.g., '-DHAVE_SOMETHING' 
    'INC'	=> '',     # e.g., '-I/usr/include/other' 
#    'PM'	=> {'Spec.pm'	=> '$(INST_LIBDIR)/File/Spec.pm',
#    			'OS2.pm'	=> '$(INST_LIBDIR)/File/Spec/OS2.pm',
#    			'Win32.pm'	=> '$(INST_LIBDIR)/File/Spec/Win32.pm',
#    			'VMS.pm'	=> '$(INST_LIBDIR)/File/Spec/VMS.pm',
#   			'Unix.pm'	=> '$(INST_LIBDIR)/File/Spec/Unix.pm',
#    			}
);
__END__
use inc::Module::Install;

name('File-Download');
abstract('A simple file download module');
author('Byrne Reese <byrne@majordojo.com>');
version_from('lib/File/Download.pm');
license('perl');
no_index(directory => 't');
sign(0);

include('ExtUtils::AutoInstall');

requires('LWP::UserAgent');
requires('LWP::MediaTypes');
requires('URI');
requires('HTTP::Date');

features(
    'Downloader' => [
        -default => 1,
        'LWP' => 1,
        'LWP::UserAgent' => 1,
        'LWP::MediaTypes' => 1,
        'URI' => 1,
        'HTTP::Date' => 1,
    ],
);

auto_include();
auto_install();

&WriteAll;
__END__
