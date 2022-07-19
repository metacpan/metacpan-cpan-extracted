package Earth;

use 5.018;

use strict;
use warnings;

use Exporter 'import';

our @EXPORT = qw(
  args
  call
  can
  chain
  error
  false
  make
  roll
  then
  true
  wrap
);

our $TRACE_LIMIT = $ENV{EARTH_TRACE_LIMIT};
our $TRACE_OFFSET = $ENV{EARTH_TRACE_OFFSET} ||= 0;

require Scalar::Util;

# STATE

state $cached = {
  'Earth' => 1,
};

# VERSION

our $VERSION = '0.03';

# AUTHORITY

our $AUTHORITY = 'cpan:AWNCORP';

# FUNCTIONS

sub args {
  return (!@_)
    ? ({})
    : ((@_ == 1 && ref($_[0]) eq 'HASH')
    ? (!%{$_[0]} ? {} : {%{$_[0]}})
    : (@_ % 2 ? {@_, undef} : {@_}));
}

sub call {
  my ($invocant, $routine, @arguments) = @_;
  my $next = !!$routine;
  if ($next && UNIVERSAL::isa($invocant, 'CODE')) {
    return $invocant->(@arguments);
  }
  if ($next && Scalar::Util::blessed($invocant)) {
    return $invocant->$routine(@arguments) if UNIVERSAL::can($invocant, $routine);
    $next = 0;
  }
  if ($next && ref($invocant) eq 'SCALAR') {
    return $$invocant->$routine(@arguments) if UNIVERSAL::can($$invocant, $routine);
    $next = 0;
  }
  if ($next && UNIVERSAL::can(load($invocant), $routine)) {
    no strict 'refs';
    return &{"${invocant}::${routine}"}(@arguments);
  }
  if ($next && UNIVERSAL::can($invocant, 'AUTOLOAD')) {
    no strict 'refs';
    return &{"${invocant}::${routine}"}(@arguments);
  }
  error("Exception! call(@{[join(', ', map qq('$_'), @_)]}) failed.");
}

sub can {
  return if !@_;
  return call((ref($_[0]) ? $_[0] : \$_[0]), 'can', $_[1]);
}


sub chain {
  my ($invocant, @routines) = @_;
  return if !$invocant;
  for my $next (map +(ref($_) eq 'ARRAY' ? $_ : [$_]), @routines) {
    $invocant = call($invocant, @$next);
  }
  return $invocant;
}

sub error {
  my ($message, $offset, $limit) = @_;
  my @stacktrace = ($message || 'Exception!');
  my $frames = trace($offset, $limit);
  if (@$frames > 1) {
    push @stacktrace, "\nTraceback (reverse chronological order):\n";
  }
  for (my $i = 1; $i < @$frames; $i++) {
    push @stacktrace,
    "$$frames[$i][3]\n  in $$frames[$i][1] at line $$frames[$i][2]";
  }
  die(join("\n", @stacktrace, ""));
}

sub false {
  require Scalar::Util;
  state $false = Scalar::Util::dualvar(0, "0");
}

