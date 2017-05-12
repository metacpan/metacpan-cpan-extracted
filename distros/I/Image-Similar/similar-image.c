/* Given two grey images, compare them using the algorithm described
   in "An Image Signature for Any Kind of Image" by H. Chi Wong,
   Marshall Bern and David Goldberg, 2002. */

#include <stdlib.h>
#include <stdio.h>
#include <math.h>
#include <stdarg.h>
#include "similar-image.h"

#ifdef HEADER

#define SIZE 9
#define DIRECTIONS 8

/* A point in the grid. */

typedef struct point {
    double average_grey_level;
    int d[DIRECTIONS];
}
point_t;

typedef int (*simage_error_channel_t) (void * s, const char * format, ...);

typedef struct simage {
    /* The width of the image in pixels. */
    unsigned int width;
    /* The height of the image in pixels. */
    unsigned int height;
    /* The image data. */
    unsigned char * data;
    /* The computed signature. */
    char * signature;
    /* The length of the signature. */
    int signature_length;
    /* The P-value for this image, see equation in article. */
    unsigned int p;
    /* The grid of values. */
    point_t grid[SIZE*SIZE];
    /* width / (SIZE + 1) */
    double w10;
    /* height / (SIZE + 1) */
    double h10;
    /* The number of times malloc/calloc were called related to this
       object. */
    int nmallocs;
    simage_error_channel_t error_channel;
    /* This contains a true value if we have actually loaded image
       data, or a false value if not. This may be false if we just
       loaded a signature rather than the image. */
    unsigned int valid_image : 1;
    /* The grid is already filled. */
    unsigned int grid_filled : 1;
}
simage_t;

typedef enum {
    simage_ok,
    /* malloc failed. */
    simage_status_memory_failure,
    /* x or y is outside the image dimensions. */
    simage_status_bounds,
    simage_status_bad_image,
    /* Some upstream program did a stupid thing. */
    simage_status_bad_logic,
    /* */
    simage_status_free_underflow,
    /* */
    simage_status_memory_leak,
}
simage_status_t;

typedef enum {
    much_darker = -2,
    darker = -1,
    same = 0,
    lighter = 1,
    much_lighter = 2,
}
comparison_t;

#endif /* def HEADER */

#define FAIL(test,status,message,...) {					\
	if (test) {							\
	    if (s->error_channel) {					\
		(*s->error_channel) (s, "%s:%d: ", __FILE__, __LINE__);	\
		(*s->error_channel) (s, message, ## __VA_ARGS__);	\
		(*s->error_channel) (s, "\n");				\
	    }								\
	    return simage_status_ ## status;				\
	}								\
    }

#define CALL(x) {							\
	simage_status_t status;						\
	status = x;							\
	if (status != simage_ok) {					\
	    if (s->error_channel) {					\
		(*s->error_channel) (s, "%s:%d: ", __FILE__, __LINE__);	\
		(*s->error_channel) (s, "%s failed with status %d",	\
				     #x, status);			\
		(*s->error_channel) (s, "\n");				\
	    }								\
	    return status;						\
	}								\
    }

#define CHECK_XY(s,x,y) {					\
	FAIL (x > s->width || x < 0, bounds,			\
	      "x coordinate %d is outside the image", x);	\
	FAIL (y > s->height || y < 0, bounds,			\
	      "y coordinate %d is outside the image", y);	\
    }

/* Default place to print errors, if the user doesn't override this. */

static int
simage_default_error_channel (void * vs, const char * message, ...)
{
    va_list va;
    int chars;
    va_start (va, message);
    chars = vfprintf (stderr, message, va);
    va_end (va);
    return chars;
}

#define OUTSIDE -1

/* Given x and y coordinates, return the part of the grid which
   corresponds to that. */

int x_y_to_entry (int x, int y)
{
    int entry;
    if (x < 0 || x >= SIZE) {
	return OUTSIDE;
    }
    if (y < 0 || y >= SIZE) {
	return OUTSIDE;
    }
    entry = y * SIZE + x;
    if (entry < 0 || entry >= SIZE * SIZE) {
	fprintf (stderr, "%s:%d: overflow %d\n", __FILE__, __LINE__, entry);
	return OUTSIDE;
    }
    return entry;
}

simage_status_t
simage_dump (simage_t * s)
{
    printf ("{\n");
    printf ("\"width\":%d,\n", s->width);
    printf ("\"height\":%d,\n", s->height);
    printf ("\"p\":%d,\n", s->p);
    printf ("\"dummy\":0\n");
    printf ("}\n");
    return simage_ok;
}

