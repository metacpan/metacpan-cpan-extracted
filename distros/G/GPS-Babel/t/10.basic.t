use strict;
use warnings;
use GPS::Babel;
use Test::More tests => 12;

my $DUMMY_EXE = 'not-the-real-gpsbabel';
our $exe_name = $DUMMY_EXE;

# Fake system
{

  package GSP::Babel;

  use subs qw(which);
  no warnings qw(redefine once);

  package main;

  *GPS::Babel::which = sub {
    my $name = shift;
    return $exe_name;
  };
}

{

  # No exe specified
  local $exe_name = undef;
  {
    ok my $babel = GPS::Babel->new(), 'new OK';
    isa_ok $babel, 'GPS::Babel';
    ok !$babel->get_exename, 'no exe found OK';
    eval { $babel->check_exe };
    like $@, qr/not\s+found/, 'check_exe errors correctly';
  }

  # Dummy exe specified
  {
    ok my $babel = GPS::Babel->new( { exename => $DUMMY_EXE } ),
     'new OK';
    isa_ok $babel, 'GPS::Babel';
    my @exe = $babel->get_exename;
    is_deeply \@exe, [$DUMMY_EXE], 'exe as arg OK';
    eval { $babel->check_exe };
    ok !$@, 'check_exe ok correctly';
  }
}

{
  ok my $babel = GPS::Babel->new(), 'new OK';
  isa_ok $babel, 'GPS::Babel';
  my @exe = $babel->get_exename;
  is_deeply \@exe, [$DUMMY_EXE], 'exe as arg OK';
  eval { $babel->check_exe };
  ok !$@, 'check_exe ok correctly';
}

