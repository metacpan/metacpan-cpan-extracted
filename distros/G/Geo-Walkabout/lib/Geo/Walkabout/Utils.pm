package Geo::Walkabout::Utils;

use strict;
use vars qw($VERSION);
use base qw(Geo::Walkabout::Class::DBI);

use Geo::Walkabout::Line;
use Geo::Walkabout::Chain;
use Carp::Assert;

=pod

=head1 NAME

Geo::Walkabout::Utils - Utility functions for Geo::Walkabout.


=head1 DESCRIPTION

These are functions I'm playing around with.  Most likely they will be
broken up into other libraries and reworked, so don't be surprised if
all this changes.

=head2 Functions

=over 4

=item B<find_address>

  my $line = find_address({fedirp       => $dirp,
                           fename       => $name,
                           fetype       => $type,
                           fedirs       => $dirs,

                           addr_num     => $num,
                           zip          => $zip,
                          });

Finds a line feature from its name and zip.  (Eventually city and
state instead of zip).

B<NOTE> fedirs and fedirp are currently ignored.

=cut

# The % 2 mess is to find the right side of the street.
# The %% is because this is a sprintf string.
__PACKAGE__->set_sql('Find_Address', <<SQL);
SELECT  %s
FROM    %s L, Address_Range A
WHERE   L.TLID = A.TLID         AND
        FeName = ?              AND
        FeType = ?              AND
        (ZipL = ? OR ZipR = ?)  AND
        ((Start_Addr < ? AND ? < End_Addr) OR
         (End_Addr   < ? AND ? < Start_Addr))   AND
        Start_Addr %% 2 = ? %% 2
SQL

sub find_address {
    my($address) = shift;

    my @line_cols = Geo::TigerLine::Line->columns('Essential');
    my $sth;
    eval {
        $sth = __PACKAGE__->sql_Find_Address(
                       join(', ', map { "L.$_" } @line_cols),
                       Geo::TigerLine::Line->table
                      );
        $sth->execute($address->{fename},
                      $address->{fetype},
                      ($address->{zip}) x 2,
                      ($address->{addr_num}) x 5
                     );
    };
    if($@) {
        Geo::Walkabout::Utils->DBIwarn('Find_Address', $address->{addr_num});
        return;
    }
    
    my $line_data = $sth->fetch_hash;
    assert(!defined $line_data || !$sth->fetch);
    $sth->finish;

    if( defined $line_data ) {
        return Geo::TigerLine::Line->construct($line_data);
    }
    else {
        return;
    }
}

=pod

=item B<in_range>

  my @lines = in_range([$long, $lat], $range);

Returns all line features in a circular $range of the given point
($long, $lat).

=cut

__PACKAGE__->set_sql('In_Range', <<SQL);
SELECT  %s
FROM    %s
WHERE   Chain_Start @ ?::circle         OR
        Chain_End   @ ?::circle
SQL

sub in_range {
    my($point, $range) = @_;

    my $pg_point = Geo::TigerLine::Chain->to_pgpoint($point);
    my $pg_circle = "($pg_point, $range)";

    my $sth;
    eval {
        $sth = __PACKAGE__->sql_In_Range(
                    join(', ', Geo::TigerLine::Line->columns('Essential')),
                    Geo::TigerLine::Line->table
                   );
        $sth->execute(($pg_circle) x 2);
    };
    if( $@ ) {
        __PACKAGE__->DBIwarn('In_Range', $pg_point);
        return;
    }

    my @lines = ();
    while( my $line_data = $sth->fetch_hash ) {
        push @lines, Geo::TigerLine::Line->construct($line_data);
    }
        
    return @lines;
}

=pod

=item B<get_line_feature>

  my @feature = get_line_feature({
                                  fedirp => $fedirp,
                                  fename => $fename,
                                  fetype => $fetype,
                                  fedirs => $fedirs,

                                  zip    => $zip,
                                 }); 

Returns all connected line features of the feature which passes
through the given zip code.

B<NOTE> I don't think this quite gets the entire road.

B<NOTE> zip, fedirp and fedirs are currently ignored.

=cut

#'#
__PACKAGE__->set_sql('Get_Line_Feature', <<SQL);
SELECT  %s
FROM    %s L1, %s L2
WHERE   L1.FeName = ?           AND
        L2.FeName = ?           AND
        L1.FeType = ?           AND
        L2.FeType = ?           AND
        L1.Chain_Start ~= L2.Chain_End
SQL

sub get_line_feature {
    my($address) = shift;

    my @line_cols = Geo::TigerLine::Line->columns('Essential');

    my $sth;
    eval {
        $sth = __PACKAGE__->sql_Get_Line_Feature(
                               join(', ', map { "L1.$_" } @line_cols),
                               (Geo::TigerLine::Line->table) x 2
                              );
        $sth->execute(($address->{fename}) x 2,
                      ($address->{fetype}) x 2
                     );
    };
    if( $@ ) {
        __PACKAGE__->DBIwarn('Get_Line_Feature', 
                             "$address->{fename} $address->{fetype}");
        return;
    }

    my @feature = ();
    while(my $line_data = $sth->fetch_hash) {
        push @feature, Geo::TigerLine::Line->construct($line_data);
    }

    return @feature;
}

