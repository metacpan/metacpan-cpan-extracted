package FTN::Addr;
$FTN::Addr::VERSION = '20250717';

use strict;
use utf8;
use warnings;

use Carp ();
use Scalar::Util ();

=encoding utf8

=head1 NAME

FTN::Addr - working with FTN addresses

=head1 VERSION

version 20250717

=head1 SYNOPSIS

  use FTN::Addr ();

  my $a = FTN::Addr -> new( '1:23/45' )
    or die "this is not a correct address";

  my ( $b, $error ) = FTN::Addr -> new( '1:23/45@fidonet' );
  if ( $error
     ) { # process the error (notify, log, die, ...)
    die 'cannot create address because: ' . $error;
  }

  print "Hey! They are the same!\n"
    if $a eq $b; # they actually are, because default domain is 'fidonet'

  if ( my $error = $b -> set_domain( 'othernet' )
     ) {
    # process the error (notify, log, die, ...)

  }

  print "Hey! They are the same!\n"
    if $a eq $b; # no output as we changed domain

  $b = FTN::Addr -> new( '44.22', $a )
    or die "cannot create address"; # takes the missing information from optional $a

  # or the same if you want to know what was the reason of failure (if there was a failure)
  ( $b, $error ) = FTN::Addr -> new( '44.22', $a );
  if ( $error
     ) {
    # process the error (notify, log, die, ...)

  }

  # can also be called as object method
  ( $b, $error ) = $a -> new( '44.22' );
  if ( $error
     ) {
    # process the error (notify, log, die, ...)

  }

  print $a -> f4, "\n"; # 1:23/45.0

  print $a -> s4, "\n"; # 1:23/45

  print $a -> f5, "\n"; # 1:23/45.0@fidonet

  print $a -> s5, "\n"; # 1:23/45@fidonet

=head1 DESCRIPTION

FTN::Addr is a module for working with FTN addresses.  Supports domains, different representations and comparison operators.

=cut

use overload
  'eq' => \ &_eq,
  'cmp' => \ &_cmp,
  'fallback' => 1;

use constant
  'DEFAULT_DOMAIN' => 'fidonet';

my $domain_re = qr/[a-z\d_~-]{1,8}/;
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

  delete @{ $t }{ qw/ full4d
                      full5d
                      short4d
                      short5d
                      fqfa
                      brake_style
                    / };
}

=head1 OBJECT CREATION

=head2 new

Can be called as class or object method.  Performs fields validation.

In scalar context an object is returned.  Or undef in case of an error.

In list context the pair ( $object, $error ) is returned.  If $error is false - $object is good to be used.
In case of error $object isn't usable and $error holds information about the failure.

  my $t = FTN::Addr -> new( '1:23/45' )
    or die 'something wrong!';

  my $k = $t -> new( '22/33.44@fidonet' ) # the missing information will be taken from the $t object
    or die 'something wrong!';

  my ( $l, $error ) = FTN::Addr -> new( '1:22/33.44@fidonet' );
  if ( $error
     ) { # do something about the error
    die 'cannot created an address because: ' . $error;
  }

Default domain is 'fidonet'.  If point isn't specified, it's considered to be 0.

Address can be:

  3d/4d                                            1:23/45 or 1:23/45.0
  5d                                               1:23/45@fidonet or 1:23/45.0@fidonet
  fqfa                                             fidonet#1:23/45.0
  The Brake! FTN-compatible mailer for OS/2 style  fidonet.1.23.45.0

If passed address misses any part except point and domain, the base is needed to get the missing information from (including domain).  It can be an optional second parameter (already created FTN::Addr object) in case of class method call or an object itself in case of object method call.

  my $an = FTN::Addr -> new( '99', $k ); # class call.  address in $an is 1:22/99.0@fidonet
  $an = $k -> new( '99' );               # object call.  the same resulting address.

or use list context if you want to know the details of validation failure:

  ( $an, $error ) = $k -> new( '99' );

