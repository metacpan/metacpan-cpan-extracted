#include <stdlib.h>
#include <string.h>
#include <errno.h>

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "puzzle.h"

#include "ppport.h"

typedef struct _Image__Libpuzzle {
    PuzzleContext context;
    PuzzleCvec    cvec;
} * Image__Libpuzzle;

typedef PuzzleCvec * Image__Libpuzzle__Cvec;

typedef PuzzleContext * Image__Libpuzzle__Context;

MODULE = Image::Libpuzzle	PACKAGE = Image::Libpuzzle::Cvec	PREFIX = cvec_

void
cvec_DESTROY(cvec)
    Image::Libpuzzle::Cvec cvec 

    CODE:
      free(cvec);

MODULE = Image::Libpuzzle	PACKAGE = Image::Libpuzzle::Context	PREFIX = context 

void
context_DESTROY(context)
    Image::Libpuzzle::Context context 

    CODE:
      free(context);

MODULE = Image::Libpuzzle	PACKAGE = Image::Libpuzzle	PREFIX = libpuzzle_

# constructor, returns reference to _Image__Libpuzzle struct 
Image::Libpuzzle
libpuzzle_new(klass, ...)
    char *klass

    CODE:
      Image__Libpuzzle self;

      if ((self = malloc(sizeof(*self))) == NULL) {
          croak("Unable to allocate PuzzleContext: %s", strerror(errno));
      }

      puzzle_init_context(&self->context);
      puzzle_init_cvec(&self->context, &self->cvec);

      RETVAL = self;

    OUTPUT:
      RETVAL

# get reference to Cvec wrapped as an Image::Libpuzzle::Cvec
Image::Libpuzzle::Cvec
libpuzzle_get_cvec(self) 
    Image::Libpuzzle self 

    CODE:
      RETVAL = &self->cvec;

    OUTPUT:
      RETVAL

# for convenience, returns signature; can also use Image::Libpuzzle->get_signature() after
SV *
libpuzzle_fill_cvec_from_file(self, filename)
    Image::Libpuzzle self 
    char *filename

    CODE:
      if (puzzle_fill_cvec_from_file(&self->context, &self->cvec, filename) < 0) {
          croak("Unable to fill CVEC from file %s: %s", filename, strerror(errno));
      }

      RETVAL = newSVpv((char *)self->cvec.vec, self->cvec.sizeof_vec);

    OUTPUT:
      RETVAL

# will return a signature, assuming after Image::Libpuzzle->fill_cvec_from_file has been called
SV *
libpuzzle_get_signature(self)
    Image::Libpuzzle self 

    CODE:
      RETVAL = newSVpv((char *)self->cvec.vec, self->cvec.sizeof_vec);

    OUTPUT:
      RETVAL

void
libpuzzle_DESTROY(self)
    Image::Libpuzzle self

    CODE:
      free(self);

int
libpuzzle_set_lambdas(self, lambdas)
    Image::Libpuzzle self;
    unsigned int lambdas

    CODE:
      RETVAL = puzzle_set_lambdas(&self->context, lambdas);

    OUTPUT:
      RETVAL

int
libpuzzle_set_p_ratio(self, p_ratio)
    Image::Libpuzzle self;
    double p_ratio

    CODE:
      RETVAL = puzzle_set_p_ratio(&self->context, p_ratio);

    OUTPUT:
      RETVAL

int
libpuzzle_set_max_width(self, width)
    Image::Libpuzzle self;
    unsigned int width

    CODE:
      RETVAL = puzzle_set_max_width(&self->context, width);

    OUTPUT:
      RETVAL

int
libpuzzle_set_max_height(self, height)
    Image::Libpuzzle self;
    unsigned int height

    CODE:
      RETVAL = puzzle_set_max_height(&self->context, height);

    OUTPUT:
      RETVAL

int
libpuzzle_set_noise_cutoff(self, noise_cutoff)
    Image::Libpuzzle self;
    double noise_cutoff

    CODE:
      RETVAL = puzzle_set_noise_cutoff(&self->context, noise_cutoff);

    OUTPUT:
      RETVAL

int
libpuzzle_set_contrast_barrier_for_cropping(self, barrier)
    Image::Libpuzzle self;
    double barrier

    CODE:
      RETVAL = puzzle_set_contrast_barrier_for_cropping(&self->context, barrier);

    OUTPUT:
      RETVAL

