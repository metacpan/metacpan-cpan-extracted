use inc::Module::Install;

name "HTML-Highlighter";
author 'Lee Aylward <leedo@cpan.org>';
all_from "lib/HTML/Highlighter.pm";

requires "Plack" => 0;
requires "Plack::Request" => 0;
requires "HTML::Parser" => 0;
requires "List::Util" => 0;

test_requires "Test::More" => 0;
test_requires "Plack::App::File" => 0;
test_requires "Plack::Test" => 0;
test_requires "HTTP::Request" => 0;

install_share;
WriteAll;