simage_status_t
simage_init (simage_t * s, unsigned int width, unsigned int height)
{
    unsigned int p;
    /* The minimum of the width and the height. */
    unsigned int min_w_h;

    s->data = calloc (width * height, sizeof (unsigned char));
    CALL (simage_inc_nmallocs (s, s->data));
    s->height = height;
    s->width = width;
    s->p = 2;
    s->error_channel = & simage_default_error_channel;
    min_w_h = width;
    if (height < min_w_h) {
	min_w_h = height;
    }
    p = (unsigned int) (floor (0.5 + ((double) min_w_h)/20.0));
    if (p > s->p) {
	s->p = p;
    }
    //    simage_dump (s); 

    // This contains a valid image data, although it is just black
    // pixels at the moment.
    s->valid_image = 1;
    return simage_ok;
}

simage_status_t
simage_inc_nmallocs (simage_t * s, void * signature)
{
    FAIL (! signature, memory_failure, "Out of memory");
    s->nmallocs++;
    return simage_ok;
}

simage_status_t
simage_dec_nmallocs (simage_t * s)
{
    s->nmallocs--;
    FAIL (s->nmallocs < 0, free_underflow,
	  "too many frees, %d should be 0.\n",
	  s->nmallocs);
    return simage_ok;
}

/* Free all the memory associated with "s", except for "s" itself,
   which is allocated by the user. */

simage_status_t
simage_free (simage_t * s)
{
    if (s->data) {
	free (s->data);
	s->data = 0;
	CALL (simage_dec_nmallocs (s));
    }
    if (s->signature) {
	free (s->signature);
	s->signature = 0;
	CALL (simage_dec_nmallocs (s));
    }
    FAIL (s->nmallocs != 0, memory_leak,
	  "memory leak: %d should be 0.", s->nmallocs);
    return simage_ok;
}

/* Set the pixel at "x", "y" to the value "grey". */

simage_status_t
simage_set_pixel (simage_t * s, int x, int y, unsigned char grey)
{
    CHECK_XY (s, x, y);
    s->data[y * s->width + x] = grey;
    return simage_ok;
}

/* Compute the average intensity of the grid square at the coordinates
   "i", "j" on the grid. This assumes that "s->w10" and "s->h10" have
   already been computed. */

simage_status_t
simage_fill_entry (simage_t * s, int i, int j)
{
    double total;
    int px;
    int py;
    double xd;
    double yd;
    int x_min;
    int y_min;
    int x_max;
    int y_max;
    int size;
    int entry;
    int grey;
    xd = (i + 1) * s->w10;
    yd = (j + 1) * s->h10;
    x_min = round (xd - s->p / 2.0);
    y_min = round (yd - s->p / 2.0);
    x_max = round (xd + s->p / 2.0);
    y_max = round (yd + s->p / 2.0);

    /* For very small images, these boundaries are sometimes
       reached. */

    if (y_max >= s->height) {
	y_max = s->height - 1;
    }
    if (x_max >= s->width) {
	x_max = s->width - 1;
    }
    if (x_min < 0) {
	x_min = 0;
    }
    if (y_min < 0) {
	y_min = 0;
    }

    total = 0.0;
    for (py = y_min; py <= y_max; py++) {
	FAIL (py < 0 || py >= s->height, bounds,
	      "overflow py=%d for i, j = (%d, %d)\n", py, i, j);
	for (px = x_min; px <= x_max; px++) {
	    FAIL (px < 0 || px >= s->width, bounds,
		  "overflow px=%d for i, j = (%d, %d)\n", px, i, j);
	    total += s->data[py * s->width + px];
	}
    }
    size = (x_max - x_min + 1) * (y_max - y_min + 1);
    grey = (int) round (total / ((double) size));
    FAIL (grey < 0 || grey >= 256, bounds,
	  "bad average grey value %d.", grey);
    entry = x_y_to_entry (i, j);
    FAIL (entry == OUTSIDE, bounds,
	  "bounds error with %d %d -> %d\n",
	  i, j, entry);
    s->grid[entry].average_grey_level = grey;
    return simage_ok;
}

/* Go around the image and make the average values for each of the
   points on the grid. */

