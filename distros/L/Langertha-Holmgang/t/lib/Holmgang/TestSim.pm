package Holmgang::TestSim;
# Test helpers for the simulator tests: one registry, the call shapes of
# cai-platform's Eval::Sim, and the state helpers the ported tests use.
use strict;
use warnings;
use Exporter qw( import );
use JSON::MaybeXS ();
use Test::More ();
use Test::Fatal qw( exception );
use Module::Runtime qw( module_notional_filename require_module );

use Langertha::Holmgang::Simulators;

our @EXPORT_OK = qw( sims run_command write_file prepare clone diff get throws_ok need_parts without_part );

my $SIMS;
sub sims { return $SIMS //= Langertha::Holmgang::Simulators->new }

# ( output, ok, gap ) — the exit status is tested on its own (t/sim/linux_contract.t)
sub run_command { my @r = sims()->run_command(@_); return @r[ 0 .. 2 ] }
sub write_file  { my @r = sims()->write_file(@_);  return @r[ 0 .. 2 ] }
sub prepare     { return sims()->prepare(@_) }

my $JSON = JSON::MaybeXS->new( utf8 => 0, canonical => 1, allow_nonref => 1 );
sub clone { my ($d) = @_; return $JSON->decode( $JSON->encode($d) ) }

# end-state diff as the World computes it: keys with a leading _ are bookkeeping
sub diff {
  my ( $a, $b, @at ) = @_;
  if ( ref $a eq 'HASH' && ref $b eq 'HASH' ) {
    my %k = map { $_ => 1 } grep { !/\A_/ } keys %$a, keys %$b;
    my @out;
    for my $k ( sort keys %k ) {
      if ( !exists $b->{$k} ) {
        push @out, ref $a->{$k} eq 'HASH' && %{ $a->{$k} } ? diff( $a->{$k}, {}, @at, $k ) : { path => [ @at, $k ], before => $a->{$k} };
      }
      elsif ( !exists $a->{$k} ) {
        push @out, ref $b->{$k} eq 'HASH' && %{ $b->{$k} } ? diff( {}, $b->{$k}, @at, $k ) : { path => [ @at, $k ], after => $b->{$k} };
      }
      else { push @out, diff( $a->{$k}, $b->{$k}, @at, $k ) }
    }
    return @out;
  }
  if ( ref $a eq 'ARRAY' && ref $b eq 'ARRAY' && @$a == @$b && grep { ref } @$a, @$b ) {
    return map { diff( $a->[$_], $b->[$_], @at, $_ ) } 0 .. $#$a;
  }
  return () if $JSON->encode($a) eq $JSON->encode($b);
  return { path => \@at, before => $a, after => $b };
}

sub get {
  my ( $d, @seg ) = @_;
  for my $k (@seg) {
    if ( defined $d && !ref $d && $k eq 'content' ) { next }
    if    ( ref $d eq 'HASH' )  { return (0) unless exists $d->{$k}; $d = $d->{$k} }
    elsif ( ref $d eq 'ARRAY' ) { return (0) unless $k =~ /\A\d+\z/ && $k < @$d; $d = $d->[$k] }
    else                        { return (0) }
  }
  return ( 1, $d );
}

sub throws_ok (&$;$) {
  my ( $code, $re, $name ) = @_;
  local $Test::Builder::Level = $Test::Builder::Level + 1;
  return Test::More::like( exception { $code->() }, $re, $name );
}

# Parts of the Linux simulator (and World modules, '+Name') that land in other slices:
# the test (or subtest) skips while one of them is not installed.
sub need_parts {
  my @missing = grep {
    my $c = /\A\+(.+)\z/ ? 'Langertha::Holmgang::'.$1 : 'Langertha::Holmgang::Sim::Linux::'.$_;
    !eval { require_module($c); 1 };
  } @_;
  return @missing ? 'needs '.join( ', ', map { s/\A\+//r } @missing ).' (not installed yet)' : undef;
}

# Run $code while a part of the Linux simulator cannot be loaded, as if it were not
# installed: its %INC entry is dropped and an @INC hook in front of the real directories
# answers "Can't locate". Everything is put back afterwards.
sub without_part {
  my ( $part, $code ) = @_;
  my $file  = module_notional_filename( 'Langertha::Holmgang::Sim::Linux::'.$part );
  my $had   = exists $INC{$file};
  my $saved = $INC{$file};
  delete $INC{$file};
  my $hook = sub { die "Can't locate $file in \@INC (hidden by the test)\n" if $_[1] eq $file; return };
  my @r;
  my $ok = do { local @INC = ( $hook, @INC ); eval { @r = $code->(); 1 } };
  my $err = $@;
  delete $INC{$file};
  $INC{$file} = $saved if $had;
  die $err unless $ok;
  return @r;
}

1;
