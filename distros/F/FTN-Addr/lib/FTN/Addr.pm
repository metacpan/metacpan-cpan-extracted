package FTN::Addr;
$FTN::Addr::VERSION = '20160303';

use strict;
use warnings;

use Carp ();
use Scalar::Util ();

=head1 NAME

FTN::Addr - Object-oriented module for creation and working with FTN addresses.

=head1 VERSION

version 20160303

=head1 SYNOPSIS

  use FTN::Addr;

  my $a = FTN::Addr -> new( '1:23/45' ) or die "this is not a correct address";

  my $b = FTN::Addr -> new( '1:23/45@fidonet' ) or die 'cannot create address';

  print "Hey! They are the same!\n" if $a eq $b; # they actually are, because default domain is 'fidonet'

  $b -> set_domain( 'othernet' );

  print "Hey! They are the same!\n" if $a eq $b; # no output as we changed domain

  $b = FTN::Addr -> new( '44.22', $a ) or die "cannot create address"; # takes the rest of information from optional $a

  $b = $a -> new( '44.22' ) or die "cannot create address"; # the same

  print $a -> f4, "\n"; # 1:23/45.0

  print $a -> s4, "\n"; # 1:23/45

  print $a -> f5, "\n"; # 1:23/45.0@fidonet

  print $a -> s5, "\n"; # 1:23/45@fidonet

=head1 DESCRIPTION

FTN::Addr module is for creation and working with FTN addresses.  Supports domains, different representations and comparison operators.

=cut

use overload
  eq => \ &_eq,
  cmp => \ &_cmp,
  fallback => 1;

use constant DEFAULT_DOMAIN => 'fidonet';

my $domain_re = '[a-z\d_~-]{1,8}';
# frl-1028.002:
# The Domain Name
# ---------------

# The domain name MUST be a character string not more than 8
# characters long and MUST include only characters as defined below in
# BNF. Any other character cannot be used in a domain name.

#   domain   = *pchar
#   pchar    = alphaLC | digit | safe
#   alphaLC  = "a" | "b" | ... | "z"
#   digit    = "0" | "1" | "2" | "3" | "4" | "5" | "6" | "7" | "8" | "9"
#   safe     = '-' | '_' | '~'


sub _remove_presentations {
  my $t = shift;

  delete @$t{ qw/ full4d full5d short4d short5d fqfa brake_style / };
}

=head1 OBJECT CREATION

=head2 new

Can be called as class or object method:

  my $t = FTN::Addr -> new( '1:23/45' ) or die 'something wrong!';

  $t = $t -> new( '1:22/33.44@fidonet' ) or die 'something wrong!'; # advisable to use class call here instead:
  $t = FTN::Addr -> new( '1:22/33.44@fidonet' ) or die 'something wrong!';

Default domain is 'fidonet'.  If point isn't specified, it's considered to be 0.

Address can be:

  3d/4d                                            1:23/45 or 1:23/45.0
  5d                                               1:23/45@fidonet or 1:23/45.0@fidonet
  fqfa                                             fidonet#1:23/45.0
  The Brake! FTN-compatible mailer for OS/2 style  fidonet.1.23.45.0

If passed address misses any part except point and domain, the base is needed to get the missing information from (including domain).  It can be optional second parameter (already created FTN::Addr object) in case of class method call or object itself in case of object method call.

  my $an = FTN::Addr -> new( '99', $t ); # class call.  address in $an is 1:22/99.0@fidonet
  $an = $t -> new( '99' );               # object call.  the same resulting address.

Performs field validation.

In case of error returns undef in scalar context or empty list in list context.

=cut

