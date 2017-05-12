use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Meta::Widget::Gtk::Sprite',
    'VERSION_FROM'	=> 'Sprite.pm', # finds $VERSION
    'PREREQ_PM'		=> { Gtk => 0.7,
											 Gnome => 0.7}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'Sprite.pm', # retrieve abstract from module
       AUTHOR     => 'Jepri <jeremy.price@member.sage-au.org.au>') : ()),
);
