#!/usr/bin/env perl
use v5.36;
use strict;
use warnings;

my @modules = qw(
  Linux::Event
  Linux::Event::Backend::Epoll
  Linux::Event::Clock
  Linux::Event::Timer
  Linux::FD
  Linux::FD::Timer
  JSON::PP
  Time::HiRes
);

my @optional_modules = qw(
  Linux::FD::Event
  Linux::FD::Signal
  Linux::FD::Pid
);

my $ok = 1;
for my $module (@modules) {
  my $file = "$module.pm";
  $file =~ s{::}{/}g;
  my $err = do {
    local $@;
    eval { require $file; 1 } ? undef : $@ || 'unknown error';
  };
  if ($err) {
    chomp $err;
    print "not ok - $module: $err\n";
    $ok = 0;
  }
  else {
    no strict 'refs';
    my $version = ${"${module}::VERSION"} // 'unknown';
    print "ok - $module $version\n";
  }
}

for my $module (@optional_modules) {
  my $file = "$module.pm";
  $file =~ s{::}{/}g;
  my $err = do {
    local $@;
    eval { require $file; 1 } ? undef : $@ || 'unknown error';
  };
  if ($err) {
    chomp $err;
    print "optional missing - $module: $err
";
  }
  else {
    no strict 'refs';
    my $version = ${"${module}::VERSION"} // 'unknown';
    print "optional ok - $module $version
";
  }
}

exit($ok ? 0 : 1);
