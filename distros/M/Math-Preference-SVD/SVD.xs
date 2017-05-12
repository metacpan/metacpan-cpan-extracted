#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include "const-c.inc"

#include <math.h>

//===================================================================
//
// Constants and Type Declarations
//
//===================================================================

// #define MAX_FEATURES    64            // Number of features to use 
#define MAX_FEATURES    8
// #define MIN_EPOCHS      120           // Minimum number of epochs per feature
#define MIN_EPOCHS      500
// #define MAX_EPOCHS      200           // Max epochs per feature
#define MAX_EPOCHS      2000

#define MIN_IMPROVEMENT 0.005        // Minimum improvement required to continue current feature
#define INITx           0.1           // Initialization value for features
#define LRATE           0.001         // Learning rate parameter
#define K               0.015         // Regularization parameter used to minimize over-fitting


//////////////////////////////////////////////////////////////////////////////////////////////////////

typedef unsigned char BYTE;
#define true 1
#define false 0

struct Movie
{
    int         RatingCount;
    int         RatingSum;
    double      RatingAvg;            
    double      PseudoAvg;
};
            // PseudoAvg is a weighted average used to deal with small movie counts 

struct Customer
{
    int         RatingCount;
    int         RatingSum;
};
    // int         CustomerId;

struct Data
{
    int         CustId;
    short       MovieId;
    BYTE        Rating;
    float       Cache;
};

// class Engine 

int num_customers;
int num_movies;
int num_ratings;

// private:

int             RatingCount;                                 // Current number of loaded ratings
struct Data     *Ratings;                                    // Array of ratings data
struct Movie    *Movies;                                     // Array of movie metrics
struct Customer *Customers;                                  // Array of customer metrics
float           **MovieFeatures;     // Array of features by movie (using floats to save space)
float           **CustFeatures;   // Array of features by customer (using floats to save space)

// was private, should be public now

void Engine(int, int, int);
void DestroyEngine();
void set_Movies(int, int, int);
void set_Ratings(int, int, int);
void CalcMetrics();
void CalcFeatures();
inline double PredictRating(short, int);
inline double PredictRating2(short, int, int, float, bool);

// end class Engine

// sdw accessors for Perl

void set_Movies(int movieId, int count, int sum) {
    Movies[movieId].RatingCount = count;
    Movies[movieId].RatingSum = sum;
}

void set_Ratings(int movieId, int custId, int rating) {
    Ratings[RatingCount].MovieId = (short)movieId;
    Ratings[RatingCount].CustId = custId;
    Ratings[RatingCount].Rating = (BYTE)rating;
    Ratings[RatingCount].Cache = 0;
    RatingCount++;
}

//===================================================================
//
// Engine Class 
//
//===================================================================

//-------------------------------------------------------------------
// Initialization
//-------------------------------------------------------------------

void Engine(int x_num_customers, int x_num_ratings, int x_num_movies) {

    int i, f;

    num_customers = x_num_customers;  // yeah, I know... there's a trick for doing this.  don't know it.  XXX todo.
    num_ratings = x_num_ratings;
    num_movies = x_num_movies; 

    RatingCount = 0;

    Ratings = (struct Data*)calloc(sizeof(struct Data), num_ratings);
    Movies = (struct Movie*)calloc(sizeof(struct Movie), num_movies);
    Customers = (struct Customer*)calloc(sizeof(struct Customer), num_customers);

    MovieFeatures = (float **)calloc(sizeof(float *), MAX_FEATURES);  // calloc should have these 0 initialized
    CustFeatures = (float **)calloc(sizeof(float *), MAX_FEATURES); 
    
    for (f=0; f<MAX_FEATURES; f++)
    {
        MovieFeatures[f] = (float *)calloc(sizeof(float), num_movies);
        CustFeatures[f] = (float *)calloc(sizeof(float), num_customers);
        for (i=0; i<num_movies; i++) {
            MovieFeatures[f][i] = (float)INITx;
        }
        for (i=0; i<num_customers; i++) {
            CustFeatures[f][i] = (float)INITx;
        }
    }
}

void DestroyEngine() {
    free(Ratings);
    free(Movies);
    free(Customers);
    free(MovieFeatures);
    free(CustFeatures);
    RatingCount = 0;
}

//-------------------------------------------------------------------
// Calculations - This Paragraph contains all of the relevant code
//-------------------------------------------------------------------

//
// CalcMetrics
// - Loop through the history and pre-calculate metrics used in the training 
//
void CalcMetrics()
{
    int i, cid;
    // IdItr itr;

    wprintf(L"\nCalculating intermediate metrics\n");

    // Process each row in the training set
    for (i=0; i<RatingCount; i++)
    {
        struct Data* rating = Ratings + i;

        // Increment movie stats
        Movies[rating->MovieId].RatingCount++;
        Movies[rating->MovieId].RatingSum += rating->Rating;

        // killed map translate stuff here -- sdw
        Customers[rating->CustId].RatingCount++;
        Customers[rating->CustId].RatingSum += rating->Rating;
    }

    // Do a follow-up loop to calc movie averages
    for (i=0; i<num_movies; i++)
    {
        struct Movie* movie = Movies+i;
        movie->RatingAvg = movie->RatingSum / (1.0 * movie->RatingCount);
        movie->PseudoAvg = (3.23 * 25 + movie->RatingSum) / (25.0 + movie->RatingCount);
    }
}

