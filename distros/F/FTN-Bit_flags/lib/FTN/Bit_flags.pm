use strict;
use warnings;
use utf8;

package FTN::Bit_flags;
$FTN::Bit_flags::VERSION = '20160324';

use Log::Log4perl ();

=head1 NAME

FTN::Bit_flags - Object-oriented module for working with bit flags.

=head1 VERSION

version 20160324

=head1 SYNOPSIS

  use Log::Log4perl ();
  use FTN::Bit_flags ();

  Log::Log4perl -> easy_init( $Log::Log4perl::INFO );

  # let's work with message attributes
  my $attribute = FTN::Bit_flags -> new( { abbr => 'PVT',
					   name => 'PRIVATE',
					 },
					 { abbr => 'CRA',
					   name => 'CRASH',
					 },
					 { abbr => 'RCV',
					   name => 'READ',
					 },
					 { abbr => 'SNT',
					   name => 'SENT',
					 },
					 { abbr => 'FIL',
					   name => 'FILEATT',
					 },
					 { name => 'TRANSIT',
					 },
					 { name => 'ORPHAN',
					 },
					 { abbr => 'K/S',
					   name => 'KILL',
					 },
					 { name => 'LOCAL',
					 },
					 { abbr => 'HLD',
					   name => 'HOLD',
					 },
					 { abbr => 'XX2',
					 },
					 { abbr => 'FRQ',
					   abbr => 'FREQ',
					 },
					 { abbr => 'RRQ',
					   name => 'Receipt REQ',
					 },
					 { abbr => 'CPT',
					 },
					 { abbr => 'ARQ',
					 },
					 { abbr => 'URQ',
					 },
				       );

  $attribute -> set_from_number( get_attribute_from_message() );

  print join ', ', $attribute -> list_of_set;

  print 'this is a private message'
    if $attribute -> is_set( 'PVT' );

  # make sure it is local and its flavour is crash
  $attribute -> set( 'LOCAL', 'CRASH' );

  # though we don't need it to be killed after sent
  $attribute -> clear( 'K/S' );

  update_message_attribute_field( $attribute -> as_number );

  $attribute -> set_from_number( get_attribute_from_another_message() );

  # work with new attribute value the same way as above

=head1 DESCRIPTION

FTN::Bit_flags module is for working with bit flags commonly used in FTN messages.

=head1 OBJECT CREATION

=head2 new

  my $bit_flags = FTN::Bit_flags -> new( { abbr => 'flag 1' },
                                         { name => 'second lowest bit' },
                                         { abbr => 'flag 2',
                                           name => 'flag numeric mask is 4'
                                         }
                                       );

Parameters are hash references representing bit in order from low to high.  At least one parameter is required.
Each hash reference should have 'abbr' and/or 'name' fields.  Dies in case of error.

=cut

sub new {
  my $logger = Log::Log4perl -> get_logger( __PACKAGE__ );

  ref( my $class = shift ) and $logger -> logcroak( "I'm only a class method!" );

  my %self = ( abbr => {},
               name => {},
               list => [],
               value => 0,
             );

  $logger -> logdie( 'attribute list was not passed to constructor' )
    unless @_;

  for my $i ( 0 .. $#_ ) {
    $logger -> logdie( sprintf 'attribute # %d is not a hashref',
                       $i,
                     )
      unless defined $_[ $i ]
      && ref $_[ $i ] eq 'HASH';

    $logger -> logdie( sprintf 'attribute # %d misses abbr and/or name',
                       $i,
                     )
      unless exists $_[ $i ]{abbr}
      || exists $_[ $i ]{name};

    my @new_to_list;

    for my $f ( [ abbr => 0 ],
                [ name => 1 ],
              ) {
      next unless exists $_[ $i ]{ $f -> [ 0 ] };

      my $val = $_[ $i ]{ $f -> [ 0 ] };
      $logger -> logdie( sprintf 'attribute # %d has undefined %s',
                         $i,
                         $f -> [ 0 ],
                       )
        unless defined $val;

      $logger -> logdie( sprintf 'attribute with %s %s is already defined',
                         $f -> [ 0 ],
                         $val,
                       )
        if exists $self{ $f -> [ 0 ] }{ $val };

      $new_to_list[ $f -> [ 1 ] ] = $val;
      $self{ $f -> [ 0 ] }{ $val } = 1 << $i;
    }

    if ( exists $_[ $i ]{descr} ) {
      my $descr = $_[ $i ]{descr};
      $logger -> logdie( sprintf 'attribute # %d has undefined description',
                         $i,
                       )
        unless defined $descr;

      $new_to_list[ 2 ] = $descr;
    }

    push @{ $self{list} }, \ @new_to_list;
  }

  bless \ %self, $class;
}

