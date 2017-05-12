use strict;
use FileHandle::Unget;
use Data::Dumper;
use Test::More tests => 1;

my $fh  = new FileHandle::Unget($0);

# 1
is(Dumper($fh),"\$VAR1 = bless( \\*Symbol::GEN0, 'FileHandle::Unget' );\n",
  'Dumped Filehandle::Unget');

$fh->close;
