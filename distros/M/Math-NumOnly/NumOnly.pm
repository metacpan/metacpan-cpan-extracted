package Math::NumOnly;
use strict;
use warnings;

use overload
'+'    => \&oload_add,
'-'    => \&oload_sub,
'*'    => \&oload_mul,
'/'    => \&oload_div,
'**'   => \&oload_pow,
'++'   => \&oload_inc,
'--'   => \&oload_dec,
'>='   => \&oload_gte,
'<='   => \&oload_lte,
'=='   => \&oload_equiv,
'>'    => \&oload_gt,
'<'    => \&oload_lt,
'<=>'  => \&oload_spaceship,
'""'   => \&oload_stringify,
;

our $VERSION = '0.01';

require DynaLoader;
Math::NumOnly->DynaLoader::bootstrap($VERSION);
sub dl_load_flags {0}

sub new {
  shift if(!ref($_[0]) && $_[0] eq "Math::NumOnly"); # 'new' has been called as a method

  my $ok = is_ok($_[0]);
  die "Bad argument (or no argument) given to new" unless $ok;

  if($ok == 1) {
    # return a copy of the given Math::NumOnly object
    my $ret = shift;
    return $ret;
  }

  # given arg must be a valid IV or NV
  my %h = ('val' => shift);
  return bless(\%h, 'Math::NumOnly');
}

sub oload_add {
  die "Wrong number of arguments given to oload_add()"
    if @_ > 3;

  my $ok = is_ok($_[1]); # check that 2nd arg is suitable.
  die "Bad argument given to oload_add" unless $ok;

  if($ok == 1) {
    return Math::NumOnly->new($_[0]->{val} + $_[1]->{val});
  }

  return Math::NumOnly->new($_[0]->{val} + $_[1]);
}

sub oload_mul {
  die "Wrong number of arguments given to oload_mul()"
    if @_ > 3;

  my $ok = is_ok($_[1]); # check that 2nd arg is suitable.
  die "Bad argument given to oload_mul" unless $ok;

  if($ok == 1) {
    return Math::NumOnly->new($_[0]->{val} * $_[1]->{val});
  }

  return Math::NumOnly->new($_[0]->{val} * $_[1]);
}

sub oload_sub {
  die "Wrong number of arguments given to oload_sub()"
    if @_ > 3;

  my $ok = is_ok($_[1]); # check that 2nd arg is suitable.
  die "Bad argument given to oload_sub" unless $ok;

  my $third_arg = $_[2];

  if($ok == 1) {
    if($third_arg) {
      return Math::NumOnly->new($_[1]->{val} - $_[0]->{val});
    }
    return Math::NumOnly->new($_[0]->{val} - $_[1]->{val});
  }

  if($third_arg) {
    return Math::NumOnly->new($_[1] - $_[0]->{val});
  }
  return Math::NumOnly->new($_[0]->{val} - $_[1]);
}

sub oload_div {
  die "Wrong number of arguments given to oload_div()"
    if @_ > 3;

  my $ok = is_ok($_[1]); # check that 2nd arg is suitable.
  die "Bad argument given to oload_div" unless $ok;

  my $third_arg = $_[2];

  if($ok == 1) {
    if($third_arg) {
      return Math::NumOnly->new($_[1]->{val} / $_[0]->{val});
    }
    return Math::NumOnly->new($_[0]->{val} / $_[1]->{val});
  }

  if($third_arg) {
    return Math::NumOnly->new($_[1] / $_[0]->{val});
  }
  return Math::NumOnly->new($_[0]->{val} / $_[1]);
}

sub oload_pow {
  die "Wrong number of arguments given to oload_pow()"
    if @_ > 3;

  my $ok = is_ok($_[1]); # check that 2nd arg is suitable.
  die "Bad argument given to oload_div" unless $ok;

  my $third_arg = $_[2];

  if($ok == 1) {
    if($third_arg) {
      return Math::NumOnly->new($_[1]->{val} ** $_[0]->{val});
    }
    return Math::NumOnly->new($_[0]->{val} ** $_[1]->{val});
  }

  if($third_arg) {
    return Math::NumOnly->new($_[1] ** $_[0]->{val});
  }
  return Math::NumOnly->new($_[0]->{val} ** $_[1]);
}

sub oload_inc {
  ($_[0]->{val}) += 1;;
}

sub oload_dec {
  ($_[0]->{val}) -= 1;
}

sub oload_stringify {
  my $self = shift;
  return $self->{val};
}

sub oload_gte {
  die "Wrong number of arguments given to oload_gte()"
    if @_ > 3;

  my $cmp = oload_spaceship($_[0], $_[1], $_[2]);

  return 1 if $cmp >= 0;
  return 0;
}

sub oload_lte {
  die "Wrong number of arguments given to oload_lte()"
    if @_ > 3;

  my $cmp = oload_spaceship($_[0], $_[1], $_[2]);

  #if($_[2]) {
  #  return 1 if $cmp >= 0;
  #  return 0;
  #}

  return 1 if $cmp <= 0;
  return 0;
}

sub oload_equiv {
  die "Wrong number of arguments given to oload_equiv()"
    if @_ > 3;

  return 1 if(oload_spaceship($_[0], $_[1], $_[2]) == 0);
  return 0;
}

sub oload_gt {
  die "Wrong number of arguments given to oload_gt()"
    if @_ > 3;

  my $cmp = oload_spaceship($_[0], $_[1], $_[2]);

  return 1 if $cmp > 0;
  return 0;
}

sub oload_lt {
  die "Wrong number of arguments given to oload_lt()"
    if @_ > 3;

  my $cmp = oload_spaceship($_[0], $_[1], $_[2]);

  return 1 if $cmp < 0;
  return 0;
}

sub oload_spaceship {
  die "Wrong number of arguments given to oload_spaceship()"
    if @_ > 3;

  my $ok = is_ok($_[1]); # check that 2nd arg is suitable.
  die "Bad argument given to oload_spaceship" unless $ok;

  my $third_arg = $_[2];

  if($ok == 1) {
    if($third_arg) {
      return ($_[1]->{val} <=> $_[0]->{val});
    }
    return ($_[0]->{val} <=> $_[1]->{val});
  }
  if($third_arg) {
     return ($_[1] <=> $_[0]->{val});
  }
  return ($_[0]->{val} <=> $_[1]);
}

1;

__END__

