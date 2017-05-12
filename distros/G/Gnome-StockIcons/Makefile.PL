use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Gnome::StockIcons',
    'VERSION_FROM'	=> 'StockIcons.pm', # finds $VERSION
    'PREREQ_PM'		=> {'Gtk'	=> '0'}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'StockIcons.pm', # retrieve abstract from module
       AUTHOR     => 'Wim Vanderbauwhede <wim@motherearth.org>') : ()),
);