sub new {
  my $either = shift;
  my $class = ref( $either ) || $either;
  my $addr = shift;

  return
    unless defined $addr;

  my %new;

  if ( $addr =~ m!^($domain_re)\.(\d+)\.(\d+)\.(-?\d+)\.(-?\d+)$! ) { # fidonet.2.451.31.0
    @new{ qw/ domain
              zone
              net
              node
              point
            /
          } = ( $1, $2, $3, $4, $5 );
  } elsif ( $addr =~ m!^($domain_re)#(\d+):(\d+)/(-?\d+)\.(-?\d+)$! ) { # fidonet#2:451/31.0
    @new{ qw/ domain
              zone
              net
              node
              point
            /
          } = ( $1, $2, $3, $4, $5 );
  } elsif ( $addr =~ m!^(\d+):(\d+)/(-?\d+)(?:\.(-?\d+))?(?:@($domain_re))?$! ) { # 2:451/31.0@fidonet 2:451/31@fidonet 2:451/31.0 2:451/31
    @new{ qw/ domain
              zone
              net
              node
              point
            /
          } = ( $5 || DEFAULT_DOMAIN,
                $1, $2, $3,
                $4 || 0,
              );
  } else {	   # partials.  need base.  451/31.0 451/31 31.1 31 .1
    my $base = ref $either ? $either : shift;

    return
      unless $base
      && ref $base
      && Scalar::Util::blessed $base
      && $base -> isa( 'FTN::Addr' );

    if ( $addr =~ m!^(\d+)/(-?\d+)(?:\.(-?\d+))?$! ) { # 451/31.0 451/31
      @new{ qw/ domain
                zone
                net
                node
                point
              /
            } = ( $base -> domain,
                  $base -> zone,
                  $1,
                  $2,
                  $3 || 0,
                );
    } elsif ( $addr =~ m!^(-?\d+)(?:\.(-?\d+))?$! ) { # 31.1 31
      @new{ qw/ domain
                zone
                net
                node
                point
              /
            } = ( $base -> domain,
                  $base -> zone,
                  $base -> net,
                  $1,
                  $2 || 0,
                );
    } elsif ( $addr =~ m!^\.(-?\d+)$! ) { # .1
      @new{ qw/ domain
                zone
                net
                node
                point
              /
            } = ( $base -> domain,
                  $base -> zone,
                  $base -> net,
                  $base -> node,
                  $1,
                );
    } else {                    # not recognizable
      return;
    }
  }

  return
    unless _validate_domain( $new{domain} )
    && _validate_zone( $new{zone} )
    && _validate_net( $new{net} )
    && _validate_node( $new{node} )
    && _validate_point( $new{point} )
    && ( $new{node} != -1       # node application
         || $new{point} == 0
       )
    && ( $new{node} > 0         # point application
         || $new{point} != -1
       );

  bless \ %new, $class;
}

sub _validate_domain {
  defined $_[ 0 ]
    # && length( $_[ 0 ] )
    # && length( $_[ 0 ] ) <= 8     # FRL-1002.001
    # && index( $_[ 0 ], '.' ) == -1; # FRL-1002.001
    && $_[ 0 ] =~ m/^$domain_re$/; # frl-1028.002
}

sub _validate_zone {
  defined $_[ 0 ]
    && 1 <= $_[ 0 ] && $_[ 0 ] <= 32767; # FRL-1002.001, frl-1028.002
}

sub _validate_net {
  defined $_[ 0 ]
    && 1 <= $_[ 0 ] && $_[ 0 ] <= 32767; # FRL-1002.001, frl-1028.002
}

sub _validate_node {
  defined $_[ 0 ]
    && -1 <= $_[ 0 ] && $_[ 0 ] <= 32767; # FRL-1002.001, frl-1028.002
}

sub _validate_point {
  defined $_[ 0 ]
    # && 0 <= $_[ 0 ] && $_[ 0 ] <= 32767; # FRL-1002.001: 0 .. 32765
    && -1 <= $_[ 0 ] && $_[ 0 ] <= 32767; # frl-1028.002: -1 .. 32767
}

=head2 clone

  $th = $an -> clone

=cut

sub clone {
  ref( my $inst = shift ) or Carp::croak "I'm only an object method!";

  bless { %$inst }, ref $inst;
}

=head1 FIELD ACCESS

Direct access to object fields.  Checking is performed (dies on error).  Setters return itself (for possible chaining).

=head2 domain:

  $an -> set_domain( 'mynet' );
  $an -> domain;
  $an -> domain( 'leftnet' );

=for Pod::Coverage domain set_domain

=cut

sub domain {
  ref( my $inst = shift ) or Carp::croak "I'm only an object method!";

  @_ ?
    $inst -> set_domain( @_ )
    : $inst -> {domain};
}

