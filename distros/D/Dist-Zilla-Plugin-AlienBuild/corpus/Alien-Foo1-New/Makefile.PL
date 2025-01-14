use ExtUtils::MakeMaker;

my %args = (
  NAME => "My::Module",
##{ $plugin->get_default(qw(ABSTRACT AUTHOR LICENSE VERSION)) ##}
##{ $plugin->get_prereqs(1) ##}
);

# ALIEN BUILD MM

WriteMakefile(%args);