simage_status_t
simage_fill_entries (simage_t * s)
{
    int i;
    int j;
    FAIL (s->width == 0 || s->height == 0, bad_image,
	  "empty image w/h %d/%d.\n",
	  s->width, s->height);
    s->w10 = ((double) s->width) / ((double) (SIZE + 1));
    s->h10 = ((double) s->height) / ((double) (SIZE + 1));
    for (i = 0; i < SIZE; i++) {
	for (j = 0; j < SIZE; j++) {
	    CALL (simage_fill_entry (s, i, j));
	}
    }
    return simage_ok;
}

/* Given offsets xo and yo, return the array offset for the difference
   array which corresponds to that. */

int xo_yo_to_direction (int xo, int yo)
{
    int direction;
    if (xo <= 0 && yo <= 0) {
	direction = (xo + 1) + 3 * (yo + 1);
    }
    else {
	// Adjust for not having a centre square, so +1, +1 is 7, not 8.
	direction = (xo + 1) + 3 * (yo + 1) - 1;
    }
    return direction;
}

simage_status_t
direction_to_xo_yo (int direction, int * xo, int * yo)
{
    if (direction < 3) {
	* yo = -1;
	* xo = direction - 1;
	return simage_ok;
    }
    if (direction < 5) {
	* yo = 0;
	if (direction == 3) {
	    * xo = -1;
	}
	else if (direction == 4) {
	    * xo = 1;
	}
	else {
	    return simage_status_bounds;
	}
	return simage_ok;
    }
    if (direction < DIRECTIONS) {
	* yo = 1;
	* xo = direction - 6;
	return simage_ok;
    }
    fprintf (stderr, "%s:%d: direction %d >= DIRECTIONS %d.\n",
	     __FILE__, __LINE__, direction, DIRECTIONS);
    return simage_status_bounds;
}

int diff (int thisgrey, int thatgrey)
{
    int d;
    d = thisgrey - thatgrey;
    if (d >= -2 && d <= 2) {
	return same;
    }
    else if (d > 100) {
	return much_darker;
    }
    else if (d > 2) {
	return darker;
    }
    else if (d < -100) {
	return much_lighter;
    }
    else if (d < -2) {
	return lighter;
    }
    else {
	fprintf (stderr, "%s:%d: mysterious d value %d\n",
		 __FILE__, __LINE__, d);
	return same;
    }
}

/* Make the difference between two adjoining points. */

simage_status_t
simage_make_point_diffs (simage_t * s, int x, int y)
{
    int xo;
    int yo;
    int thisgrey;
    int thisentry;
    point_t * thispoint;
    thisentry = x_y_to_entry (x, y);
    /* Make 100% sure that we don't try to access outside the "grid" array
       within "s". */
    FAIL (thisentry == OUTSIDE, bounds, "entry outside grid %d %d %d\n",
	  x, y, thisentry);
    thispoint = & s->grid[thisentry];
    thisgrey = thispoint->average_grey_level;
    for (xo = -1; xo <= 1; xo++) {
	for (yo = -1; yo <= 1; yo++) {
	    int thatentry;
	    int direction;
	    int thatgrey;
	    if (xo == 0 && yo == 0) {
		// Skip the middle square, since this would be the
		// difference between us and ourselves.
		continue;
	    }
	    thatentry = x_y_to_entry (x + xo, y + yo);
	    if (thatentry == OUTSIDE) {
		// Skip entries which are outside the grid, which
		// happens e.g. if x = 0 and xo = -1.
		continue;
	    }
	    // Get the grey level of the other point
	    thatgrey = s->grid[thatentry].average_grey_level;
	    // turn xo, yo into an array offset "direction".
	    direction = xo_yo_to_direction (xo, yo);
	    // Put the difference into d[direction] of the current point.
	    thispoint->d[direction] = diff (thisgrey, thatgrey);
	    //	    fprintf (stderr, "# %d %d %d\n", thisentry, direction, thispoint->d[direction]);
	}
    }
    return simage_ok;
}

simage_status_t
entry_to_x_y (int entry, int * x_ptr, int * y_ptr)
{
    int x;
    int y;
    x = entry % SIZE;
    y = entry / SIZE;
    * x_ptr = x;
    * y_ptr = y;
    return simage_ok;
}

/* Make the array of differences between adjoining points. */

simage_status_t
simage_make_differences (simage_t * s)
{
    int cell;
    for (cell = 0; cell < SIZE * SIZE; cell++) {
	int x;
	int y;
	CALL (entry_to_x_y (cell, & x, & y));
	CALL (simage_make_point_diffs (s, x, y));
    }
    return simage_ok;
}

