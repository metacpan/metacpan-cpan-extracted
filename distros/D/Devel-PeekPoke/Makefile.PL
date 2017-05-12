use warnings;
use strict;

use 5.006;

use inc::Module::Install '1.06';

my $use_pp = $ENV{DEVEL_PEEK_POKE_USE_PP} || ! can_cc();

$use_pp = 1; # FIXME - if someone writes the XS, this will no longer be true

if ($use_pp and ($] =~ /^5.(\d{3})/)[0] % 2) {
  die "Installation will need Devel::PeekPoke::PP, which does not work (by design) on development perls ($])\n";
}

# the XS version (when written) should work fine on 5.6
perl_version $use_pp ? '5.008001' : '5.006';

test_requires 'Test::More'      => '0.88';  # done testing
test_requires 'Test::Exception' => '0.31';  # non-segfaulting caller()

all_from 'lib/Devel/PeekPoke.pm';

homepage 'http://git.shadowcat.co.uk/gitweb/gitweb.cgi?p=p5sagit/Devel-PeekPoke.git';
resources 'IRC'         => 'irc://irc.perl.org/#pp';
resources 'license'     => 'http://dev.perl.org/licenses/';
resources 'repository'  => 'git://git.shadowcat.co.uk/p5sagit/Devel-PeekPoke.git';
resources 'bugtracker'  => 'http://rt.cpan.org/NoAuth/Bugs.html?Dist=Devel-PeekPoke';

WriteAll;
