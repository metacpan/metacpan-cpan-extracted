use inc::Module::Install::DSL 0.99;

all_from      lib/JSAN/Client.pm
requires_from lib/JSAN/Client.pm
requires      Algorithm::Dependency 1.106
requires      Archive::Tar          1.30
requires      Archive::Zip          1.18
requires      YAML                  0.60
test_requires Test::More            0.47
test_requires File::Remove          1.40