//
// CalcFeatures
// - Iteratively train each feature on the entire data set
// - Once sufficient progress has been made, move on
//
void CalcFeatures()
{
    int f, e, i, custId, cnt = 0;
    struct Data* rating;
    double err, p, sq, rmse_last, rmse = 2.0;
    short movieId;
    float cf, mf;

    for (f=0; f<MAX_FEATURES; f++)
    {
        wprintf(L"\n--- Calculating feature: %d ---\n", f);

        // Keep looping until you have passed a minimum number 
        // of epochs or have stopped making significant progress 
        for (e=0; (e < MIN_EPOCHS) || (rmse <= rmse_last - MIN_IMPROVEMENT); e++)
        {
            cnt++;
            sq = 0;
            rmse_last = rmse;

            for (i=0; i<RatingCount; i++)
            {
                rating = Ratings + i;
                movieId = rating->MovieId;
                custId = rating->CustId;

                // Predict rating and calc error
                p = PredictRating2(movieId, custId, f, rating->Cache, true);
            // wprintf(L"         movieId=%d custId=%d rating=%d predicted=%1.2f finalpredicted=%1.2f\n", movieId, custId, rating->Rating, p, PredictRating(movieId, custId));
                err = (1.0 * rating->Rating - p);
                sq += err*err;
                
                // Cache off old feature values
                cf = CustFeatures[f][custId];
                mf = MovieFeatures[f][movieId];

                // Cross-train the features
                CustFeatures[f][custId] += (float)(LRATE * (err * mf - K * cf));
                MovieFeatures[f][movieId] += (float)(LRATE * (err * cf - K * mf));
            }
            
            rmse = sqrt(sq/RatingCount);
                  
            // wprintf(L"     cnt='%d' rmse='%f' />\n",cnt,rmse);
        }

        // Cache off old predictions
        for (i=0; i<RatingCount; i++)
        {
            rating = Ratings + i;
            rating->Cache = (float)PredictRating2(rating->MovieId, rating->CustId, f, rating->Cache, false);
        }            
    }
}

//
// PredictRating
// - During training there is no need to loop through all of the features
// - Use a cache for the leading features and do a quick calculation for the trailing
// - The trailing can be optionally removed when calculating a new cache value
//
double PredictRating2(short movieId, int custId, int feature, float cache, bool bTrailing)
{
    // Get cached value for old features or default to an average
    double sum = (cache > 0) ? cache : 1; //Movies[movieId].PseudoAvg; 

    // Add contribution of current feature
    sum += MovieFeatures[feature][movieId] * CustFeatures[feature][custId];
    if (sum > 5) sum = 5;
    if (sum < 1) sum = 1;

    // Add up trailing defaults values
    if (bTrailing)
    // if (bTrailing && feature > 0)  // sdw -- no way to test this without more complicated data so leaving it alone for now
    {
        sum += (MAX_FEATURES-feature-1) * (INITx * INITx); // sdw -- this is bizarre; wrap around from the other side minus one?
        // sum += (feature-1) * (INITx * INITx); // sdw -- wouldn't this be more correct?  meh?
        if (sum > 5) sum = 5;
        if (sum < 1) sum = 1;
    }

    return sum;
}

//
// PredictRating
// - This version is used for calculating the final results
// - It loops through the entire list of finished features
//
double PredictRating(short movieId, int custId)
{
    double sum = 1; //Movies[movieId].PseudoAvg;
    int f;

    for (f=0; f<MAX_FEATURES; f++) 
    {
        sum += MovieFeatures[f][movieId] * CustFeatures[f][custId];
    }

    if (sum > 5) sum = 5;
    if (sum < 1) sum = 1;

    return sum;
}


/* 
###############################################################################
#
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
###############################################################################

Copyright © 2008 by Timely Development, LLC.

 */

MODULE = Math::Preference::SVD	PACKAGE = Math::Preference::SVD	

INCLUDE: const-xs.inc

PROTOTYPES: DISABLE


void
set_Movies (movieId, count, sum)
	int	movieId
	int	count
	int	sum
	PREINIT:
	I32* temp;
	PPCODE:
	temp = PL_markstack_ptr++;
	set_Movies(movieId, count, sum);
	if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
	  PL_markstack_ptr = temp;
	  XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
	return; /* assume stack size is correct */

void
set_Ratings (movieId, custId, rating)
	int	movieId
	int	custId
	int	rating
	PREINIT:
	I32* temp;
	PPCODE:
	temp = PL_markstack_ptr++;
	set_Ratings(movieId, custId, rating);
	if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
	  PL_markstack_ptr = temp;
	  XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
	return; /* assume stack size is correct */

void
Engine (x_num_customers, x_num_ratings, x_num_movies)
	int	x_num_customers
	int	x_num_ratings
	int	x_num_movies
	PREINIT:
	I32* temp;
	PPCODE:
	temp = PL_markstack_ptr++;
	Engine(x_num_customers, x_num_ratings, x_num_movies);
	if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
	  PL_markstack_ptr = temp;
	  XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
	return; /* assume stack size is correct */

void
DestroyEngine ()
	PREINIT:
	I32* temp;
	PPCODE:
	temp = PL_markstack_ptr++;
	DestroyEngine();
	if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
	  PL_markstack_ptr = temp;
	  XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
	return; /* assume stack size is correct */

void
CalcMetrics ()
	PREINIT:
	I32* temp;
	PPCODE:
	temp = PL_markstack_ptr++;
	CalcMetrics();
	if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
	  PL_markstack_ptr = temp;
	  XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
	return; /* assume stack size is correct */

void
CalcFeatures ()
	PREINIT:
	I32* temp;
	PPCODE:
	temp = PL_markstack_ptr++;
	CalcFeatures();
	if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
	  PL_markstack_ptr = temp;
	  XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
	return; /* assume stack size is correct */

double
PredictRating2 (movieId, custId, feature, cache, bTrailing)
	short	movieId
	int	custId
	int	feature
	float	cache
	bool	bTrailing

double
PredictRating (movieId, custId)
	short	movieId
	int	custId