=head2 set_from_number

After object describing all possible fields is created we can use it to work with already defined value:

  $bit_flags -> set_from_number( 3 );

=cut

sub set_from_number {
  my $logger = Log::Log4perl -> get_logger( __PACKAGE__ );

  ref( my $self = shift ) or $logger -> logcroak( "I'm only an object method!" );

  $logger -> logdie( 'no value was passed to set from number' )
    unless @_;

  $logger -> logdie( sprintf 'incorrect numeric value: %s',
                     defined $_[ 0 ] ? $_[ 0 ] : 'undef',
                   )
    unless defined $_[ 0 ]
    && $_[ 0 ] =~ m/^\d+$/;

  # let's check that it is not bigger than we have attributes
  $logger -> logdie( sprintf 'numeric value is too big %d',
                     $_[ 0 ],
                   )
    if $_[ 0 ] >> @{ $self -> {list} };

  $self -> {value} = $_[ 0 ];

  $self;
}

=head2 clear_all

We can clear all bitfields (setting numeric value to 0):

  $bit_flags -> clear_all;

=cut

sub clear_all {
  my $logger = Log::Log4perl -> get_logger( __PACKAGE__ );

  ref( my $self = shift ) or $logger -> logcroak( "I'm only an object method!" );

  $self -> {value} = 0;

  $self;
}

=head2 set

To set one (or more) fields:

  $bit_flags -> set( 'second lowest bit', 'flag 2' );

If you have equal 'abbr' for one field and 'name' for another field, then 'abbr' has higher priority here.

=cut

sub set {
  my $logger = Log::Log4perl -> get_logger( __PACKAGE__ );

  ref( my $self = shift ) or $logger -> logcroak( "I'm only an object method!" );

  $logger -> logdie( 'no attribute abbr/name was passed to set' )
    unless @_;

  for my $i ( 0 .. $#_ ) {
    my $t = $_[ $i ];
    $logger -> logdie( sprintf 'passed attribute abbr/name to be set with index %d is undefined',
                       $i,
                     )
      unless defined $t;

    if ( exists $self -> {abbr}{ $t } ) {
      $self -> {value} |= $self -> {abbr}{ $t };
    } elsif ( exists $self -> {name}{ $t } ) {
      $self -> {value} |= $self -> {name}{ $t };
    } else {
      $logger -> logdie( sprintf 'unknown abbr/name %s was passed to set',
                         $t,
                       );
    }
  }

  $self;
}

=head2 clear

To clear one (or more) fields:

  $bit_flags -> clear( 'second lowest bit' );

If you have equal 'abbr' for one field and 'name' for another field, then 'abbr' has higher priority here.

=cut