=pod

=item B<get_zip>

  my @lines = get_zip($zip);

Get all lines in a given zip code.

=cut

__PACKAGE__->set_sql('Get_Zip', <<SQL);
SELECT  %s
FROM    %s
WHERE   ZipL = ?        OR
        ZipR = ?
SQL


sub get_zip {
    my($zip) = @_;

    my $sth;
    my @line_cols = Geo::TigerLine::Line->columns('Essential');
    eval {
        $sth = __PACKAGE__->sql_Get_Zip(
                                        join(', ', @line_cols),
                                        Geo::TigerLine::Line->table
                                       );

        $sth->execute(($zip) x 2);
    };
    if( $@ ) {
        __PACKAGE__->DBIwarn('Get_Zip', $zip);
        return;
    }

    my @lines = ();
    while( my $line_data = $sth->fetch_hash ) {
        push @lines, Geo::TigerLine::Line->construct($line_data);
    }

    return @lines;
}

=pod

=item B<bounding_box>

  my $box = bounding_box_zip($zip);

Returns the two point box bounding this zip code.  $box->[0]
upper-right, $box->[1] is lower-left.

=cut

__PACKAGE__->set_sql('Bounding_Zip', <<SQL);
SELECT  box(polygon(pclose(Chain)))
FROM    %s
WHERE   ZipL = ?        OR
        ZipR = ?
SQL


sub bounding_box_zip {
    my($zip) = @_;

    my $sth;
    eval {
        $sth = __PACKAGE__->sql_Bounding_Zip(Geo::TigerLine::Line->table);
        $sth->execute(($zip) x 2);
    };
    if( $@ ) {
        __PACKAGE__->DBIwarn('Bounding_Zip', $zip);
        return;
    }

    my @bound_box;
    while(my($pgbox) = $sth->fetch) {
        my $box = from_pgbox($pgbox);

        # XXX puke
        if( !defined $bound_box[0][0] ||
            $box->[0][0] > $bound_box[0][0] )
        {
            $bound_box[0][0] = $box->[0][0];
        }
        
        if( !defined $bound_box[0][1] ||
            $box->[0][1] > $bound_box[0][1] )
        {
            $bound_box[0][1] = $box->[0][1];
        }

        if( !defined $bound_box[1][0] ||
            $box->[1][0] < $bound_box[1][0] )
        {
            $bound_box[1][0] = $box->[1][0];
        }

        if( !defined $bound_box[1][1] ||
            $box->[1][1] < $bound_box[1][1] )
        {
            $bound_box[1][1] = $box->[1][1];
        }
    }

    return \@bound_box;
}


sub from_pgbox {
    my($pg_box) = shift;

    my @box = ();
    # XXX Unifty with _split_pg_path
    while( $pg_box =~ / \( \s* ([-\d\.]+) \s* , 
                           \s* ([-\d\.]+) \s* \) 
                      /gx ) 
    {
        push @box, [$1,$2];
    }
 
    assert(@box == 2);
   
    return \@box;
}

=pod

=item B<find_intersection>

  @lines = find_intersection({fename => $fe_name,
                              fetype => $fe_type,
                             },
                             {fename => $fe_name,
                              fetype => $fe_type,
                             },
                             $zip
                            );

Finds the given cross-street, returning all lines which share in this
intersection.

=cut

__PACKAGE__->set_sql('Find_Intersection', <<SQL);
SELECT  %s, %s
FROM    %s L1, %s L2
WHERE   (L1.FeName = ?  AND L1.FeType = ?)      AND
        (L2.FeName = ?  AND L2.FeType = ?)      AND
        (L1.Chain_Start ~= L2.Chain_Start       OR
         L1.Chain_End   ~= L2.Chain_End)
SQL


sub find_intersection {
    my($line1, $line2, $zip) = @_;

    my @line_cols = Geo::Walkabout::Line->columns('Essential');
    my $line_table = Geo::Walkabout::Line->table;

    my $sth;
    eval {
        $sth = __PACKAGE__->sql_Find_Intersection(
                                       join(", ", map { "L1.$_" } @line_cols),
                                       join(", ", map { "L2.$_" } @line_cols),
                                       ($line_table) x 2
                                      );
        $sth->execute($line1->{fename}, $line1->{fetype},
                      $line2->{fename}, $line2->{fetype}
                     );
    };
    if( $@ ) {
        __PACKAGE__->DBIwarn("find_intersection", 
                             "$line1->{fename}, $line2->{fename}");
        return;
    }

    my @lines = ();
    while( my @line_data = $sth->fetchrow_array ) {
        # @line_data contains the info for two lines.
        assert( @line_data == @line_cols * 2 ) if DEBUG;

        for my $line_data ([@line_data[0..$#line_data/2]], 
                           [@line_data[$#line_data/2+1..$#line_data]])
        {
            push @lines, Geo::Walkabout::Line->construct({
                             map { $line_cols[$_] => $line_data->[$_] } 
                                 0..$#line_cols
                            });
        }
    }

    return @lines;
}
    

=pod

=head1 AUTHOR

Michael G Schwern <schwern@pobox.com>

=cut

1;
