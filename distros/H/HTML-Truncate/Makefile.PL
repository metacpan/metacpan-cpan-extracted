use strict;
use inc::Module::Install;

name "HTML-Truncate";
license 'perl';
all_from "lib/HTML/Truncate.pm";

perl_version_from 'lib/HTML/Truncate.pm';

# requires "perl" => 5.006;
requires "HTML::Tagset" => 3;
requires "HTML::TokeParser" => 2;
requires "List::Util" => 1;
    
build_requires "Encode" => 2;
build_requires "Test::More" => 0.5;
build_requires "File::Spec" => 3;

system('pod2text lib/HTML/Truncate.pm > README');

auto_install;
WriteAll;

__END__
