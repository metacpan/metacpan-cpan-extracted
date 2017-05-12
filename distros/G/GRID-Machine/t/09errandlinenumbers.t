#!/usr/local/bin/perl -w
use strict;
use Test::More tests => 7;
sub findVersion {
  my $pv = `perl -v`;
  my ($v) = $pv =~ /v(\d+\.\d+)\.\d+/;

  $v ? $v : 0;
}
BEGIN { use_ok('GRID::Machine', qw(is_operative qc)) };

my $test_exception_installed;
BEGIN {
  $test_exception_installed = 1;
  eval { require Test::Exception };
  $test_exception_installed = 0 if $@;
}


my $host = $ENV{GRID_REMOTE_MACHINE} || '';

SKIP: {
    skip "Remote not operative or Test::Exception not installed", 6
  unless $host and  $test_exception_installed and is_operative('ssh', $host);

########################################################################

  my $machine;
  Test::Exception::lives_ok { 
    $machine = GRID::Machine->new(host => $host);
  } 'No fatals creating a GRID::Machine object';

########################################################################


  my $p = { name => 'Peter', familyname => [ 'Smith', 'Garcia'] };

  my $r = $machine->eval( (q{ 
      $q = shift; $q->{familyname} 
    }), $p
  );

  my $expected = qr{
      Error\s+while\s+compiling\s+eval\s+'.q\s+=\s+shift;\s+.q->.fam...'\s+
      Global\s+symbol\s+".q"\s+requires\s+explicit\s+package\s+name\s+at\s+t/09errandlinenumbers.t\s+line\s+39
  }xs;

  my $err = $r->errmsg;

  like($err, $expected, q{Error line is pointed in eval accurately});

  is($r->stdout, '', q{nothing in stdout});

  is($r->errcode, 0, q{errcode is 0});

  is($r->stderr, '', q{stderr is ''});

  is($r->type, 'DIED', q{type is 'DIED'});

} # end SKIP block

