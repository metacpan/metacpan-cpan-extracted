BEGIN { print "1..37\n";}
END { print "not ok 1\n" unless $loaded; }
use Exception::Class::TCF qw(&make &try &catch &throw &finally);
use Exception::Class::TCF::AssertFailure qw(&assert);
$loaded = 1;

package Exception::Class::TCF::Exc1;
@ISA = qw(Exception::Class::TCF);
package Exception::Class::TCF::Exc2;
@ISA = qw(Exception::Class::TCF);
package Exception::Class::TCF::Exc12;
@ISA = qw(Exception::Class::TCF::Exc1 Exception::Class::TCF::Exc2);
package Exception::Class::TCF::Exc1a;
@ISA = qw(Exception::Class::TCF::Exc1);

package main;

my $tests_done = 0; 

use Carp;

my $ok = 1;

sub passert (&) {
  my($code) = shift;
  sub {
    my($s,@args) = @_;
    unless (&$code)
    {
      if (@ARGV)
      {
        warn Carp::shortmess "Assertion failed";
        warn "The exception ",$s->type," was thrown with arguments @args.\n";
      }
      $ok = 0;
    }
  }
}

sub tassert (&) {
  my($code) = shift;
  sub {
    my($s,@args) = @_;
    unless (&$code)
    {
      if (@ARGV)
      {
        warn Carp::shortmess "Assertion failed";
        warn "The exception ",$s->type," was thrown with arguments @args\n";
      }
      $ok = 0;
    }
    else
    {
      $s->throw(@args);
    }
  }
}
sub rassert (&) {
  my($code) = shift;
  sub {
    my($s,@args) = @_;
    unless (&$code)
    {
      if (@ARGV)
      {
        warn Carp::shortmess "Assertion failed";
        warn "The exception ",$s->type," was thrown with arguments @args\n";
      }
      $ok = 0;
    }
    else
    {
      throw;
    }
  }
}

sub N {
  $tests_done++;
  unless ($ok)
  {
    print "not ";
  }
  print "ok $tests_done\n";
  $ok = 1;
}

N; # 1 ok/nok
# below is test 2
try
{ 
};

N; # 2 ok/nok
# below is test 3
try
{
  throw Error;
}
catch Default => passert { $_[0]->type eq 'Error' };

N; # 3 ok/nok
# below is test 4
eval
{
  try
  {
    throw Error;
  }
  catch Exc1 => passert { 0 };
};

unless ($@)
{
  $ok = 0;
}

N; # 4 ok/nok
# below is test 5
try
{
  throw Exc1;
}
catch Exc1 => passert { $_[0]->type eq 'Exc1' } ;

N; # 5 ok/nok
# below is test 6
sub test
{
  throw Exc1;
}

try
{
  test;
}
catch Default => passert { $_[0]->type eq 'Exc1' };

N; # 6
# below is test 7
eval
{
  try
  {
    test;
  }
  catch Exc2 => passert { 0 };
};

unless ($@)
{
#  die "Termination failed";
  $ok = 0;
}

N; # 7
# below is test 8
try
{
  make(Exc1,Message => "Exc1")->throw;
}
catch Exc1 => passert { $_[0]->type eq 'Exc1' && $_[0]->message eq 'Exc1' };

N; # 8
# below is test 9
try
{
  throw  new Exception::Class::TCF::Exc1 Message => "Exc1" ;
}
catch Exc1 => passert { $_[0]->type eq 'Exc1' && $_[0]->message eq 'Exc1' };

N; # 9
# below is test 10
try
{
  my $exc = make Exc1;
  $exc->setMessage("Exc1");
  throw $exc;
}
catch Exc1 => passert { $_[0]->type eq 'Exc1' && $_[0]->message eq 'Exc1' };

N; # 10
# below is test 11
try
{
  throw Exc1, "Exc1";
}
catch Exc1 => passert { $_[0]->type eq 'Exc1' && $_[1] eq 'Exc1' };

N; # 11
# below is test 12
try
{
  throw Exc1a;
}
catch  Exc1      => passert { $_[0]->type eq 'Exc1a' },
       Default => passert { 0 };

N; # 12
# below is test 13
try
{
  throw Exc12;
}
catch Exc1      => passert { $_[0]->type eq 'Exc12' },
      Exc2      => passert { 0 },
      Default => passert { 0 };

N; # 13
# below is test 14
try
{
  try
  {
    throw Error;
  }
  catch Default => tassert { $_[0]->type eq 'Error' };
}
catch Default => passert { $_[0]->type eq 'Error' };

N; # 14
# below is test 15
eval
{
  try
  {
    try
    {
      die "Talk to me\n";
    }
    catch Default => tassert { $_[0]->type eq 'Error' };
  }
  catch Default => passert { $_[0]->type eq 'Error' };
};

unless ($@ eq "Talk to me\n")
{
  $ok = 0;
}


N; # 15
# below is test 16
$ok =
try
{
  throw Exc12;
  0;
}
catch Exc1      => sub { $_[0]->type eq 'Exc12' },
      Exc2      => sub { 0 },
      Default => sub { 0 };

