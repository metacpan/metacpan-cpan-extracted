use strict;
use warnings;
use ExtUtils::MakeMaker;
use Config;

my $oe = $Config{obj_ext};
my @obj = map { $_ . $oe } qw(
 md6_compress md6_mode md6_nist
);

WriteMakefile(
  NAME         => 'Digest::MD6/src',
  AUTHOR       => 'Andy Armstrong <andy@hexten.net>',
  VERSION_FROM => '../MD6.pm',
  #  OPTIMIZE     => '-g',
  clean => { FILES => "*.o *.lo *$oe" },
  OBJECT => join( ' ', @obj ),
  PM     => {},
  XS     => {},
  linkext => { LINKTYPE => 'static' }
);

sub MY::static {
  return entab( <<'EOM');
static :: $(FIRST_MAKEFILE) $(OBJECT)
 $(NOECHO) $(NOOP)
EOM
}

sub entab {
  my $str = shift;
  $str =~ s{^\s+}{\t}msg;
  return $str;
}

