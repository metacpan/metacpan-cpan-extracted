
=pod

L<Module::Install> file for L<Digest::Whirlpool>. MI knows how to
build our XS stuff automatically.

=cut

use strict;
use inc::Module::Install;

name 'Digest-Whirlpool';

# Primary maintainer
author 'Ævar Arnfjörð Bjarmason <avar@cpan.org>';

# some parts are under 'perl', see LICENSE
license_from 'Whirlpool.pm';
version_from 'Whirlpool.pm';

install_script 'script/whirlpoolsum';

# script/
requires 'Digest'       => 0; # 5.007003
requires 'Pod::Usage'   => 0; # 5.006
requires 'Getopt::Long' => 0; # 5

# lib/
requires 'Digest::base' => 0; # 5.008003
requires 'MIME::Base64' => 0; # 5.007003

# t/
build_requires 'Test::More' => 0; # 5.007003

WriteAll;


