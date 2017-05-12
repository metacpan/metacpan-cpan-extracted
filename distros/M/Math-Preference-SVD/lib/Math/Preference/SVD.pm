#!/usr/bin/perl

package Math::Preference::SVD;

use strict;
use warnings;

no AutoLoader;

our $VERSION = '0.01';

require XSLoader;
XSLoader::load('Math::Preference::SVD', $VERSION);

sub new {
    my $class = shift;
    bless { @_ }, $class;
}

# sub set_rating {
#     # doing just one would be tricky... have to figure out if the movie has already been seen and add it if not
#     # customers add themselves as necessary I think
#     my $self = shift;
# }

sub set_ratings {
    my $self = shift;
    my $ratings = shift;   # array of arrays, each of those having customer_id, movie_id (or, in general, id of the thing rated), rating
    my @ratings = @{ $ratings };
    my $max_movie_id = 0;
    my $max_customer_id = 0;
    my $max_rating_id = 0;

    @ratings = sort { $a->[1] <=> $b->[1] } @ratings; # sort by movie
    $max_movie_id = $ratings[-1]->[1];

    for my $rating ( @ratings ) {
        die unless ref $rating eq 'ARRAY';
        (my $custId, my $movieId, my $rating) = @{ $rating };
        defined $custId or die;
        defined $movieId or die;
        defined $rating or die;
        $max_customer_id = $custId if $custId > $max_customer_id;
        $max_rating_id++;
    }
warn "totals calced: customers: @{[ $max_customer_id + 1 ]}  ratings: $max_rating_id  movies: @{[ $max_movie_id + 1 ]}";
    Engine($max_customer_id+1, $max_rating_id, $max_movie_id+1);

    my $last_movie_id = -1;
    for my $rating ( @ratings ) {
        (my $custId, my $movieId, my $rating) = @{ $rating };
        if( $last_movie_id != $movieId ) {
            set_Movies($movieId, 0, 0); # RatingCount = 0, RatingSum = 0
            $last_movie_id = $movieId;
        }
        set_Ratings($movieId, $custId, $rating); 
    }

warn "calc metrics...";

    CalcMetrics();

warn "calc features...";

    CalcFeatures();

warn "processed";

}

sub predict_rating {
    my $self = shift;
    my $movieId = shift;
    my $custId = shift;
    PredictRating($movieId, $custId);
}

1;

__END__

NOTES:

You may have something there about this 'original order' stuff. Because in my verbatim implementation of TD's C++ source, the only difference is in the reading of the data which is not in your so called 'original order'. And this could explain why I'm not getting below 0.9400 This makes this whole SVD approach even spookier than I thought.
And the only place in the code where this could happen is in the 1-5 clipping - which is an area that I have always been very suspicious of, i.e. if it happens too often for a particular user[feature,custid] or movie[feature,movid] then the final result of 5 or 1 could be pretty meaningless.
When I have a chance I'll run some statistics on this clipping phenomena.

Suggested Reading
Wikipedia

    * Collaborative Filtering
    * Correlation
    * Singular Value Decomposition (SVD)
    * Principal Components Analysis (PCA)
    * Latent Semantic Analysis (LSA)
    * Pearson Correlation
    * Dimensionality Reduction
    * Slope One

Amazon

    * Numerical Recipes in C: The Art of Scientific Computing
    * Statistics For People Who (Think They) Hate Statistics
    * Principal Component Analysis
    * Geometric Data Analysis: An Empirical Approach to Dimensionality Reduction and the Study of Patterns
    * Data Mining with Computational Intelligence (Advanced Information and Knowledge Processing)
    * Neural Networks for Pattern Recognition
    * Pattern Classification


re: tuning epocs:
    ... so, more epocs for later on features?  - sdw
    ... or the number of features times epochs must come out to a value in a
    certain range just to get values where they need to be, so with fewer
    features, we need a higher number of epochs? - sdw

=head1 NAME

Math::Preference::SVD - Preference/Recommendation Engine based on Single Value Decomposition

