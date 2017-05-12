#!/usr/local/bin/perl -w
use strict;
use GRID::Machine;

BEGIN {
  #unshift @INC, '/home/pp2/src/perl/IPC-Rperl/lib';
  print "@INC\n";
}

my $ips = GRID::Machine->new( Command => 'ssh casiano@orion.pcg.ull.es perl' );

$ips->eval( "use POSIX qw( uname )" );
my @remote_uname = $ips->eval( "uname()" );
print "@remote_uname\n";

# We can pass arguments
$ips->eval( "open FILE, '> /tmp/foo.txt'; print FILE shift; close FILE;",
           "Hello, world!" );

$ips->eval('use vars qw($c $f %d)');
$ips->eval('$a = [4..9]; $c = {a=>1, b=>2}; %d = (d=>9, e=>11)');

$b = $ips->eval('Dumper($a);');
print $b;

print $ips->dump('$a', '$c', '\%d');

# We can pre-compile stored procedures
$ips->store( "slurp_file", <<'EOS'
  my $filename = shift;
  my $FILE;
  local $/ = undef; 
  open $FILE, "< /tmp/foo.txt";
  $_ = <$FILE>;
  close $FILE;
  return $_;
EOS
);

# We can pre-compile stored procedures
$ips->install( "Mipaquete::triple", <<'EOS'
  return 3*$_[0];
EOS
);

#$ips->eval('$f = \&slurp_file');
#print $ips->dump('$f');

my $f = $ips->eval('Mipaquete::triple(4)');
print "triple de 4: $f\n";

my @files = $ips->eval('glob("/tmp/*.txt")');
foreach my $file ( @files ) {
  my $content = $ips->call( "slurp_file", $file );
  print "$file:\n********************\n$content\n";
}