=cut

sub new {
  my $either = shift;
  my $class = ref( $either ) || $either;
  my $addr = shift;

  unless ( defined $addr
         ) {
    return undef
      unless wantarray;

    return ( undef, 'address should be provided' );
  }

  my %new;

  if ( $addr =~ m!^($domain_re)\.(\d{1,5})\.(\d{1,5})\.(-?\d{1,5})\.(-?\d{1,5})$!
     ) { # fidonet.2.451.31.0
    @new{ qw/ domain
              zone
              net
              node
              point
            /
          } = ( $1, $2, $3, $4, $5 );
  } elsif ( $addr =~ m!^($domain_re)#(\d{1,5}):(\d{1,5})/(-?\d{1,5})\.(-?\d{1,5})$!
          ) { # fidonet#2:451/31.0
    @new{ qw/ domain
              zone
              net
              node
              point
            /
          } = ( $1, $2, $3, $4, $5 );
  } elsif ( $addr =~ m!^(\d{1,5}):(\d{1,5})/(-?\d{1,5})(?:\.(-?\d{1,5}))?(?:@($domain_re))?$!
          ) { # 2:451/31.0@fidonet 2:451/31@fidonet 2:451/31.0 2:451/31
    @new{ qw/ domain
              zone
              net
              node
              point
            /
          } = ( $5 || DEFAULT_DOMAIN(),
                $1, $2, $3,
                $4 || 0,
              );
  } else {         # partials.  need base.  451/31.0 451/31 31.1 31 .1
    my $base = ref $either ? $either : shift;

    unless ( $base
             && ref $base
             && Scalar::Util::blessed( $base )
             && $base -> isa( 'FTN::Addr' )
           ) {
      return undef
        unless wantarray;

      return ( undef, 'a base should be provided for partial address' );
    }

    if ( $addr =~ m!^(\d{1,5})/(-?\d{1,5})(?:\.(-?\d{1,5}))?$!
       ) { # 451/31.0 451/31
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
    } elsif ( $addr =~ m!^(-?\d{1,5})(?:\.(-?\d{1,5}))?$!
            ) { # 31.1 31
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
    } elsif ( $addr =~ m!^\.(-?\d{1,5})$!
            ) { # .1
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
      return undef
        unless wantarray;

      return ( undef, 'unrecognized address format: ' . $addr );
    }
  }

  for my $f
    ( [ \ &_validate_domain, $new{ 'domain' } ],
      [ \ &_validate_zone, $new{ 'zone' } ],
      [ \ &_validate_net, $new{ 'net' } ],
      [ \ &_validate_node, $new{ 'node' } ],
      [ \ &_validate_point, $new{ 'point' } ],
    ) {
    my ( $sub, $val ) = @{ $f };

    if ( my $error = $sub -> ( $val )
       ) {
      return undef
        unless wantarray;

      return ( undef, $error );
    }
  }

  # node application
  if ( $new{ 'node' } == -1
       && $new{ 'point' } != 0
     ) {
      return undef
        unless wantarray;

      return ( undef, 'node cannot be -1 for a point' );
  }

  # point application
  if ( $new{ 'point' } == -1
       && $new{ 'node' } <= 0
     ) {
      return undef
        unless wantarray;

      return ( undef, 'point should be -1 only for a regular node' );
  }

  bless \ %new, $class;
}

sub _validate_domain {
  return 'domain should be defined'
    unless defined $_[ 0 ];

  return 'invalid domain: ' . $_[ 0 ]
    unless $_[ 0 ] =~ m/^$domain_re$/; # frl-1028.002

  undef;
}