=head1 SYNOPSIS

    use Math::Preference::SVD;

    my $x = Math::Preference::SVD->new;

    my @users = (0..3);
    my @movies = (0..3);

    my @ratings = (
        map({ [ $_, 0, 4 ] } @users),    # *everyone* says item 0 is rated 4
        map({ [ $_, 1, 5 ] } @users),    # *everyone* says item 1 is rated 5
        map({ [ $_, 2, 1 ] } @users),    # *everyone* says item 2 is rated 1
        map({ [ $_, 3, 2 ] } @users),    # *everyone* says item 3 is rated 2
    );

    $x->set_ratings( \@ratings, );

    for my $cust (@users) {
        for my $movie (@movies) {
            # predict_rating() takes movie_id then cust_id -- yes, 
            # this seems backward to me too
            my $predicted = sprintf "%1.2f", $x->predict_rating($movie, $cust);
            print "cust $cust says about movie $movie: predicted: $predicted";
        }
    }

=head1 DESCRIPTION

This module imples a simple "preference engine" based on one of
the entries to the NetFlix Prize competition.
Preference engines take user rating data for items and attempt
to predict the user's rating for other items so that a system
might find and suggest to them other things they're likely to
purchase or enjoy.

Single Value Decoposition takes a large rectangular array of data
and decomposes it into two matrices, one as long as the data
and one as wide, that approximates the original matrix.
here and there.

And then it does it again, starting with the error left off by
the first set of matrices, making a second set of long and wide
matrices.  And then it does it again.
The result is a series of matrices that can be multiplied together,
and their outputs totaled up, to approximately reconstruct the original.

The large input matrix might, for instance, have customers
in the columns and movies in the rows, with data filled in
here and there to specify that customer's rating of that
movie.
Each set of matrices, with a tall one (for movies) and a 
wide one (for customers), could be thought of as containing
information about some tangible attribute of the movies
being rated and how the user feels about that attribute.
See the references below for an awesome example of the
first three attributes extracted from the NetFlix Prize
data.

Extrapolation is a side-effect of this lossy compression scheme.
This is where the recommendation engine bit comes into play --
you can ask the thing for ratings by a customer that that
customer never made, and it'll dutifully multiply the customer's
features versus the movie's features for the various features,
add them up, and give you a predicted rating for that movie
for that user.
By iterating over all of the movies (and I say movies, but
the user could be rating anything, including other users)
and asking for predictions for a specific user for that
movie, and sorting the results, you can come up with a list
of recommendations that he or she or it might like.

=head2 Deep, Profound Suckage

This is Alpha software!  Input validation is poor or non-existant, 
the C code likes to coredump, and there's presently no way to 
adjust tuning parameters without editing the XS, and the thing 
really needs tuning to the dataset at hand.

For what it's worth, SVD is nice for computing lots of 
recommendations quickly, but due to the extremely lossy
nature, it really isn't a fantastic recommendation engine.
It also requires large amounts of tuning to work on any
data set.
Quoting from http://sifter.org/~simon/journal/20061211.html on the subject
of the #defines inside the C:

"Despite the regularization term in the final incremental law above, over
fitting remains a problem. Plotting the progress over time, the probe rmse
eventually turns upward and starts getting worse (even though the training
error is still inching down). We found that simply choosing a fixed number of
training epochs appropriate to the learning rate and regularization constant
resulted in the best overall performance. I think for the numbers mentioned
above it was about 120 epochs per feature, at which point the feature was
considered done and we moved on to the next before it started over fitting."

See the URL for a more complete description of the over-fitting problem,
but the short version is that if it tries too hard at first by 
iterating too many times in the successive approximation feedback
thingie, then the first feature (set of wide and tall matrices) will 
fit well, but all of the ones after it will fit worse, and the overall
quality of predictions will drop.

=head2 API

Nothing is exported or available for export.  Use the OO interface --
even though you're allowed only one object because the C allocates
one set of datastructures, once.

    use Math::Preference::SVD;
    my $x = Math::Preference::SVD->new;
    
C<new()> takes no parameters.

        map({ [ $_, 3, 2 ] } @users),    # *everyone* says item 3 is rated 2
    );

    $x->set_ratings( [ [ cust_id_1, movie_id_1, rating ], ..., ] );

