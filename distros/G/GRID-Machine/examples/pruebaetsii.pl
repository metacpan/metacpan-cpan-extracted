#!/usr/local/bin/perl -w
use strict;
use IPC::PerlSSH;

my $ips = IPC::PerlSSH->new( Host => 'casiano@etsii.ull.es' );

$ips->eval( "use POSIX qw( uname )" );
my @remote_uname = $ips->eval( "uname()" );
print "@remote_uname\n";

# We can pass arguments
$ips->eval( "open FILE, '> /tmp/foo.txt'; print FILE shift; close FILE;",
           "Hello, world!" );

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

my @files = $ips->eval('glob("/tmp/*.txt")');
foreach my $file ( @files ) {
  print "$file:\n**************\n";
  my $content = $ips->call( "slurp_file", $file );
  print "$content\n";
}