sub _validate_zone {
  # [ 1 .. 32767 ] by FRL-1002.001, frl-1028.002.  why not 1 .. 65535?
  return 'zone should be defined'
    unless defined $_[ 0 ];

  return 'zone should be a number, but it is ' . $_[ 0 ]
    unless $_[ 0 ] =~ m/^\d{1,5}$/;

  return 'zone should be at least 1, but it is ' . $_[ 0 ]
    unless 1 <= $_[ 0 ];

  return 'zone should be at most 32767, but it is ' . $_[ 0 ]
    unless $_[ 0 ] <= 32767;

  undef;
}

sub _validate_net {
  # [ 1 .. 32767 ] by FRL-1002.001, frl-1028.002.  why not 1 .. 65535?
  return 'net should be defined'
    unless defined $_[ 0 ];

  return 'net should be a number, but it is ' . $_[ 0 ]
    unless $_[ 0 ] =~ m/^\d{1,5}$/;

  return 'net should be at least 1, but it is ' . $_[ 0 ]
    unless 1 <= $_[ 0 ];

  return 'net should be at most 32767, but it is ' . $_[ 0 ]
    unless $_[ 0 ] <= 32767;

  undef;
}

sub _validate_node {
  # [ -1 .. 32767 ] by FRL-1002.001, frl-1028.002.  why not 0 .. 65534, and 65535 special == -1?
  return 'node should be defined'
    unless defined $_[ 0 ];

  return 'node should be a number, but it is ' . $_[ 0 ]
    unless $_[ 0 ] =~ m/^-?(?:\d{1,5})$/;

  return 'node should be at least -1, but it is ' . $_[ 0 ]
    unless -1 <= $_[ 0 ];

  return 'node should be at most 32767, but it is ' . $_[ 0 ]
    unless $_[ 0 ] <= 32767;

  undef;
}

sub _validate_point {
  # [ 0 .. 32767 ] by FRL-1002.001
  # [ -1 .. 32767 ] by frl-1028.002.  why not 0 .. 65534, and 65535 special == -1?
  return 'point should be defined'
    unless defined $_[ 0 ];

  return 'point should be a number, but it is ' . $_[ 0 ]
    unless $_[ 0 ] =~ m/^-?(?:\d{1,5})$/;

  return 'point should be at least -1, but it is ' . $_[ 0 ]
    unless -1 <= $_[ 0 ];

  return 'point should be at most 32767, but it is ' . $_[ 0 ]
    unless $_[ 0 ] <= 32767;

  undef;
}

=head2 clone

  my $clone_addr = $an -> clone;

=cut

sub clone {
  ref( my $inst = shift )
    or Carp::croak( "I'm only an object method!" );

  bless { %{ $inst } }, ref $inst;
}

=head1 FIELD ACCESS

Direct access to object fields.

=head2 domain

Returns current domain.

  my $domain = $an -> domain;

=cut

sub domain {
  ref( my $inst = shift )
    or Carp::croak( "I'm only an object method!" );

  $inst -> { 'domain' };
}

=head2 set_domain

Sets new domain to the current address.  Validation is performed.  Returned true value is a string describing failure in validation.  False value means new value is valid.

  if ( my $error = $an -> set_domain( 'mynet' )
     ) {
    # deal with error here (notify, log, request valid, ...)

  }

=cut

sub set_domain {
  ref( my $inst = shift )
    or Carp::croak( "I'm only an object method!" );

  my $value = shift;

  if ( my $error = _validate_domain( $value )
     ) {
    return $error;
  }

  $inst -> { 'domain' } = $value;
  $inst -> _remove_presentations;

  undef;
}

=head2 zone

Returns current zone value.

  my $zone = $an -> zone;

=cut

sub zone {
  ref( my $inst = shift )
    or Carp::croak( "I'm only an object method!" );

  $inst -> { 'zone' };
}

=head2 set_zone

Sets new zone to the current address.  Validation is performed.  Returned true value is a string describing failure in validation.  False value means new value is valid.

  if ( my $error = $an -> set_zone( 2 )
     ) {
    # deal with error here (notify, log, request valid, ...)

  }

=cut