#define MAXDIM 10000

simage_status_t
simage_check_image (simage_t * s)
{
    FAIL (s->width == 0 || s->height == 0, bad_image,
	  "empty image w/h %d/%d.\n",
	  s->width, s->height);
    FAIL (s->width > MAXDIM || s->height > MAXDIM, bad_image,
	  "oversize image w/h %d/%d.\n",
	  s->width, s->height);
    return simage_ok;
}

simage_status_t
simage_fill_grid (simage_t * s)
{
    FAIL (s->grid_filled, bad_logic, 
	  "double call to fill_grid.\n");
    CALL (simage_check_image (s));
    CALL (simage_fill_entries (s));
    CALL (simage_make_differences (s));
    s->grid_filled = 1;
    return simage_ok;
}

simage_status_t
simage_diff (simage_t * s1, simage_t * s2, double * total_diff)
{
    int total;
    int total1;
    int total2;
    int cell;
    total = 0;
    total1 = 0;
    total2 = 0;
    for (cell = 0; cell < SIZE * SIZE; cell++) {
	int direction;
	for (direction = 0; direction < DIRECTIONS; direction++) {
	    int diff;
	    int s1cd;
	    int s2cd;
	    s1cd = s1->grid[cell].d[direction];
	    s2cd = s2->grid[cell].d[direction];
	    diff = s1cd - s2cd;
	    // Add the squares of the values to the totals.
	    total += diff * diff;
	    total1 += s1cd * s1cd;
	    total2 += s2cd * s2cd;
	}
    }
    if (total1 == 0 && total2 == 0) {
	*total_diff = 0.0;
	return simage_ok;
    }
    *total_diff = ((double) total) / ((double)(total1 + total2));
    return simage_ok;
}

/* Check whether this direction and cell point to another
   cell or are outside the image. */

int inside (int cell, int direction)
{
    int x;
    int y;
    int xo;
    int yo;
    int nextcell;
    x = cell % SIZE;
    y = cell / SIZE;
    direction_to_xo_yo (direction, & xo, & yo);
    nextcell = x_y_to_entry (x + xo, y + yo);
    if (nextcell == OUTSIDE) {
	return 0;
    }
    return 1;
}

simage_status_t
simage_allocate_signature (simage_t * s, int size)
{
    s->signature = calloc (size + 1, sizeof (unsigned char));
    CALL (simage_inc_nmallocs (s, s->signature));
    return simage_ok;
}

simage_status_t
simage_signature (simage_t * s)
{
    int cell;
    int max_size;
    max_size = DIRECTIONS * SIZE * SIZE;
    CALL (simage_allocate_signature (s, max_size));
    s->signature_length = 0;
    for (cell = 0; cell < SIZE * SIZE; cell++) {
	int direction;
	for (direction = 0; direction < DIRECTIONS; direction++) {
	    if (inside (cell, direction)) {
		int value;
		value = s->grid[cell].d[direction] + 2 + '0';
		FAIL (value < '0' || value > '5', bounds,
		      "overflow %d at cell=%d direction=%d",
		      value, cell, direction);
		s->signature[s->signature_length] = (char) value;
		s->signature_length++;
		FAIL (s->signature_length > max_size, bounds,
		      "signature length %d > max size %d",
		      s->signature_length, max_size);
	    }
	}
    }
    return simage_ok;
}

simage_status_t
simage_fill_from_signature (simage_t * s, char * signature, int signature_length)
{
    // Cell number
    int c;
    // Offset into signature.
    int o;
    CALL (simage_allocate_signature (s, signature_length));
    s->signature_length = signature_length;
    o = 0;
    for (c = 0; c < SIZE * SIZE; c++) {
	/* The direction. */
	int d;
	int x;
	int y;
	CALL (entry_to_x_y (c, & x, & y));
	for (d = 0; d < DIRECTIONS; d++) {
	    if (inside (c, d)) {
		//printf ("%d %d %d\n", c, d, o);
		/* The value of this cell. */
		int value;
		FAIL (o >= signature_length, bounds,
		      "offset %d exceeded signature length %d.\n",
		      o, signature_length);
		value = signature[o] - '0' - 2;
		s->signature[o] = signature[o];
		o++;
		s->grid[c].d[d] = value;
	    }
	}
    }
    s->signature[s->signature_length] = '\0';
    return simage_ok;
}
