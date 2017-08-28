package Math::Random::MTwist;

use strict;
use warnings;

use Exporter;
use Time::HiRes;  # for timeseed()
use XSLoader;

use constant MT_TIMESEED => \0;
use constant MT_FASTSEED => \0;
use constant MT_GOODSEED => \0;
use constant MT_BESTSEED => \0;

our $VERSION = '0.23';

our @ISA = 'Exporter';
our @EXPORT = qw(MT_TIMESEED MT_FASTSEED MT_GOODSEED MT_BESTSEED);
our @EXPORT_OK = @EXPORT;
our %EXPORT_TAGS = (
  'rand'  => [
    qw(srand rand rand32 rand64 irand irand32 irand64 irand128 randstr)
  ],
  'seed'  => [qw(seed32 seedfull timeseed fastseed goodseed bestseed)],
  'state' => [qw(savestate loadstate getstate setstate)],
  'dist'  => [
    qw(
        rd_double
        rd_iuniform rd_iuniform32 rd_iuniform64
        rd_uniform rd_luniform
        rd_erlang rd_lerlang
        rd_exponential rd_lexponential
        rd_lognormal rd_llognormal
        rd_normal rd_lnormal
        rd_triangular rd_ltriangular
        rd_weibull rd_lweibull
    )
  ],
);

$EXPORT_TAGS{all} = [ map @$_, values %EXPORT_TAGS ];

XSLoader::load('Math::Random::MTwist', $VERSION);

# We want the function-oriented interface to provide the same function names as
# the OO interface. But since it doesn't have the state argument (aka $self),
# MTwist.xs provides counterparts with a leading underscore that we map to here.
sub import {
  my $this = shift;

  my @unhandled_args;

  if (@_) {
    my $caller = caller;
    my $need4seed = 0;
    my %exportable = map +($_ => 1), @{$EXPORT_TAGS{all}};

    while (defined(my $arg = shift)) {
      if ($arg =~ /^:(.+)/ && exists $EXPORT_TAGS{$1}) {
        push @_, @{$EXPORT_TAGS{$1}};
      }
      elsif ($exportable{$arg}) {
        no strict 'refs';
        $need4seed++;
        *{"$caller\::$arg"} = \&{"$this\::_$arg"};
      }
      else {
        push @unhandled_args, $arg;
      }
    }

    _fastseed() if $need4seed;
  }

  __PACKAGE__->export_to_level(1, $this, @unhandled_args);
}

sub new {
  my $class = shift;
  my $seed = shift;

  my $self = new_state($class);

  if (! defined $seed) {
    $self->fastseed();
  }
  elsif (! ref $seed) {
    $self->seed32($seed);
  }
  elsif (ref $seed eq 'ARRAY') {
    $self->seedfull($seed);
  }
  elsif ($seed == MT_TIMESEED) {
    $self->timeseed();
  }
  elsif ($seed == MT_FASTSEED) {
    $self->fastseed();
  }
  elsif ($seed == MT_GOODSEED) {
    $self->goodseed();
  }
  elsif ($seed == MT_BESTSEED) {
    $self->bestseed();
  }
  else { # WTF?
    $self->fastseed();
  }

  $self;
}

1;