sub set_zone {
  ref( my $inst = shift )
    or Carp::croak( "I'm only an object method!" );

  my $value = shift;

  if ( my $error = _validate_zone( $value )
     ) {
    return $error;
  }

  $inst -> { 'zone' } = $value;
  $inst -> _remove_presentations;

  undef;
}

=head2 net

Returns current net value.

  my $net = $an -> net;

=cut

sub net {
  ref( my $inst = shift )
    or Carp::croak( "I'm only an object method!" );

  $inst -> { 'net' };
}

=head2 set_net

Sets new net to the current address.  Validation is performed.  Returned true value is a string describing failure in validation.  False value means new value is valid.

  if ( my $error = $an -> set_net( 456 )
     ) {
    # deal with error here (notify, log, request valid, ...)

  }

=cut

sub set_net {
  ref( my $inst = shift )
    or Carp::croak( "I'm only object method!" );

  my $value = shift;

  if ( my $error = _validate_net( $value )
     ) {
    return $error;
  }

  $inst -> { 'net' } = $value;
  $inst -> _remove_presentations;

  undef;
}

=head2 node

Returns current node value.

  my $node = $an -> node;

=cut

sub node {
  ref( my $inst = shift )
    or Carp::croak( "I'm only an object method!" );

  $inst -> { 'node' };
}

=head2 set_node

Sets new node to the current address.  Validation is performed.  Returned true value is a string describing failure in validation.  False value means new value is valid.

  if ( my $error = $an -> set_node( 33 )
     ) {
    # deal with error here (notify, log, request valid, ...)

  }

=cut

sub set_node {
  ref( my $inst = shift )
    or Carp::croak( "I'm only object method!" );

  my $value = shift;

  if ( my $error = _validate_node( $value )
     ) {
    return $error;
  }

  return 'cannot assign node value to -1 while point is not 0'
    if $value == -1
       && $inst -> point != 0;

  $inst -> { 'node' } = $value;
  $inst -> _remove_presentations;

  undef;
}

=head2 point

  my $point = $an -> point;

=cut

sub point {
  ref( my $inst = shift )
    or Carp::croak( "I'm only an object method!" );

  $inst -> { 'point' };
}

=head2 set_point

Sets new point to the current address.  Validation is performed.  Returned true value is a string describing failure in validation.  False value means new value is valid.

  if ( my $error = $an -> set_point( 6 )
     ) {
    # deal with error here (notify, log, request valid, ...)

  }

  if ( my $error = $an -> set_point( 0 )
     ) {
    # deal with error here (notify, log, request valid, ...)

  }

=cut

sub set_point {
  ref( my $inst = shift )
    or Carp::croak( "I'm only object method!" );

  my $value = shift;

  if ( my $error = _validate_point( $value )
     ) {
    return $error;
  }

  return 'cannot assign point to -1 for not a regular node'
    if $value == -1
       && $inst -> node <= 0;

  $inst -> { 'point' } = $value;
  $inst -> _remove_presentations;

  undef;
}

=head1 REPRESENTATION

=head2 f4

Full 4d address (without domain):

  print $an -> f4;   # 2:456/33.0

=cut

sub f4 {
  ref( my $inst = shift )
    or Carp::croak( "I'm only an object method!" );

  $inst -> { 'full4d' } = sprintf( '%d:%d/%d.%d',
                                   @{ $inst }{ qw/ zone net node point / }
                                 )
    unless exists $inst -> { 'full4d' };

  $inst -> { 'full4d' };
}

=head2 s4

Short form (if possible) of 4d address:

  print $an -> s4;   # 2:456/33

=cut

sub s4 {
  ref( my $inst = shift )
    or Carp::croak( "I'm only an object method!" );

  $inst -> { 'short4d' } = sprintf( '%d:%d/%d%s',
                                    @{ $inst }{ qw/ zone net node / },
                                    $inst -> { 'point' } ? '.' . $inst -> { 'point' } : ''
                                  )
    unless exists $inst -> { 'short4d' };

  $inst -> { 'short4d' };
}

