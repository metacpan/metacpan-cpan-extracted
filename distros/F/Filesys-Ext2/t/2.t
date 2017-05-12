use File::Spec;
use Filesys::Ext2 q(:all);

print "1..8\n";

$PATH = q(/usr/bin);
while( 1 ){
  unless( -x File::Spec->catfile($PATH, 'chattr') &&
	  -x File::Spec->catfile($PATH, 'lsattr') ){
    print STDERR qq(

Could not find executable copy of chattr and lsattr in:
  $PATH

To continue enter PATH to lsattr/chattr, <Enter> to skip
PATH: );
    chomp($PATH = <STDIN>);
    if( $PATH =~ /^\s*$/ ){
      print "ok $_ # Skipped: No PATH for e2fsprogs\n" for 1 .. 8;
      exit 0;
    }
  }
  else{
    print STDERR q(
**************************************************************************
When using Filesys::Ext2 you will need to do
  use Filesys::Ext2 {PATH=>'$PATH'};
Or, you may change the default path in Ext2.pm.
) unless $PATH eq '/usr/bin';
    last;
  }
}

#Nasty Hack to get around run-time import not overriding builtins
eval "use Filesys::Ext2 q(:all), {PATH=>q($PATH)}";
print "# re-use Filesys::Ext2, $@: don't be surprised if tests fail\n" if $@;

my @attr;
chattr(0, $0); #XXX or die?

{
  ($attr[0] = lsattr($0)) || print "not ";
  printf "ok 1 # %s\n", scalar calcSymMask($attr[0]);
}
{
  chattr('+d-A', $0) && print "not ";
  print "ok 2 # chattr +d -A\n";
}
{
  ($attr[1] = lsattr($0)) || print "not ";
  printf "ok 3 # %s\n", scalar calcSymMask($attr[1]);
}
{
  print "not " unless (($attr[1] & 0x40) == 0x40) && (($attr[1] & 0x80) == 0);
  print "ok 4 # Are the previous lsattr and chattr in agreement?\n";
}
{
  chattr('-d+A', $0) && print "not ";
  print "ok 5 # chattr -d +A\n";
}
{
  my @F = lstat($0);
  ($attr[2] = $F[$#F]) || print "not ";
  printf "ok 6 # %s\n", scalar calcSymMask($attr[2]);
  print "not " unless scalar @F == 14;
  print "ok 7 # Override builtin\n";
}
{
  print "not " unless (($attr[2] & 0x40) == 0) && (($attr[2] & 0x80) == 0x80);
  print "ok 8 # Are the previous lsattr and chattr in agreement?\n";
}
