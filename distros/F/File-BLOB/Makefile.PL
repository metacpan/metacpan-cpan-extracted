use inc::Module::Install::DSL 1.04;

all_from      lib/File/BLOB.pm
requires_from lib/File/BLOB.pm
requires      bytes      0
requires      IO::File   0
requires      File::Type 0.22
test_requires File::Spec 0.80
test_requires Test::More 0.47
