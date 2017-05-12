# $Id: Line.pm,v 1.1.1.1 2000/12/05 00:55:01 schwern Exp $

# Somebody's going to want to graft this thing to another database.
# May as well plan for it.
package Geo::Walkabout::Line;
@ISA = qw(Geo::Walkabout::Line::PostgreSQL);


package Geo::Walkabout::Line::PostgreSQL;

use strict;
use vars qw($VERSION);

$VERSION = '0.01';

use base qw(Geo::Walkabout::Class::DBI);

require Geo::Walkabout::Chain;
use Carp::Assert;

__PACKAGE__->table('Line_Feature');

__PACKAGE__->columns(Primary    => 'TLID');
__PACKAGE__->columns(Essential  => qw( TLID FeName Chain ));

__PACKAGE__->columns(Feature    => qw( FeDirP FeName FeType FeDirS ));
__PACKAGE__->columns(Zip        => qw( ZipL Zip4L ZipR Zip4R ));
__PACKAGE__->columns(Chain      => qw( Chain_Start Chain_End Chain 
                                       Chain_Length));


=pod

=head1 NAME

Geo::Walkabout::Line - A "line feature"


=head1 SYNOPSIS

  require Geo::Walkabout::Line;

  my $line = Geo::Walkabout::Line->retrieve($tlid);
  my $line = Geo::Walkabout::Line->new(\%data);

  $line->delete;

  my $id   = $line->id;
  my $name = $line->name;

  my($zip_left, $zip_right) = $line->zip;

  my @address_ranges = $line->addresses_left;
  my @address_ranges = $line->addresses_right;
  $line->add_addresses($side, @address_ranges);

  my $chain = $line->chain;

  $line->TLID;

  $line->FeDirP;
  $line->FeName;
  $line->FeType;
  $line->FeDirS;

  $line->ZipL;
  $line->Zip4L;
  $line->ZipR;
  $line->Zip4R;

  $line->commit;
  $line->rollback;


=head1 DESCRIPTION

This represents a complete "line feature".  Roads, waterways, fences,
power lines, railroads, boundries...  See chapter 3 of the TIGER/Line
documentation for details.


=head1 Public Methods

=head2 Constructors and Destructors

Geo::Walkabout::Line is a subclass of Class::DBI and expects to be
stored in a database.

=over 4

=item B<retrieve>

  my $line = Geo::Walkabout::Line->retrieve($id);

Retrieve an existing line feature from the database by its ID.

=item B<new>

  my $line = Geo::Walkabout::Line->new(\%data);

Create a new line feature.  %data must contain the following fields...

    TLID        Unique TIGER/Line ID
    Chain       A Geo::Walkabout::Chain object representing the line

And optionally contain these...

    FeDirP      See accessor descriptions below
    FeName      for what these are
    FeType
    FeDirS

    ZipL
    Zip4L
    ZipR
    Zip4R

=cut

sub new {
    my($proto, $data) = @_;

    assert( $data->{Chain}->isa('Geo::Walkabout::Chain') ) if DEBUG;
    my $chain_obj = $data->{Chain};
    $data->{Chain} = $data->{Chain}->as_pgpath;
    $data->{Chain_Start} = $chain_obj->to_pgpoint($chain_obj->begin);
    $data->{Chain_End}   = $chain_obj->to_pgpoint($chain_obj->end);

    # Blank values translate to null values.
    foreach my $key (keys %$data) {
        $data->{$key} = undef unless length $data->{$key};
    }

    my $self = $proto->SUPER::new($data);

    $self->{chain_obj} = $chain_obj;

    return $self;
}

=pod

=item B<delete>

  $line->delete;

Deletes this line feature from the database B<permanently>.

=back


=head2 Accessors

=over 4


=item B<id>

  my $id = $line->id

Returns a unique ID for this object, not necessarily the same as TLID.

