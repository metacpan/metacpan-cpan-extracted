package Labyrinth::Filters;

use warnings;
use strict;

use vars qw( $VERSION $AUTOLOAD @ISA %EXPORT_TAGS @EXPORT_OK @EXPORT );
$VERSION = '5.32';

=head1 NAME

Labyrinth::Filters - Basic Filters Handler for Labyrinth

=head1 DESCRIPTION

Provides basic filter methods used within Labyrinth.

=cut

# -------------------------------------
# Export Details

require Exporter;
@ISA       = qw(Exporter);
%EXPORT_TAGS = (
    'all' => [ qw( float2 float3 float5 ) ]
);

@EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
@EXPORT    = ( @{ $EXPORT_TAGS{'all'} } );

#----------------------------------------------------------------------------
# Libraries

use Labyrinth::Audit;
use Labyrinth::Variables;

#----------------------------------------------------------------------------
# Subroutines

sub float2 { return _filter_float( @_, "%.2f" ) }
sub float3 { return _filter_float( @_, "%.3f" ) }
sub float5 { return _filter_float( @_, "%.5f" ) }

sub filter_float2 { return _filter_float( @_, "%.2f" ) }
sub filter_float3 { return _filter_float( @_, "%.3f" ) }
sub filter_float5 { return _filter_float( @_, "%.5f" ) }

sub _filter_float {
    my ($value,$pattern) = @_;
    return  unless(defined $value);

#LogDebug("filter:value=$value, pattern=$pattern");
    my ($num) = $value =~ m< ^ ([\d.]+) $ >x;
    return  unless(defined $num);

#LogDebug("filter:num=$num, val=" . ( sprintf $pattern, $num ));
    return sprintf $pattern, $num;
}

#----------------------------------------------------------------------------

sub AUTOLOAD {
    my $name = $AUTOLOAD;

    no strict qw/refs/;

    my ($num) = $name =~ m/^.*:(?:filter_)?float(\d+)/;

    return  unless(defined $num);

    my $fmt = '%.' . $num . 'f';
    return _filter_float( @_, $fmt )
}

1;

__END__

=head1 FUNCTIONS

=head2 Filters

=over 4

=item float2
=item float3
=item float5

Basic filters for 2, 3 and 5 decimal places.

=item filter_float2
=item filter_float3
=item filter_float5

DFV named filters for 2, 3 and 5 decimal places.

=back

=head1 SEE ALSO

  Labyrinth

=head1 AUTHOR

Barbie, <barbie@missbarbell.co.uk> for
Miss Barbell Productions, L<http://www.missbarbell.co.uk/>

=head1 COPYRIGHT & LICENSE

  Copyright (C) 2002-2015 Barbie for Miss Barbell Productions
  All Rights Reserved.

  This module is free software; you can redistribute it and/or
  modify it under the Artistic License 2.0.

=cut