sub set_domain {
  ref( my $inst = shift ) or Carp::croak "I'm only an object method!";

  my $value = shift;

  die 'incorrect domain: ' . ( defined $value ? $value : 'undef' )
    unless _validate_domain( $value );

  $inst -> {domain} = $value;
  $inst -> _remove_presentations;

  $inst;
}

=head2 zone:

  $an -> set_zone( 2 );
  $an -> zone;
  $an -> zone( 3 );

=for Pod::Coverage zone set_zone

=cut

sub zone {
  ref( my $inst = shift ) or Carp::croak "I'm only an object method!";

  @_ ?
    $inst -> set_zone( @_ )
    : $inst -> {zone};
}

sub set_zone {
  ref( my $inst = shift ) or Carp::croak "I'm only an object method!";

  my $value = shift;

  die 'incorrect zone: ' . ( defined $value ? $value : 'undef' )
    unless _validate_zone( $value );

  $inst -> {zone} = $value;
  $inst -> _remove_presentations;

  $inst;
}

=head2 net:

  $an -> set_net( 456 );
  $an -> net;
  $an -> net( 5020 );

=for Pod::Coverage net set_net

=cut

sub net {
  ref( my $inst = shift ) or Carp::croak "I'm only an object method!";

  @_ ?
    $inst -> set_net( @_ )
    : $inst -> {net};
}

sub set_net {
  ref( my $inst = shift ) or Carp::croak "I'm only object method!";

  my $value = shift;

  die 'incorrect net: ' . ( defined $value ? $value : 'undef' )
    unless _validate_net( $value );

  $inst -> {net} = $value;
  $inst -> _remove_presentations;

  $inst;
}

=head2 node:

  $an -> set_node( 33 );
  $an -> node;
  $an -> node( 60 );

=for Pod::Coverage node set_node

=cut

sub node {
  ref( my $inst = shift ) or Carp::croak "I'm only an object method!";

  @_ ?
    $inst -> set_node( @_ )
    : $inst -> {node};
}

sub set_node {
  ref(my $inst = shift) or Carp::croak "I'm only object method!";

  my $value = shift;

  die 'incorrect node: ' . ( defined $value ? $value : 'undef' )
    unless _validate_node( $value );

  $inst -> {node} = $value;
  $inst -> _remove_presentations;

  $inst;
}

=head2 point:

  $an -> set_point( 6 );
  $an -> point;
  $an -> point( 0 );

=for Pod::Coverage point set_point

=cut

sub point {
  ref( my $inst = shift ) or Carp::croak "I'm only an object method!";

  @_ ?
    $inst -> set_point( @_ )
    : $inst -> {point};
}

sub set_point {
  ref(my $inst = shift) or Carp::croak "I'm only object method!";

  my $value = shift;

  die 'incorrect point: ' . ( defined $value ? $value : 'undef' )
    unless _validate_point( $value );

  $inst -> {point} = $value;
  $inst -> _remove_presentations;

  $inst;
}

=head1 REPRESENTATION

=head2 f4 - Full 4d address (without domain):

  print $an -> f4;   # 1:22/99.0

=cut

sub f4 {
  ref( my $inst = shift ) or Carp::croak "I'm only an object method!";

  $inst -> {full4d} = sprintf '%d:%d/%d.%d', map $inst -> { $_ }, qw/ zone net node point /
    unless exists $inst -> {full4d};

  $inst -> {full4d};
}

=head2 s4 - Short form (if possible) of 4d address:

  print $an -> s4;   # 1:22/99

=cut

sub s4 {
  ref( my $inst = shift ) or Carp::croak "I'm only an object method!";

  $inst -> {short4d} = sprintf '%d:%d/%d%s',
    map( $inst -> { $_ }, qw/ zone net node / ),
    $inst -> {point} ? '.' . $inst -> {point} : ''
    unless exists $inst -> {short4d};

  $inst -> {short4d};
}

=head2 f5 - Full 5d address (with domain):

  print $an -> f5;   # 1:22/99.0@fidonet

=cut

sub f5 {
  ref( my $inst = shift ) or Carp::croak "I'm only an object method!";

  $inst -> {full5d} = sprintf '%d:%d/%d.%d@%s', map $inst -> { $_ }, qw/ zone net node point domain /
    unless exists $inst -> {full5d};

  $inst -> {full5d};
}

