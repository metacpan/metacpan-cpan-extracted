#!env perl

use strict;
use diagnostics;
use IO::Handle;
use Log::Log4perl qw/:easy/;
use Log::Any::Adapter;
use Log::Any qw/$log/;
use MarpaX::ESLIF::URI;
use Data::Scan::Printer;
use Devel::Peek;
use File::Slurp qw/read_file/;

autoflush STDOUT 1;
autoflush STDERR 1;

#
# Init log
#
our $defaultLog4perlConf = '
        log4perl.rootLogger              = TRACE, Screen
        log4perl.appender.Screen         = Log::Log4perl::Appender::Screen
        log4perl.appender.Screen.stderr  = 0
        log4perl.appender.Screen.layout  = PatternLayout
        log4perl.appender.Screen.layout.ConversionPattern = %d %-5p %6P %m{chomp}%n
        ';
Log::Log4perl::init(\$defaultLog4perlConf);
Log::Any::Adapter->set('Log4perl');

my $format  = '%-21s : %s';

while (@ARGV) {

  my $self;
  my $arg = shift @ARGV;

  #
  # We hack by saying that if the STRING start with '<' it is a file
  #
  if ($arg =~ /^<(.+)\z/) {
    $arg = read_file($1);
    #
    # Probability to have an automatic and unwanted EOL is high
    # when using a file in input
    #
    $arg =~ s/\s*\z//;
  }
  $log->info('----------------------------------------');
  $log->info('Argument test');
  $log->info('----------------------------------------');
  eval {
      $self = MarpaX::ESLIF::URI->new($arg);
      inspect($self);
  };
  $log->errorf('%s', $@) if $@;

  $log->info('----------------------------------------');
  $log->info('Base test');
  $log->info('----------------------------------------');
  my $base;
  eval {
      $base = $self->base;
      inspect($base);
  };
  $log->errorf('%s', $@) if $@;

  $log->info('----------------------------------------');
  $log->info('Resolve test');
  $log->info('----------------------------------------');
  my $resolve;
  eval {
      $resolve = $self->resolve(MarpaX::ESLIF::URI->new('http://there.com/x/y'));
      inspect($resolve);
  };
  $log->errorf('%s', $@) if $@;

  $log->info('----------------------------------------');
  $log->info('base eq self test');
  $log->info('----------------------------------------');
  eval {
      my $eq = $base eq $self;
      $log->infof($format, '$base eq $self', $eq);
  };
  $log->errorf('%s', $@) if $@;
}

sub inspect {
    my ($self) = @_;

    local %Data::Scan::Printer::Option = (with_ansicolor => 0);
    my @methods = qw/string decoded normalized scheme authority host ip ipv4 ipv6 ipvx zone port path segments query fragment drive user password is_abs to headers/;
    my @_methods = qw/_string _scheme _authority _host _ip _ipv4 _ipv6 _ipvx _zone _port _path _segments _query _fragment _drive _user _password _to _headers/;

    # dspp($self); print "\n";
    $log->infof($format, 'Type', ref($self));
    foreach (@methods, @_methods) {
        next unless $self->can($_);
        $log->infof($format, $_, $self->$_);
    }
}