int
libpuzzle_set_max_cropping_ratio(self, ratio)
    Image::Libpuzzle self;
    double ratio

    CODE:
      RETVAL = puzzle_set_max_cropping_ratio(&self->context, ratio);

    OUTPUT:
      RETVAL

int
libpuzzle_set_autocrop(self, enable)
    Image::Libpuzzle self;
    int enable

    CODE:
      RETVAL = puzzle_set_autocrop(&self->context, enable);

    OUTPUT:
      RETVAL

double
libpuzzle_vector_euclidean_length(self)
    Image::Libpuzzle self

    CODE:
      RETVAL = puzzle_vector_euclidean_length(&self->context, &self->cvec);

    OUTPUT:
      RETVAL
    
double
libpuzzle_vector_normalized_distance(self, other)
    Image::Libpuzzle self;
    Image::Libpuzzle other;

    CODE:
      RETVAL = puzzle_vector_normalized_distance(&self->context, &self->cvec, &other->cvec, 1);

    OUTPUT:
      RETVAL

# use PUZZLE_CVEC_SIMILARITY_THRESHOLD
int
libpuzzle_is_similar(self, other)
    Image::Libpuzzle self;
    Image::Libpuzzle other;
    CODE:
      RETVAL = 0;
      double distance = puzzle_vector_normalized_distance(&self->context, &self->cvec, &other->cvec, 0);
      if ( distance <  PUZZLE_CVEC_SIMILARITY_THRESHOLD ) {
        RETVAL = 1;
      }

    OUTPUT:
      RETVAL

# use PUZZLE_CVEC_SIMILARITY_LOW_THRESHOLD
int
libpuzzle_is_very_similar(self, other)
    Image::Libpuzzle self;
    Image::Libpuzzle other;
    CODE:
      RETVAL = 0;
      double distance = puzzle_vector_normalized_distance(&self->context, &self->cvec, &other->cvec, 0);
      if ( distance <  PUZZLE_CVEC_SIMILARITY_LOW_THRESHOLD ) {
        RETVAL = 1;
      }

    OUTPUT:
      RETVAL

# use PUZZLE_CVEC_SIMILARITY_LOWER_THRESHOLD
int
libpuzzle_is_most_similar(self, other)
    Image::Libpuzzle self;
    Image::Libpuzzle other;
    CODE:
      RETVAL = 0;
      double distance = puzzle_vector_normalized_distance(&self->context, &self->cvec, &other->cvec, 0);
      if ( distance <  PUZZLE_CVEC_SIMILARITY_LOWER_THRESHOLD ) {
        RETVAL = 1;
      }

    OUTPUT:
      RETVAL

# access to libary constants

int
libpuzzle_PUZZLE_VERSION_MAJOR(self)

    CODE:
      RETVAL = PUZZLE_VERSION_MAJOR;

    OUTPUT:
      RETVAL

int
libpuzzle_PUZZLE_VERSION_MINOR(self)

    CODE:
      RETVAL = PUZZLE_VERSION_MINOR;

    OUTPUT:
      RETVAL

double
libpuzzle_PUZZLE_CVEC_SIMILARITY_THRESHOLD(self)

    CODE:
      RETVAL = PUZZLE_CVEC_SIMILARITY_THRESHOLD;

    OUTPUT:
      RETVAL

double
libpuzzle_PUZZLE_CVEC_SIMILARITY_HIGH_THRESHOLD(self)

    CODE:
      RETVAL = PUZZLE_CVEC_SIMILARITY_HIGH_THRESHOLD;

    OUTPUT:
      RETVAL

double
libpuzzle_PUZZLE_CVEC_SIMILARITY_LOW_THRESHOLD(self)

    CODE:
      RETVAL = PUZZLE_CVEC_SIMILARITY_LOW_THRESHOLD;

    OUTPUT:
      RETVAL

double
libpuzzle_PUZZLE_CVEC_SIMILARITY_LOWER_THRESHOLD(self)

    CODE:
      RETVAL = PUZZLE_CVEC_SIMILARITY_LOWER_THRESHOLD;

    OUTPUT:
      RETVAL