B<NOTE> Do I<NOT>, I repeat, do I<NOT> use attempt to use the TLID as
a unique identifer for a Geo::Walkabout::Line object.  While the TLID is
unique, it is not guaranteed that all Geo::Walkabout::Line objects will
have one.  Geo::Walkabout::Line objects will come from many sources.

=item B<TLID>

  my $tlid = $line->TLID;

Returns the TIGER/Line ID for this object.


=item B<name>

  my $name = $line->name;

The complete name of this feature.  Its roughly equivalent to:

  my $name = join ' ', $line->FeDirP, $line->FeName, $line->FeType, 
                       $line->FeDirS;

For example:  "Elford PL"

=cut

sub name {
    my($self) = shift;

    my @name = ($self->FeDirP, $self->FeName, $self->FeType, $self->FeDirS);
    return join ' ', grep { defined && length } @name;
}

=pod

=item B<zip>

  my($zip_left, $zip_right) = $line->zip;

The zip code for the left and right side of this line.  Zip may be the
5 digit zip code or the 9 digit zip +4.

=cut

sub zip {
    my($self) = shift;

    my $zip4L = $self->Zip4L;
    my $zip4R = $self->Zip4R;

    my($zip_left, $zip_right);

    $zip_left = sprintf "%05d", $self->ZipL;
    $zip_left .= sprintf "%04d", $zip4L if defined $zip4L;

    $zip_right = sprintf "%05d", $self->ZipR;
    $zip_right .= sprintf "%04d", $zip4R if defined $zip4R;
    

    return($zip_left, $zip_right);
}

=pod

=item B<addresses_left>

=item B<addresses_right>

  my @address_ranges = $line->addresses_left;
  my @address_ranges = $line->addresses_right;

The possible addresses on the left side of this line.  @address_ranges
is a list of range pairs (two element array refs).  A range with the
same start and end number (such as [146,146]) represents a single
anomalous address.

The order is meaningless.

For example:

    # Represents that the addresses descend from 290 to 200 from the
    # start of the line to the end.  There is also a single outstanding
    # address #146 and an additional range of addresses from 20 to 10.
    # So 10-20, 146 and 200-290.
    ([290,200],[146,146],[20,10])

=cut

sub addresses_left {
    my($self) = shift;

    $self->_get_addresses unless defined $self->{addresses}{L};

    return @{$self->{addresses}{L}};
}

sub addresses_right {
    my($self) = shift;

    $self->_get_addresses unless defined $self->{addresses}{L};

    return @{$self->{addresses}{R}};
}

__PACKAGE__->set_sql('GetAddresses', <<SQL);
SELECT  Start_Addr, End_Addr, Side
FROM    Address_Range
WHERE   TLID = ?
SQL

sub _get_addresses {
    my($self) = shift;

    my $sth;
    my($from, $to, $side);  # bind columns.
    eval {
        $sth = $self->sql_GetAddresses;
        $sth->execute([$self->id], [\($from, $to, $side)]);
    };
    if($@) {
        $self->DBIwarn($self->id, '_get_addresses');
        return;
    }

    $self->{addresses}{L} = [];
    $self->{addresses}{R} = [];
    while( $sth->fetch ) {
        push @{$self->{addresses}{uc $side}}, [$from, $to];
    }

    $sth->finish;
}

=pod

=item B<add_addresses>

  $line->add_addresses($side, @address_ranges);

Addes a new address range to this line on the given $side.  $side is
either 'R' or 'L'.  @address_range is a list of two element array
references representing possible addresses on that side of the street.
The ordering is from the start of the chain to the end.

=cut

__PACKAGE__->set_sql('AddAddress', <<SQL);
INSERT INTO Address_Range
       (TLID, Start_Addr, End_Addr, Side)
VALUES (?,    ?,          ?,        ?   )
SQL


sub add_addresses {
    my($self, $side, @address_ranges) = @_;

    assert($side eq 'R' or $side eq 'L') if DEBUG;

    my $sth;
    $sth = $self->sql_AddAddress;
    foreach my $address_range (@address_ranges) {
        assert(@$address_range == 2) if DEBUG;
        
        eval {
            $sth->execute($self->id, @{$address_range}, $side);
        };
        if ($@) {
            $self->DBIwarn($self->id, 'add_address');
            return;
        }
    }

    $sth->finish;
}

