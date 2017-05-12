use strict;
use inc::Module::Install;

name "HTML-DTD";
license "perl";
all_from "lib/HTML/DTD.pm";

requires "File::ShareDir" => "1.02";
requires "Scalar::Util";
requires "Path::Class";

build_requires "Test::More";

install_share;

auto_install;
WriteAll;

__END__