sub load {
  my ($package) = @_;

  if ($$cached{$package}) {
    return $package;
  }

  if ($package eq 'main') {
    return do {$$cached{$package} = 1; $package};
  }

  my $failed = !$package || $package !~ /^\w(?:[\w:']*\w)?$/;
  my $loaded;

  my $error = do {
    local $@;
    no strict 'refs';
    $loaded = !!UNIVERSAL::can($package, 'new');
    $loaded = !!UNIVERSAL::can($package, 'import') if !$loaded;
    $loaded = eval "require $package; 1" if !$loaded;
    $@;
  }
  if !$failed;

  error("Exception! Error loading package \"$package\".")
    if $error
    or $failed
    or not $loaded;

  $$cached{$package} = 1;

  return $package;
}

sub make {
  return if !@_;
  return call($_[0], 'new', @_);
}

sub roll {
  return (@_[1,0,2..$#_]);
}

sub then {
  return ($_[0], call(@_));
}

sub trace {
  my ($offset, $limit) = (@_);

  $offset //= $TRACE_OFFSET // 1;
  $limit //= $TRACE_LIMIT;

  my $frames = [];
  for (my $i = $offset; my @caller = caller($i); $i++) {
    push @$frames, [@caller];
    last if defined($limit) && $i + 1 == $offset + $limit;
  }

  return $frames;
}

sub true {
  require Scalar::Util;
  state $true = Scalar::Util::dualvar(1, "1");
}

sub wrap {
  my ($package, $alias) = @_;
  return if !$package;
  my $moniker = $alias // $package =~ s/\W//gr;
  my $caller = caller(0);
  no strict 'refs';
  no warnings 'redefine';
  return *{"${caller}::${moniker}"} = sub {@_ ? make($package, @_) : $package};
}

1;


=head1 NAME

Earth - FP Framework

=cut

=head1 ABSTRACT

FP Framework for Perl 5

=cut

=head1 VERSION

0.03

=cut

=head1 SYNOPSIS

  package main;

  use Earth;

  wrap 'Digest::SHA', 'SHA';

  call(SHA(), 'sha1_hex');

  # "da39a3ee5e6b4b0d3255bfef95601890afd80709"

=cut

=head1 DESCRIPTION

Earth is a functional-programming framework for Perl 5. Perl is a
multi-paradigm programming language that also supports functional programming,
but, Perl has an intentionally limited standard library with an emphasis on
providing library support via the CPAN which is overwhelmingly object-oriented.
This makes developing in a functional style difficult as you'll eventually need
to rely on a CPAN library that requires you to switch over to object-oriented
programming. Earth facilitates functional programming for Perl 5 by providing
functions which enable indirect routine dispatching, allowing the execution of
both functional and object-oriented code.

=cut

=head1 FUNCTIONS

This package provides the following functions:

=cut

=head2 args

  args(Any @args) (HashRef)

The args function takes a list of arguments and returns a hashref.

I<Since C<0.04>>

=over 4

=item args example 1

  # given: synopsis

  args(content => 'example');

  # {content => "example"}

=back

=over 4

=item args example 2

  # given: synopsis

  args({content => 'example'});

  # {content => "example"}

=back

=over 4

=item args example 3

  # given: synopsis

  args('content');

  # {content => undef}

=back

=over 4

=item args example 4

  # given: synopsis

  args('content', 'example', 'algorithm');

  # {content => "example", algorithm => undef}

=back

=cut

=head2 call

  call(Str | Object | CodeRef $self, Any @args) (Any)

The call function dispatches function and method calls to a package and returns
the result.

I<Since C<0.01>>

=over 4

=item call example 1

  # given: synopsis

  call(SHA, 'sha1_hex');

  # "da39a3ee5e6b4b0d3255bfef95601890afd80709"

=back

=over 4

=item call example 2

  # given: synopsis

  call('Digest::SHA', 'sha1_hex');

  # "da39a3ee5e6b4b0d3255bfef95601890afd80709"

=back

=over 4

=item call example 3

  # given: synopsis

  call(\SHA, 'new');

  # bless(do{\(my $o = '...')}, 'Digest::SHA')

=back

=over 4

=item call example 4

  # given: synopsis

  wrap 'Digest';

  call(Digest('SHA'), 'reset');

  # "da39a3ee5e6b4b0d3255bfef95601890afd80709"

=back

=cut

=head2 can

  can(Str | Object | CodeRef $self, Str $name) (CodeRef)

The can function checks if the object or class has a routine matching the name
provided, and if so returns a coderef for that routine.

I<Since C<0.02>>

=over 4

=item can example 1

  # given: synopsis

  my $coderef = can(SHA(1), 'sha1_hex');

  # sub { ... }

=back

=cut

=head2 chain

  chain(Str | Object | CodeRef $self, Str | ArrayRef[Str] @args) (Any)

The chain function chains function and method calls to a package (and return
values) and returns the result.

I<Since C<0.01>>

=over 4

=item chain example 1

  # given: synopsis

  my $hex = chain(\SHA, 'new', 'sha1_hex');

  # "d3aed913fdc7f277dddcbde47d50a8b5259cb4bc"

=back

=over 4

=item chain example 2

  # given: synopsis

  my $hex = chain(\SHA, 'new', ['add', 'hello'], 'sha1_hex');

  # "f47b0cd4b6336d07ab117d7ee3f47566c9799f23"

=back

=over 4

=item chain example 3

  # given: synopsis

  wrap 'Digest';

  my $hex = chain(Digest('SHA'), ['add', 'hello'], 'sha1_hex');

  # "8575ce82b266fdb5bc98eb43488c3b420577c24c"

=back

=cut

=head2 error

  error(Str $message, Int $offset, Int $limit) (Any)

The error function dies with the error message provided and prints a
stacktrace. If C<$limit> or C<$offset> are provided, those options will
constrain the output of the stacktrace.

I<Since C<0.04>>

=over 4

=item error example 1

  # given: synopsis

  error;

  # "Exception!"

=back

=over 4

=item error example 2

  # given: synopsis

  error('Exception!');

  # "Exception!"

=back

=over 4

=item error example 3

  # given: synopsis

  error('Exception!', 0, 1);

  # "Exception!"

=back

=cut

=head2 false

  false() (Bool)

The false function returns a falsy boolean value which is designed to be
practically indistinguishable from the conventional numerical C<0> value.

I<Since C<0.01>>

=over 4

=item false example 1

  package main;

  use Earth;

  my $false = false;

  # 0

=back

=over 4

=item false example 2

  package main;

  use Earth;

  my $true = !false;

  # 1

=back

=cut

=head2 make

  make(Str $package, Any @args) (Any)

The make function L<"calls"|Earth/call> the C<new> routine on the invocant and
returns the result which should be a package string or an object.

I<Since C<0.01>>

=over 4

=item make example 1

  # given: synopsis

  my $string = make(SHA);

  # bless(do{\(my $o = '...')}, 'Digest::SHA')

=back

=over 4

=item make example 2

  # given: synopsis

  my $string = make(Digest, 'SHA');

  # bless(do{\(my $o = '...')}, 'Digest::SHA')

=back

=cut

=head2 roll

  roll(Str $name, Any @args) (Any)

The roll function takes a list of arguments, assuming the first argument is
invokable, and reorders the list such that the routine name provided comes
after the invocant (i.e. the 1st argument), creating a list acceptable to the
L</call> function.

I<Since C<0.02>>

=over 4

=item roll example 1

  package main;

  use Earth;

  my @list = roll('sha1_hex', SHA);

  # ("Digest::SHA", "sha1_hex")

=back

=over 4

=item roll example 2

  package main;

  use Earth;

  my @list = roll('sha1_hex', call(SHA(1), 'reset'));

  # (bless(do{\(my $o = '...')}, 'Digest::SHA'), "sha1_hex")

=back

=cut

=head2 then

  then(Str | Object | CodeRef $self, Any @args) (Any)

The then function proxies the call request to the L</call> function and returns
the result as a list, prepended with the invocant.

I<Since C<0.02>>

=over 4

=item then example 1

  package main;

  use Earth;

  my @list = then(SHA, 'sha1_hex');

  # ("Digest::SHA", "da39a3ee5e6b4b0d3255bfef95601890afd80709")

=back

=cut

=head2 true

  true() (Bool)

The true function returns a truthy boolean value which is designed to be
practically indistinguishable from the conventional numerical C<1> value.

I<Since C<0.01>>

=over 4

=item true example 1

  package main;

  use Earth;

  my $true = true;

  # 1

=back

=over 4

=item true example 2

  package main;

  use Earth;

  my $false = !true;

  # 0

=back

=cut

=head2 wrap

  wrap(Str $package, Str $alias) (CodeRef)

The wrap function installs a wrapper function in the calling package which when
called either returns the package string if no arguments are provided, or calls
L</make> on the package with whatever arguments are provided and returns the
result. Unless an alias is provided as a second argument, special characters
are stripped from the package to create the function name.

I<Since C<0.01>>

=over 4

=item wrap example 1

  # given: synopsis

  my $coderef = wrap('Digest::SHA');

  # my $digest = DigestSHA();

  # "Digest::SHA"

=back

=over 4

=item wrap example 2

  # given: synopsis

  my $coderef = wrap('Digest::SHA');

  # my $digest = DigestSHA(1);

  # bless(do{\(my $o = '...')}, 'Digest::SHA')

=back

=over 4

=item wrap example 3

  # given: synopsis

  my $coderef = wrap('Digest::SHA', 'SHA');

  # my $digest = SHA;

  # "Digest::SHA"

=back

=over 4

=item wrap example 4

  # given: synopsis

  my $coderef = wrap('Digest::SHA', 'SHA');

  # my $digest = SHA(1);

  # bless(do{\(my $o = '...')}, 'Digest::SHA')

=back

=cut

=head1 AUTHORS

Awncorp, C<awncorp@cpan.org>

=cut