C<set_ratings()> takes all of the data in one batch.
It takes an arrayref full of arrayrefs, each of those containing
three fields:  the customer id of the person doing the rating;
the numeric id of the thing being rated, and the rating itself.
The rating must be 1-5 and this is enforced inside the engine.

Taking all of the data in one batch done by the Perl API 
so that it can extract the largest customer_id
and movie_id so that the C datastructures can be correctly sized.
See below for instructions on how to bang the XS directly if you want
to optimize by incrementally loading the data and are willing to size
these structures yourself.

    $x->predict_rating($movie, $cust);

Yes, this is B<ass backwards> from C<set_ratings()>. 
Sorry.  I'll fix it in the next version.
Gets a floating point value of the range 1.0 through 5.0 inclusive.

=head2 Incrementally Loading Rating Data

If you want to pre-size the datastructures and then load data 
incrementally, ditch the OO interface and call the XS routines directly
using fully qualified package names.
The C<Engine()> function takes the sizes of the data structures,
then C<set_Movies()> is called for each data item to be rated
then in a nested loop, C<set_Ratings()> is called.
Movies (or whatever -- I'm just going to continue to call them movies)
must be loaded in order with all of their ratings loaded sometime
after them and perhaps immediately after them -- I haven't tested.
See the Perl source of this module for an example of this usage -- it's pretty brief.

=head2 XS API

  void Engine(int, int, int);
  void set_Movies(int, int, int);    // set_Movies($movieId, 0, 0); # RatingCount = 0, RatingSum = 0
  void set_Ratings(int, int, int);   // set_Ratings($movieId, $custId, $rating);
  void CalcMetrics();                // call after loading all of the rating data -- pre-calc
  void CalcFeatures();               // call after calling the above -- does the actual work
  double PredictRating(short, int);  // takes $movieId, $custId, returns predicted rating, 1-5 float
  void DestroyEngine();              // free up the working RAM -- untested

=head2 EXPORT

None.

=head1 SEE ALSO

As far as Perl modules:  Dunno.  Any suggestions for me?

=over 1

=item http://www.timelydevelopment.com/demos/NetflixPrize.aspx

=item http://www.kdnuggets.com/news/2007/n08/6i.html

=back

=head1 BUGS

Values out of range make it coredump.  Other things make it coredump.
Duplicate ratings (same user and movie) seem to make it coredump.
You can only create one object at a time.
Memory is not automatically freed but must be manually freed.
The algorithm is kind of lame and needs lots of tuning.
The "other users with similar tastes" thing is a joke.

=head1 AUTHOR

Hi, I'm Scott, and I did this Perl adaption and wrote this documentation,
and this is my copyright foreword:
This code is covered by _two_ copyrights; I have copyright over my 
own work, and Timely Development, LLC has copyright over their work.
As such, to copy this entire thing, you must adhere to both copyrights.
Among other things, this means no stripping off credits or copyright
notices just because GPL+Artistic touched this thing.  
Fact of the matter is, the vast majority of the code is Timely
Development, LLC's, not mine.  Thanks.  
I'm glad we could have this little chat.

Copyright (c) 2008 by Scott Walters

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

Copyright (c) 2008 by Timely Development, LLC.

# SVD Sample Code
#
# Copyright (C) 2007 Timely Development (www.timelydevelopment.com)
#
# Special thanks to Simon Funk and others from the Netflix Prize contest 
# for providing pseudo-code and tuning hints.
#
# Feel free to use this code as you wish as long as you include 
# these notices and attribution. 
#
# Also, if you have alternative types of algorithms for accomplishing 
# the same goal and would like to contribute, please share them as well :)
#
# STANDARD DISCLAIMER:
#
# - THIS CODE AND INFORMATION IS PROVIDED "AS IS" WITHOUT WARRANTY
# - OF ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT
# - LIMITED TO THE IMPLIED WARRANTIES OF MERCHANTABILITY AND#OR
# - FITNESS FOR A PARTICULAR PURPOSE.
#

=cut


