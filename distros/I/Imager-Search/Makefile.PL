use inc::Module::Install::DSL 1.01;

all_from      lib/Imager/Search.pm
requires      IO::File            1.14
requires      Params::Util        1.00
requires      Object::Tiny::XS    1.01
requires      File::Slurp         9999.12
requires      Imager              0.65
requires      Imager::Screenshot  0.007
test_requires Test::More          0.47
test_requires Test::File::Cleaner 0.03
test_requires File::Remove        1.42