N; # 16
# below is test 17
$ok =
try
{
  1;
}
catch Exc2      => sub { 0 },
      Exc1      => sub { 0 },
      Default => sub { 0 };

N; # 17
# below is test 18
my $cnt = 0;

$SIG{'__DIE__'} = sub { $cnt++ };

$ok = 
try
{
  eval { die; };
  throw if &Exception::Class::TCF::isThrowing;
  1;
}
Default => sub { 0 };
$ok &&= $cnt == 1;

N; # 18
# below is test 19
$cnt = 0;

$ok = 
eval
{
  try
  {
    eval { die; };
    throw Error;
  }
  Default => sub { 1 };
} && $cnt == 1;

N; # 19
# below is test 20
$cnt = 0;

$ok = 
!eval
{
  try
  {
    eval { die; };
    throw Error;
  }
  catch Exc1 => sub { 0 };
} && $cnt == 2;

N; # 20
# below is test 21
$cnt = 0;

$ok = 
(
try
{
  eval { throw Exc1; };
  throw if &Exception::Class::TCF::isThrowing;
}
catch Default => sub { 1 }) && $cnt == 0;

N; # 21
# below is test 22
sub rt { throw };

$ok = 
try
{
  try
  {
    throw Exc1; 
  }
  catch Default => sub { rt }
}
catch Exc1 => sub { 1 };

N; # 22
# below is test 23
$ok = 1;

eval
{
  try
  {
    try
    {
      throw Exc1; 
    }
    catch Default => sub { die };
    $ok = 0;
  }
  catch Exc1 => sub { $ok = 0 };
  $ok = 0;
};
$ok = $ok && !!$@;

N; # 23
# below is test 24
my $tok;

package Exception::Class::TCF::Exc3;
@Exception::Class::TCF::Exc3::ISA = qw(Exception::Class::TCF);
sub DESTROY { $ok = $tok }

package main;

$ok = 0;

try
{
  try
  {
    throw  make Exc3 ;
    $tok = 0;
  }
  catch Default => sub {  $tok = 0; throw };
}
catch Exc3 => sub { $tok = 1; };

N; # 24
# below is test 25
$ok = 0;

try
{
  try
  {
    throw  make Exc3 ;
    $tok = 0;
  }
  catch Default => sub {  $tok = 1;  };
  $tok = 0;
}
catch Exc3 => sub { $tok = 0;  };

N; # 25
# below is test 26
$tok = 0;
$ok = 0;
{
  $tok = 1;
  eval
  {
    try
    {
      try
      {
        throw  make Exc3;
        $tok = 0;
      }
      catch Default => rassert { $_[0]->type eq 'Exc3' };
      $tok = 0;
    }
    catch Exc1 => passert { $tok = 0;  };
    $tok = 0;
  };
  $tok = 0;
}

N; # 26
# below is test 27
$ok =
try
{
  throw Error;
}
catch Default =>
   sub {
     try
     {
       throw Exc3;
     }
     catch Exc3 => sub { 1 }
   };

N; # 27
# below is test 28
$tok = 0;
$ok = 1;

try
{
  try
  {
    throw Exc3;
  }
  catch Default =>
    sub {
      try
      {
        throw Error;
      }
      catch Default => sub { $tok = 1; };
      throw;
    };
}
catch Default  => passert { $_[0]->type eq 'Exc3' };

$ok &&= $tok;

N; # 28
# below is test 29
$tok = 0;
$ok =
try
{
  try
  {
    throw Exc3;
  }
  catch Default =>
    sub {
      try
      {
        throw Error;
      }
      catch Default => rassert { $tok = 1; $_[0]->type eq 'Error' };
      throw;
    };
}
catch Exc3      => sub { 0 },
      Default => sub { 1 };

$ok &&= $tok;

N; # 29
# below is test 30
#try
#{
#  die "P";
#}
#catch Die => passert { $_[1]  eq "P at t/Exception.t line 493.\n"; };

N; # 30
# below is test 31
#eval
#{
#  try
#  {
#    die "P";
#  }
#  catch Default => passert { 0 };
#};
#
#$ok &&= $@ eq "P at t/Exception.t line 503.\n";

N; # 31
# below is test 32
&Exception::Class::TCF::handleDie(1);

eval
{
  try
  {
    die "P";
  }
  catch Default => passert { 1 };
};

$ok &&= !$@;

N; # 32
# below is test 33
try
{
  assert { 0 } Message => "12345";  
}
catch Error => 
  passert { $_[0]->type eq 'AssertFailure' && $_[0]->message eq "12345" };

N; # 33
# below is test 34
try
{
  assert { 0 } "12345";  
}
catch Error => 
  passert { $_[0]->type eq 'AssertFailure' && $_[0]->message eq "12345" };

N; # 34
# below is test 35
$ok  = 0;

try
{
}
catch 'Default' => sub { $ok = 0; }, 'Finally' => sub { $ok = 1};

N; # 35
# below is test 36
$ok  = 0;

try
{
  throw 'Error';
}
catch 'Default' => sub { $ok = 0; }, 
finally { $ok = 1};

N; # 36
# below is test 37
$ok = 0;

try
{
}
finally { $ok = 1};

N; # 37
