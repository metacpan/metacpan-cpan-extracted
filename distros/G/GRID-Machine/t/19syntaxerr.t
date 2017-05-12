#!/usr/bin/perl
use strict;
use warnings;

my $numtests;
BEGIN {
    $numtests = 12;
}
use Test::More tests => $numtests;
BEGIN { use_ok('GRID::Machine', 'is_operative') };

my $test_exception_installed;
BEGIN {
 $test_exception_installed = 1;
 eval { require Test::Exception };
 $test_exception_installed = 0 if $@;
}

sub e2r {
  local $_ = shift;

  s/\s+//g;
  $_ = quotemeta;
  $_ = qr{$_};
}

my $debug = @ARGV ? 1234 : 0;

my $host = $ENV{GRID_REMOTE_MACHINE} || '';
SKIP: {
  skip "Remote not operative or Test::Exception not installed", $numtests-1 unless 
                           $test_exception_installed and  $host && is_operative('ssh', $host);

   my $machine;
   Test::Exception::lives_ok {
     $machine = GRID::Machine->new(
        host => $host,
        #prefix => "/tmp/perl5lib$$",                                                          
        startdir => '/tmp',                                                                               
        log => '/tmp/rperl$$.log',                                                                                           
        err => '/tmp/rperl$$.err',                                                                                
        debug => $debug,
        cleanup => 1,                                                                                 
        sendstdout => 1
      );
   } 'No fatals creating a GRID::Machine object';


  my $p = { name => 'Peter', familyname => [ 'Smith', 'Garcia'] };

  {  # test error messages: line number for EVAL
      my $r = $machine->eval( q{ $q = shift; $q->{familyname} }, $p);

      my $expected = qr{
          Error\s+while\s+compiling\s+eval\s+'.q\s+=\s+shift;\s+.q->.fam...'\s+
          Global\s+symbol\s+".q"\s+requires\s+explicit\s+package\s+name\s+at\s+t/19syntaxerr.t\s+line\s+52,
      }xs;

      my $err = $r->errmsg;

      like($err, $expected, q{Error line is pointed in eval accurately});

      is($r->stdout, '', q{nothing in stdout});

      is($r->errcode, 0, q{errcode is 0});

      is($r->stderr, '', q{stderr is ''});

      is($r->type, 'DIED', q{type is 'DIED'});
  }

  {  # test error messages: line number for SUB
      my $r = $machine->sub(chuchu => q{ $q = shift; $q->{familyname} }); # do not move this line. Must be line 72!!!!!
      my $expected = qr{
Error\s+while\s+compiling\s+'chuchu'.\s+Global\s+symbol\s+".q"\s+requires\s+explicit\s+package\s+name\s+at\s+t/19syntaxerr.t\s+line\s+73,\s+<STDIN>\s+line\s+\d+.\s+
Global\s+symbol\s+".q"\s+requires\s+explicit\s+package\s+name\s+at\s+t/19syntaxerr.t\s+line\s+73,\s+<STDIN>\s+line\s+\d+
      }xs;

      my $err = $r->errmsg;

      like($err, $expected, q{Error line is pointed in sub accurately});

      is($r->stdout, '', q{nothing in stdout});

      is($r->errcode, 0, q{errcode is 0});

      is($r->stderr, '', q{stderr is ''});

      is($r->type, 'DIED', q{type is 'DIED'});
  }
} # END SKIP


