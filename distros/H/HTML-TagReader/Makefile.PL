# Makefile.PL -- Makefile template for HTML::TagReader.
use ExtUtils::MakeMaker;

BEGIN {
    require 5.003;
    eval { require Image::Size };
    $@  and  warn "In order to use tr_imgaddsize you should install the Image::Size module!\n";
        if(($Image::Size::VERSION || 0) < 2.0) {
          warn "You need at least version 2.0 of the Image::Size module.\n";
        }
}

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
my @programs_to_install = qw(tr_fixltgt tr_blck tr_xlnk tr_llnk tr_mvlnk tr_httpcheck tr_staticssi tr_tagcontentgrep tr_imgaddsize tr_delfont);

WriteMakefile(
    'NAME'	=> 'HTML::TagReader',
    'VERSION_FROM' => 'TagReader.pm', # finds $VERSION
    'PL_FILES'  => { map {("bin/$_.PL" => "bin/$_")} @programs_to_install },
    'EXE_FILES' => [ map {"bin/$_"} @programs_to_install ],
    'clean'     => { FILES => '$(EXE_FILES)' },
    'LIBS'	=> [''],   # e.g., '-lm' 
    'DEFINE'	=> '',     # e.g., '-DHAVE_SOMETHING' 
    'INC'	=> '',     # e.g., '-I/usr/include/other' 
    dist    => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
);
