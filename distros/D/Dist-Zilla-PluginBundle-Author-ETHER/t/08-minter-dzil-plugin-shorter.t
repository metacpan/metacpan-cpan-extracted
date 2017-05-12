use strict;
use warnings;

# this is just like t/07-minter-dzil-plugin.t except we are minting
# Dist-Zilla-Plugin-Foo, rather than Dist-Zilla-Plugin-Foo-Bar.

use Path::Tiny;
my $code = path('t', '07-minter-dzil-plugin.t')->slurp_utf8;

$code =~ s/Dist-Zilla-Plugin-Foo\K-Bar//g;
$code =~ s/Dist::Zilla::Plugin::Foo\K::Bar//g;
$code =~ s{lib/Dist/Zilla/Plugin/Foo\K/Bar\.pm}{.pm};
$code =~ s/\\\[Foo\K::Bar\\\]/\\\]/g;
$code =~ s/\[Foo\K::Bar\]/\]/g;
$code =~ s/'Foo\K::Bar'/'/g;

eval $code;
die $@ if $@;
