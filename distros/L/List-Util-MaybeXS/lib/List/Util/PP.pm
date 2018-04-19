package List::Util::PP;
use strict;
use warnings;
use Exporter ();

our $VERSION = '1.500002';
$VERSION =~ tr/_//d;

our @EXPORT_OK = qw(
  first min max minstr maxstr reduce sum shuffle
  all any none notall product sum0 uniq uniqnum uniqstr
  pairs unpairs pairkeys pairvalues pairmap pairgrep pairfirst
  head tail
);

sub import {
  my $pkg = caller;

  # (RT88848) Touch the caller's $a and $b, to avoid the warning of
  #   Name "main::a" used only once: possible typo" warning
  no strict 'refs';
  ${"${pkg}::a"} = ${"${pkg}::a"};
  ${"${pkg}::b"} = ${"${pkg}::b"};

  goto &Exporter::import;
}

sub reduce (&@) {
  my $f = shift;
  unless ( length ref $f && eval { $f = \&$f; 1 } ) {
    require Carp;
    Carp::croak("Not a subroutine reference");
  }

  return shift unless @_ > 1;

  my $pkg = caller;
  my $a = shift;

  no strict 'refs';
  local *{"${pkg}::a"} = \$a;
  my $glob_b = \*{"${pkg}::b"};

  foreach my $b (@_) {
    local *$glob_b = \$b;
    $a = $f->();
  }

  $a;
}

sub first (&@) {
  my $f = shift;
  unless ( length ref $f && eval { $f = \&$f; 1 } ) {
    require Carp;
    Carp::croak("Not a subroutine reference");
  }

  $f->() and return $_
    foreach @_;

  undef;
}

sub sum (@) {
  return undef unless @_;
  my $s = 0;
  $s += $_ foreach @_;
  return $s;
}

sub min (@) {
  return undef unless @_;
  my $min = shift;
  $_ < $min and $min = $_
    foreach @_;
  return $min;
}

sub max (@) {
  return undef unless @_;
  my $max = shift;
  $_ > $max and $max = $_
    foreach @_;
  return $max;
}

sub minstr (@) {
  return undef unless @_;
  my $min = shift;
  $_ lt $min and $min = $_
    foreach @_;
  return $min;
}

sub maxstr (@) {
  return undef unless @_;
  my $max = shift;
  $_ gt $max and $max = $_
    foreach @_;
  return $max;
}

sub shuffle (@) {
  my @a=\(@_);
  my $n;
  my $i=@_;
  map {
    $n = rand($i--);
    (${$a[$n]}, $a[$n] = $a[$i])[0];
  } @_;
}

sub all (&@) {
  my $f = shift;
  unless ( length ref $f && eval { $f = \&$f; 1 } ) {
    require Carp;
    Carp::croak("Not a subroutine reference");
  }

  $f->() or return 0
    foreach @_;
  return 1;
}

sub any (&@) {
  my $f = shift;
  unless ( length ref $f && eval { $f = \&$f; 1 } ) {
    require Carp;
    Carp::croak("Not a subroutine reference");
  }

  $f->() and return 1
    foreach @_;
  return 0;
}

sub none (&@) {
  my $f = shift;
  unless ( length ref $f && eval { $f = \&$f; 1 } ) {
    require Carp;
    Carp::croak("Not a subroutine reference");
  }

  $f->() and return 0
    foreach @_;
  return 1;
}

sub notall (&@) {
  my $f = shift;
  unless ( length ref $f && eval { $f = \&$f; 1 } ) {
    require Carp;
    Carp::croak("Not a subroutine reference");
  }

  $f->() or return 1
    foreach @_;
  return 0;
}

sub product (@) {
  my $p = 1;
  $p *= $_ foreach @_;
  return $p;
}

sub sum0 (@) {
  my $s = 0;
  $s += $_ foreach @_;
  return $s;
}