=head2 f5

Full 5d address (with domain):

  print $an -> f5;   # 2:456/33.0@mynet

=cut

sub f5 {
  ref( my $inst = shift )
    or Carp::croak( "I'm only an object method!" );

  $inst -> { 'full5d' } = sprintf( '%d:%d/%d.%d@%s',
                                   @{ $inst }{ qw/ zone net node point domain / }
                                 )
    unless exists $inst -> { 'full5d' };

  $inst -> { 'full5d' };
}

=head2 s5

Short form (if possible - only for nodes) of 5d address:

  print $an -> s5;   # 2:456/33@mynet

=cut

sub s5 {
  ref( my $inst = shift )
    or Carp::croak( "I'm only an object method!" );

  $inst -> { 'short5d' } = sprintf( '%d:%d/%d%s@%s',
                                    @{ $inst }{ qw/ zone net node / },
                                    $inst -> { 'point' } ? '.' . $inst -> { 'point' } : '',
                                    $inst -> { 'domain' }
                                  )
    unless exists $inst -> { 'short5d' };

  $inst -> { 'short5d' };
}

=head2 fqfa

Full qualified FTN address:

  print $an -> fqfa; # mynet#2:456/33.0

=cut

sub fqfa {
  ref( my $inst = shift )
    or Carp::croak( "I'm only an object method!" );

  $inst -> { 'fqfa' } = sprintf( '%s#%d:%d/%d.%d',
                                 @{ $inst }{ qw/ domain zone net node point / }
                               )
    unless exists $inst -> { 'fqfa' };

  $inst -> { 'fqfa' };
}

=head2 bs

The Brake! FTN-compatible mailer for OS/2 style representation:

  print $an -> bs;   # mynet.2.456.33.0

=cut

sub bs {
  ref( my $inst = shift )
    or Carp::croak( "I'm only an object method!" );

  $inst -> { 'brake_style' } = sprintf( '%s.%d.%d.%d.%d',
                                        @{ $inst }{ qw/ domain zone net node point / }
                                      )
    unless exists $inst -> { 'brake_style' };

  $inst -> { 'brake_style' };
}

=head1 COMPARISON

=head2 equal, eq, cmp

Two addresses can be compared.

  ( my $one, $error ) = FTN::Addr -> new( '1:23/45.66@fidonet' );
  die "cannot create: " . $error
    if $error;

  my $two = FTN::Addr -> new( '1:23/45.66@fidonet' )
    or die "cannot create";

  print "the same address!\n"
    if FTN::Addr -> equal( $one, $two ); # should print the message

  print "the same address!\n"
    if $one eq $two;                   # the same result

  print "but objects are different\n"
    if $one != $two;           # should print the message

The same way (comparison rules) as 'eq' works 'cmp' operator.

=cut

sub _eq {                       # eq operator
  return
    unless $_[ 1 ]
    && ref $_[ 1 ]
    && Scalar::Util::blessed( $_[ 1 ] )
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
    && Scalar::Util::blessed( $_[ 1 ] )
    && $_[ 1 ] -> isa( 'FTN::Addr' );

  my ( $i, $j ) = ( 0, 1 );

  ( $i, $j ) = ( $j, $i )
    if $_[ 2 ];                 # arguments were swapped

  $_[ $i ] -> domain cmp $_[ $j ] -> domain
    || $_[ $i ] -> zone <=> $_[ $j ] -> zone
    || $_[ $i ] -> net <=> $_[ $j ] -> net
    || $_[ $i ] -> node <=> $_[ $j ] -> node
    || $_[ $i ] -> point <=> $_[ $j ] -> point;
}

sub equal {
  ref( my $class = shift )
    and Carp::croak( "I'm only a class method!" );

  return
    unless $_[ 0 ]
    && ref $_[ 0 ]
    && Scalar::Util::blessed( $_[ 0 ] )
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
