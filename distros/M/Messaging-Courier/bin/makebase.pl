use warnings;
use strict;
use lib qw(lib);
use Messaging::Courier::Config;
use File::HomeDir;
use File::Spec;

sub file {
  my $name = shift;
  mkdir( File::Spec->catdir( home(), '.courier' ) );
  return File::Spec->catfile(home(), '.courier', $name);
}

sub set {
  my $name = shift;
  my $value = shift;
  open FILE, ">".file($name) or die "can't open ".file($name);
  print FILE $value."\n";
  close FILE;
}

#my $username = getlogin || getpwid($>);

#set('group', "courier_".$username);