sub pairs (@) {
  if (@_ % 2) {
    warnings::warnif('misc', 'Odd number of elements in pairs');
  }

  return
    map { bless [ @_[$_, $_ + 1] ], 'List::Util::PP::_Pair' }
    map $_*2,
    0 .. int($#_/2);
}

sub unpairs (@) {
  map @{$_}[0,1], @_;
}

sub pairkeys (@) {
  if (@_ % 2) {
    warnings::warnif('misc', 'Odd number of elements in pairkeys');
  }

  return
    map $_[$_*2],
    0 .. int($#_/2);
}

sub pairvalues (@) {
  if (@_ % 2) {
    require Carp;
    warnings::warnif('misc', 'Odd number of elements in pairvalues');
  }

  return
    map $_[$_*2 + 1],
    0 .. int($#_/2);
}

sub pairmap (&@) {
  my $f = shift;
  unless ( length ref $f && eval { $f = \&$f; 1 } ) {
    require Carp;
    Carp::croak("Not a subroutine reference");
  }

  if (@_ % 2) {
    warnings::warnif('misc', 'Odd number of elements in pairmap');
  }

  my $pkg = caller;
  no strict 'refs';
  my $glob_a = \*{"${pkg}::a"};
  my $glob_b = \*{"${pkg}::b"};

  return
    map {
      local (*$glob_a, *$glob_b) = \( @_[$_,$_+1] );
      $f->();
    }
    map $_*2,
    0 .. int($#_/2);
}

sub pairgrep (&@) {
  my $f = shift;
  unless ( length ref $f && eval { $f = \&$f; 1 } ) {
    require Carp;
    Carp::croak("Not a subroutine reference");
  }

  if (@_ % 2) {
    warnings::warnif('misc', 'Odd number of elements in pairgrep');
  }

  my $pkg = caller;
  no strict 'refs';
  my $glob_a = \*{"${pkg}::a"};
  my $glob_b = \*{"${pkg}::b"};

  return
    map {
      local (*$glob_a, *$glob_b) = \( @_[$_,$_+1] );
      $f->() ? (wantarray ? @_[$_,$_+1] : 1) : ();
    }
    map $_*2,
    0 .. int ($#_/2);
}

sub pairfirst (&@) {
  my $f = shift;
  unless ( length ref $f && eval { $f = \&$f; 1 } ) {
    require Carp;
    Carp::croak("Not a subroutine reference");
  }

  if (@_ % 2) {
    warnings::warnif('misc', 'Odd number of elements in pairfirst');
  }

  my $pkg = caller;
  no strict 'refs';
  my $glob_a = \*{"${pkg}::a"};
  my $glob_b = \*{"${pkg}::b"};

  foreach my $i (map $_*2, 0 .. int($#_/2)) {
    local (*$glob_a, *$glob_b) = \( @_[$i,$i+1] );
    return wantarray ? @_[$i,$i+1] : 1
      if $f->();
  }
  return ();
}

sub List::Util::PP::_Pair::key   { $_[0][0] }
sub List::Util::PP::_Pair::value { $_[0][1] }

sub uniq (@) {
  my %seen;
  my $undef;
  my @uniq = grep defined($_) ? !$seen{$_}++ : !$undef++, @_;
  @uniq;
}

sub uniqnum (@) {
  my %seen;
  my @uniq =
    grep !$seen{(eval { pack "J", $_ }||'') . pack "F", $_}++,
    map +(defined($_) ? $_
      : do { warnings::warnif('uninitialized', 'Use of uninitialized value in subroutine entry'); 0 }),
    @_;
  @uniq;
}

sub uniqstr (@) {
  my %seen;
  my @uniq =
    grep !$seen{$_}++,
    map +(defined($_) ? $_
      : do { warnings::warnif('uninitialized', 'Use of uninitialized value in subroutine entry'); '' }),
    @_;
  @uniq;
}

sub head ($@) {
  my $size = shift;
  return @_
    if $size > @_;
  @_[ 0 .. ( $size >= 0 ? $size - 1 : $#_ + $size ) ];
}

sub tail ($@) {
  my $size = shift;
  return @_
    if $size > @_;
  @_[ ( $size >= 0 ? ($#_ - ($size-1) ) : 0 - $size ) .. $#_ ];
}

1;

__END__

=head1 NAME

List::Util::PP - Pure-perl implementations of List::Util subroutines

=head1 SYNOPSIS

    use List::Util::PP qw(
      reduce any all none notall first

      max maxstr min minstr product sum sum0

      pairs pairkeys pairvalues pairfirst pairgrep pairmap

      shuffle

      head tail
    );

=head1 DESCRIPTION

C<List::Util::PP> contains pure-perl implementations of all of the functions
documented in L<List::Util>.  This is meant for when a compiler is not
available, or when packaging for reuse without without installing modules.

Generally, L<List::Util::MaybeXS> should be used instead, which will
automatically use the faster XS implementation when possible, but fall back on
this module otherwise.

=head1 FUNCTIONS

=over

=item L<all|List::Util/all>

=item L<any|List::Util/any>

=item L<first|List::Util/first>

=item L<min|List::Util/min>

=item L<max|List::Util/max>

=item L<minstr|List::Util/minstr>

=item L<maxstr|List::Util/maxstr>

=item L<none|List::Util/none>

=item L<notall|List::Util/notall>

=item L<product|List::Util/product>

=item L<reduce|List::Util/reduce>

=item L<sum|List::Util/sum>

=item L<sum0|List::Util/sum0>

=item L<shuffle|List::Util/shuffle>

=item L<uniq|List::Util/uniq>

=item L<uniqnum|List::Util/uniqnum>

=item L<uniqstr|List::Util/uniqstr>

=item L<pairs|List::Util/pairs>

=item L<unpairs|List::Util/unpairs>

=item L<pairkeys|List::Util/pairkeys>

=item L<pairvalues|List::Util/pairvalues>

=item L<pairmap|List::Util/pairmap>

=item L<pairgrep|List::Util/pairgrep>

=item L<pairfirst|List::Util/pairfirst>

=item L<head|List::Util/head>

=item L<tail|List::Util/tail>

=back

=head1 SUPPORT

See L<List::Util::MaybeXS> for support and contact information.

=head1 AUTHORS

See L<List::Util::MaybeXS> for authors.

=head1 COPYRIGHT AND LICENSE

See L<List::Util::MaybeXS> for the copyright and license.

=cut