=pod

=item B<chain>

  my $chain = $line->chain;
  $line->chain($chain);

The Geo::Walkabout::Chain object representing the shape of this line
feature.  This is the important bit, the line's actual location in the
world.  L<Geo::Walkabout::Chain> for details.

=cut

#'#
sub chain {
    my($self) = shift;
    my($chain) = @_;

    if(@_) {
        Carp::carp("This is not a Geo::Walkabout::Chain object")
          unless $chain->isa("Geo::Walkabout::Chain");
        $self->{chain_obj} = $chain;
        $self->_Chain_accessor($chain->as_pgpath);
    }
    
    unless( defined $self->{chain_obj} ) {
        $self->{chain_obj} = 
          Geo::Walkabout::Chain->new_from_pgpath($self->_Chain_accessor);
    }

    return $self->{chain_obj};
}

=pod

=item B<FeDirP>

  my $fedirp = $line->FeDirP;
  $line->FeDirP($fedirp);

Feature Direction Prefix.  For example, if you had "North Southington
Road", "N" would be the FeDirP.

Possible values are "N", "NE", "NW", "S", "SE", "SW", "E", "W", "EX".
"EX" means "Extended" or "Extension".

=cut

sub FeDirP {
    my($self) = shift;
    my($fedirp) = @_;

    if(@_ and !_valid_fedir($fedirp)) {
        Carp::carp("'$fedirp' is not a valid feature direction.");
    }

    $self->_FeDirP_accessor(@_);
}

sub _valid_fedir {
    my($fedir) = shift;

    return $fedir =~ /^(?:N[EW]?|S[EW]?|E[X]?|W)$/;
}

=pod

=item B<FeName>

  my $fename = $line->FeName;
  $line->FeName($fename);

Feature Name.  Continuing the example, "Southington" is the FeName.


=item B<FeType>

  my $fetype = $line->FeType;
  $line->FeType($fetype);

Feature Type.  "Rd" would be the feature type from above.  Standard
abbreviations can be found in Appendix D of the TIGER/Line
documentation.


=item B<FeDirS>

  my $fedirs = $line->FeDirS;
  $line->FeDirS($fedirs);

Feature Type Suffix.  Same as FeDirP, except it follows the feature
name.  So for "Red Rock West", the FeDirS would be "W".

=cut

sub FeDirS {
    my($self) = shift;
    my($fedirs) = @_;

    if(@_ and !_valid_fedir($fedirs)) {
        Carp::carp("'$fedirs' is not a valid feature direction.");
    }

    $self->_FeDirS_accessor(@_);
}

=pod

=item B<ZipL>

=item B<ZipR>

  my $zipl = $line->ZipL;
  $line->ZipL($zipl);
  my $zipr = $line->ZipR;
  $line->ZipR($zipr);

5 digit zip codes for the left and right side of this line.

=item B<Zip4L>

=item B<Zip4R>

  my $zip4l = $line->Zip4L;
  $line->Zip4L($zip4l);
  my $zip4r = $line->Zip4R;
  $line->Zip4R($zip4r);

4 digit +4 zip code extension for the left and right side of this line.


=back

=head2 Other Methods

=over 4

=item B<commit>

  $line->commit;

Commit changes made to this line to the database.

=cut

sub commit {
    my($self) = shift;

    $self->_Chain_accessor($self->chain->as_pgpath);

    $self->SUPER::commit;
}

=pod

=item B<rollback>

  $line->rollback;

Throw away changes made to this line and refresh it from the database.
If an object is changed and destroyed without committing or rolling
back a warning will be thrown.

=back


=head1 AUTHOR

Michael G Schwern <schwern@pobox.com>


=head1 SEE ALSO

L<Geo::Walkabout>, L<Geo::TigerLine>, L<Geo::Walkabout::Chain>

=cut

1;
