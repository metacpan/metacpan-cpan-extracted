package List::Util::WeightedChoice;

use 5.006000;
use strict;
use warnings;

use Carp qw(croak);
require Exporter;
use AutoLoader qw(AUTOLOAD);
use Params::Validate qw(:all);


our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use List::Util::WeightedChoice ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
   choose_weighted
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

our $VERSION = '0.06';



sub choose_weighted{
     validate_pos(@_, 
		  { type => ARRAYREF },
		  { type => CODEREF | ARRAYREF}
 	);

    my ($objects, $weightsArg ) = @_;
    my $calcWeight = $weightsArg if 'CODE' eq ref $weightsArg;
    my @weights;		# fix wasteful of memory
    if( $calcWeight){
	@weights =  map { $calcWeight->($_) } @$objects; 
    }
    else{
	@weights =@$weightsArg;
	if ( @$objects != @weights ){
	    croak "given arefs of unequal lengths!";
	}
    }

    my @ranges = ();		# actually upper bounds on ranges
    my $left = 0;
    for my $weight( @weights){
	$weight = 0 if $weight < 0; # the world is hostile...
	my $right = $left+$weight;
	push @ranges, $right;
	$left = $right;
    }
    my $weightIndex = rand $left;
    for( my $i =0; $i< @$objects; $i++){
	my $range = $ranges[$i];
	return $objects->[$i] if $weightIndex < $range;
    }
}


# Preloaded methods go here.

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

List::Util::WeightedChoice - Perl extension to allow for nonnormalized weighted choices

=head1 SYNOPSIS

  use List::Util::WeightedChoice qw( choose_weighted );
  my $choices = ['Popular', 'Not so much', 'Unpopular'];
  my $weights = [ 50, 25, 1] ;
  my $choice = choose_weighted( $choices, $weights );


  my $complexChoices = [ 
    {val=>"Not so much", weight=>2},
    {val=>"Popular", weight=>50},
    {val=>"Unpopular", weight=>1},
    ];

  $choice = choose_weighted($complexChoices, sub{ $_[0]->{weight} } );


=head1 DESCRIPTION

Just one function, a simple means of making a weighted random choice

The implementation uses rand to calculate random numbers.

=head2 EXPORT

None by default.


=head3 choose_weighted

 choose_weighted ($object_Aref, $weights_Aref )

or 
 choose_weighted ($object_Aref, $weights_codeRef )

In the second case, the coderef is called on each object to determine its weight;

=head1 SEE ALSO

List::Util

=head1 CAVEATS


TODO: object-oriented module to implement fast re-picks with binary searches.

OO-interface ought to allow for other sources of randomness;
 
This currently does a linear search to find the winner.  It could be made faster

=head1 AUTHOR

Danny Sadinoff, <lt>danny-cpan@sadinoff.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by Danny Sadinoff

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.


=cut