sub clear {
  my $logger = Log::Log4perl -> get_logger( __PACKAGE__ );

  ref( my $self = shift ) or $logger -> logcroak( "I'm only an object method!" );

  $logger -> logdie( 'no attribute abbr/name was passed to clear' )
    unless @_;

  for my $i ( 0 .. $#_ ) {
    my $t = $_[ $i ];
    $logger -> logdie( sprintf 'passed attribute abbr/name to be cleared with index %d is undefined',
                       $i,
                     )
      unless defined $t;

    if ( exists $self -> {abbr}{ $t } ) {
      $self -> {value} &= ~ $self -> {abbr}{ $t };
    } elsif ( exists $self -> {name}{ $t } ) {
      $self -> {value} &= ~ $self -> {name}{ $t };
    } else {
      $logger -> logdie( sprintf 'unknown abbr/name %s was passed to clear',
                         $t,
                       );
    }
  }

  $self;
}

=head2 is_set

To check if some field is set:

  print 'it is set'
    if $bit_flags -> is_set( 'second lowest bit' );

If you have equal 'abbr' for one field and 'name' for another field, then 'abbr' has higher priority here.

=cut

sub is_set {
  my $logger = Log::Log4perl -> get_logger( __PACKAGE__ );

  ref( my $self = shift ) or $logger -> logcroak( "I'm only an object method!" );

  $logger -> logdie( 'no attribute abbr/name was passed to check if it is set' )
    unless @_;

  my $t = shift;

  $logger -> logdie( 'passed attribute abbr/name to check if it is set is undefined' )
    unless defined $t;

  if ( exists $self -> {abbr}{ $t } ) {
    $self -> {value} & $self -> {abbr}{ $t };
  } elsif ( exists $self -> {name}{ $t } ) {
    $self -> {value} & $self -> {name}{ $t };
  } else {
    $logger -> logdie( sprintf 'unknown abbr/name %s was passed to check if it is set',
                       $t,
                     );
  }
}

=head2 as_number

To get numeric value after you set or cleared some flags:

  print $bit_flags -> as_number;

=cut

sub as_number {
  my $logger = Log::Log4perl -> get_logger( __PACKAGE__ );

  ref( my $self = shift ) or $logger -> logcroak( "I'm only an object method!" );

  $self -> {value};
}

=head2 list_of_set

To get list of set flags:

  print join ' ', $bit_flags -> list_of_set;

By default it tries to return 'abbr' field value for each set bit and if there is none, then return 'name' field value.  If 'name' field is preferable, pass optional parameter 'name'.

  print join ' ', $bit_flags -> list_of_set( 'name' );

=cut

sub list_of_set {
  my $logger = Log::Log4perl -> get_logger( __PACKAGE__ );

  ref( my $self = shift ) or $logger -> logcroak( "I'm only an object method!" );

  my @res;

  my $prefer_abbr = ! ( @_ && defined $_[ 0 ] && $_[ 0 ] eq 'name' );

  for my $b ( @{ $self -> {list} } ) {
    my $a;
    my $v;
    if ( $prefer_abbr ) {
      $a = defined $b -> [ 0 ] ? $b -> [ 0 ] : $b -> [ 1 ];
      $v = defined $b -> [ 0 ] ?
        $self -> {abbr}{ $b -> [ 0 ] }
        : $self -> {name}{ $b -> [ 1 ] };
    } else {
      $a = defined $b -> [ 1 ] ? $b -> [ 1 ] : $b -> [ 0 ];
      $v = defined $b -> [ 1 ] ?
        $self -> {name}{ $b -> [ 1 ] }
        : $self -> {abbr}{ $b -> [ 0 ] };
    }

    push @res, $a
      if $self -> {value} & $v;
  }

  wantarray ?
    @res
    : \ @res;
}

1;

=head1 AUTHOR

Valery Kalesnik, C<< <valkoles at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-ftn-bit_flags at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=FTN-Bit_flags>.
I will be notified, and then you'll automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

  perldoc FTN::Bit_flags

=cut

__END__
new( { name =>
       abbr =>
       descr =>
     },
   )

# clear_all # zeroes all bits
# set_from_number( number ) parses number to bits and stores the result
# set( list of name/abbr )
# clear( list of name/abbr )
# is_set( name/abbr )
# as_number
# list_of_set( abbr/name ); # optional arg says what is preffered.  by default it is abbr
