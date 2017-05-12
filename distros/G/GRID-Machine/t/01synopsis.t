#!/usr/local/bin/perl -w
use strict;
use Test::More tests => 10;
BEGIN { use_ok('GRID::Machine', 'is_operative') };

my $test_exception_installed;
BEGIN {
  $test_exception_installed = 1;
  eval { require Test::Exception };
  $test_exception_installed = 0 if $@;
}

my $host = $ENV{GRID_REMOTE_MACHINE};

my $machine;
SKIP: {
    skip "Remote not operative or Test::Exception not installed", 9
  unless $test_exception_installed and $host and is_operative('ssh', $host);

########################################################################

  Test::Exception::lives_ok { 
    $machine = GRID::Machine->new(host => $host);
  } 'No fatals creating a GRID::Machine object';

########################################################################

  ok(
    $machine->sub( 
      rmap => q{
        my $f = shift; # function to apply
        die "Code reference expected\n" unless UNIVERSAL::isa($f, 'CODE');

        my @result;

        for (@_) {
          die "Array reference expected\n" unless UNIVERSAL::isa($_, 'ARRAY');
          push @result, [ map { $f->($_) } @$_ ];
        }
        return @result;
      }
    )->result, 
    "installed sub on remote machine"
  );

########################################################################

  my $cube = sub { $_[0]**3 };
  my $r = $machine->rmap($cube, [1..3], [4..6], [7..9]);
  ok($r->ok, "RPC didn't died");

########################################################################

  my $expected = [[ qw(1    8   27)], [ qw(64  125  216)], [ qw(343  512  729)]];
  is_deeply($expected, $r->results, "nested structures");

########################################################################

  $cube = "error";
  $r = $machine->rmap($cube, [1..3], [4..6], [7..9]);
  like("$r", qr{Error running sub rmap: Code reference expected}, "Remote died gracefully");

########################################################################

  $r = $machine->sub(
    read_all => q{
      my $filename = shift;
      my $FILE;
      local $/ ) undef; # line X1 <-- error!!!
      open $FILE, "< /tmp/foo.txt";
      $_ = <$FILE>;
      close $FILE;
      return $_;
    },
  );
  like("$r", 
       qr{Error while compiling}
       , "Syntax error correctly catched");

########################################################################

$r = $machine->eval( 'chuchu(0)');
like("$r", 
     qr{Undefined subroutine}
     , "Undefined subroutine error correctly catched");


########################################################################

  $machine->sub( iguales => q{
      my ($first, $sec) = @_;

      if ($first == $sec) {
        print "Iguales\n";
        return 1;
      }
      print "Distintos\n";
      return 0;
    },
  );

  my $w = [ 1..3 ];
  my $z = $w;
  $r = $machine->iguales($w, $z);
  like("$r", qr{Iguales}, "Equal local references look equal on the remote side");

########################################################################

  $machine->sub( remote_iguales => q{
      my $first = [1..3];
      my $sec = $first;

      return ($first, $sec);
    },
  );

  my ($f, $s) =$machine->remote_iguales->Results;
  ok($f == $s, "Equal remote references look equal on the local side");


} # end SKIP block