=head2 s5 - Short form (if possible - only for nodes) of 5d address:

  print $an -> s5;   # 1:22/99@fidonet

=cut

sub s5 {
  ref( my $inst = shift ) or Carp::croak "I'm only an object method!";

  $inst -> {short5d} = sprintf '%d:%d/%d%s@%s',
    map( $inst -> { $_ }, qw/ zone net node / ),
    $inst -> {point} ? '.' . $inst -> {point} : '',
    $inst -> {domain}
    unless exists $inst -> {short5d};

  $inst -> {short5d};
}

=head2 fqfa - Full qualified FTN address:

  print $an -> fqfa; # fidonet#1:22/99.0

=cut

sub fqfa {
  ref( my $inst = shift ) or Carp::croak "I'm only an object method!";

  $inst -> {fqfa} = sprintf '%s#%d:%d/%d.%d', map $inst -> { $_ }, qw/ domain zone net node point /
    unless exists $inst -> {fqfa};

  $inst -> {fqfa};
}

=head2 bs - The Brake! FTN-compatible mailer for OS/2 style representation:

  print $an -> bs;   # fidonet.1.22.99.0

=cut

sub bs {
  ref( my $inst = shift ) or Carp::croak "I'm only an object method!";

  $inst -> {brake_style} = sprintf '%s.%d.%d.%d.%d', map $inst -> { $_ }, qw/ domain zone net node point /
    unless exists $inst -> {brake_style};

  $inst -> {brake_style};
}

=head1 COMPARISON

=head2 equal, eq, cmp

Two addresses can be compared.

  my $one = FTN::Addr -> new( '1:23/45.66@fidonet' ) or die "cannot create";

  my $two = FTN::Addr -> new( '1:23/45.66@fidonet' ) or die "cannot create";

  print "the same address!\n" if FTN::Addr -> equal( $one, $two ); # should print the message

  print "the same address!\n" if $one eq $two;                   # the same result

  print "but objects are different\n" if $one != $two;           # should print the message

The same way (comparison rules) as 'eq' works 'cmp' operator.

=cut

sub _eq {                       # eq operator
  return
    unless $_[ 1 ]
    && ref $_[ 1 ]
    && Scalar::Util::blessed $_[ 1 ]
    && $_[ 1 ] -> isa( 'FTN::Addr' );

  $_[ 0 ] -> domain eq $_[ 1 ] -> domain
    && $_[ 0 ] -> zone == $_[ 1 ] -> zone
    && $_[ 0 ] -> net == $_[ 1 ] -> net
    && $_[ 0 ] -> node == $_[ 1 ] -> node
    && $_[ 0 ] -> point == $_[ 1 ] -> point;
}

sub _cmp {                      # cmp operator
  return
    unless $_[ 1 ]
    && ref $_[ 1 ]
    && Scalar::Util::blessed $_[ 1 ]
    && $_[ 1 ] -> isa( 'FTN::Addr' );

  if ( $_[ 2 ] ) {              # arguments were swapped
    $_[ 1 ] -> domain cmp $_[ 0 ] -> domain
      || $_[ 1 ] -> zone <=> $_[ 0 ] -> zone
      || $_[ 1 ] -> net <=> $_[ 0 ] -> net
      || $_[ 1 ] -> node <=> $_[ 0 ] -> node
      || $_[ 1 ] -> point <=> $_[ 0 ] -> point;
  } else {
    $_[ 0 ] -> domain cmp $_[ 1 ] -> domain
      || $_[ 0 ] -> zone <=> $_[ 1 ] -> zone
      || $_[ 0 ] -> net <=> $_[ 1 ] -> net
      || $_[ 0 ] -> node <=> $_[ 1 ] -> node
      || $_[ 0 ] -> point <=> $_[ 1 ] -> point;
  }
}

sub equal {
  ref( my $class = shift ) and Carp::croak "I'm only a class method!";

  return
    unless $_[ 0 ]
    && ref $_[ 0 ]
    && Scalar::Util::blessed $_[ 0 ]
    && $_[ 0 ] -> isa( 'FTN::Addr' );

  _eq( @_ );
}

=head1 AUTHOR

Valery Kalesnik, C<< <valkoles at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-ftn-addr at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=FTN-Addr>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

  perldoc FTN::Addr

=cut

1;
