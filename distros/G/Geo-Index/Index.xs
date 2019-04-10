#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "INLINE.h"
/* Start of C code */

// This code requires at least a C99 compiler (for uint_* types and // comments)

#define MAJOR_VERSION 0
#define MINOR_VERSION 0
#define SUB_VERSION   8

/* Do not put void in the parameters below, it'll break XS */ 
unsigned int GetCCodeVersion( ) {
	return ( MAJOR_VERSION << 20 ) | ( MINOR_VERSION << 10 ) | SUB_VERSION;
}

/*
   All functions below come in two versions, one using single-precision (float) 
   math and variables and the other using double-precision (double) math and 
   variables.  Functionally, the two versions of each function are identical.
*/

unsigned int fast_log2_double(double n) {
	return ceil( log2(n) );
}

unsigned int fast_log2_float(float n) {
	return ceilf( log2f(n) );
}


#define PI 3.14159265358979
#define DEG2RAD (PI / 180.0) *
#define RAD2DEG (180.0 / PI) *

/*
This code accelerates the set-up code in the Search(...) method.  Functionally it is identical to the Perl version.
Called as ( $grid_level, $grid_size, $max_grid_idx, $lat_0_idx, $lat_1_idx, $lon_0_idx, $lon_1_idx ) = ComputeAreaExtrema( $tile_adjust, $max_size, $max_level, $p_lat, $p_lat_rad, $p_lon, $self->{polar_circumference}, $search_radius );
*/

void ComputeAreaExtrema_float( int tile_adjust, unsigned long max_size, unsigned int max_level, float p_lat, float p_lat_rad, float p_lon, float polar_circumference, float search_radius ) {
	Inline_Stack_Vars;  /* For return values */
	
	uint_fast8_t  grid_level   = 0;
	uint_fast32_t grid_size    = 0;
	uint_fast32_t max_grid_idx = 0;
	
	// Determine grid level to search at
	
	// Size of most detailed grid tile at this point (in meters)
	float ns_indexed_meters = ( polar_circumference / 2.0 ) / max_size; // Dividing by two to get pole-to-pole distance
	
	uint_fast8_t shift = fast_log2_float( search_radius / ns_indexed_meters );
	
	shift += tile_adjust;
	
	//  Make sure the shift we computed lies within the index levels
	if (shift < 0) {
		shift = 0;
	} else if (shift >= max_level) {
		shift = max_level - 1;
	}
	
	//  Shift is relative to the highest-resolution zoom level
	//  Determine grid level to use
	grid_level = max_level - shift;
	
	grid_size = 1 << (grid_level+1);
	max_grid_idx = grid_size - 1;
	
	//  Determine which grid tiles need to be checked
	
	//  Get search point's grid indices
	
	float lat_meter_in_degrees = 360.0 / polar_circumference;
	
	float lat_radius = search_radius * lat_meter_in_degrees;
	float lat_radius_rad = DEG2RAD( lat_radius );
	float lon_radius = RAD2DEG( atan2f( sinf(lat_radius_rad), cosf(lat_radius_rad) * cosf(p_lat_rad) ) );
	
	float lat_0 = p_lat - lat_radius;
	float lat_1 = p_lat + lat_radius;
	
	float lon_0 = p_lon - lon_radius;
	float lon_1 = p_lon + lon_radius;
	
	
	if (lat_0 <= -90) {
		lat_0 = -90;
	}
	
	if (lat_1 >= 90) {
		lat_1 = 90;
	}
	
	if      ( lon_0 < -180.0 ) { lon_0 += 360.0; }
	else if ( lon_0 > 180.0 )  { lon_0 -= 360.0; }
	
	if      ( lon_1 < -180.0 ) { lon_1 += 360.0; }
	else if ( lon_1 > 180.0 )  { lon_1 -= 360.0; }
	
	if      ( lat_0 < -90.0 ) { lat_0 = -90.0; }
	else if ( lat_0 >  90.0 ) { lat_0 =  90.0; }
	
	if      ( lat_1 < -90.0 ) { lat_1 = -90.0; }
	else if ( lat_1 >  90.0 ) { lat_1 =  90.0; }
	
	uint_fast32_t lat_0_idx = (uint_fast32_t)( ( lat_0 + 90.0 )  * max_size / 180.0 );
	if (lat_0_idx >= max_size) lat_0_idx = max_size - 1;
	lat_0_idx >>= shift;
	
	uint_fast32_t lat_1_idx = (uint_fast32_t)( ( lat_1 + 90.0 )  * max_size / 180.0 );
	if (lat_1_idx >= max_size) lat_1_idx = max_size - 1;
	lat_1_idx >>= shift;
	
	uint_fast32_t lon_0_idx = ( (uint_fast32_t)( ( lon_0 + 180.0 ) * max_size / 360.0 ) % max_size ) >> shift;
	
	uint_fast32_t lon_1_idx = ( (uint_fast32_t)( ( lon_1 + 180.0 ) * max_size / 360.0 ) % max_size ) >> shift;
	
	if (lat_0_idx > lat_1_idx) {
		uint_fast32_t tmp = lat_1_idx;
		lat_1_idx = lat_0_idx;
		lat_0_idx = tmp;
	}
	
	/* Populate return values (all unsigned integers) */
	
	Inline_Stack_Reset;
	Inline_Stack_Push(sv_2mortal(newSVuv( grid_level )));
	Inline_Stack_Push(sv_2mortal(newSVuv( grid_size )));
	Inline_Stack_Push(sv_2mortal(newSVuv( max_grid_idx )));
	Inline_Stack_Push(sv_2mortal(newSVuv( lat_0_idx )));
	Inline_Stack_Push(sv_2mortal(newSVuv( lat_1_idx )));
	Inline_Stack_Push(sv_2mortal(newSVuv( lon_0_idx )));
	Inline_Stack_Push(sv_2mortal(newSVuv( lon_1_idx )));
	Inline_Stack_Done;
}


void ComputeAreaExtrema_double( int tile_adjust, unsigned long max_size, unsigned int max_level, double p_lat, double p_lat_rad, double p_lon, double polar_circumference, double search_radius ) {
	Inline_Stack_Vars;  /* For return values */
	
	uint_fast8_t  grid_level   = 0;
	uint_fast32_t grid_size    = 0;
	uint_fast32_t max_grid_idx = 0;
	
	// Determine grid level to search at
	
	// Size of most detailed grid tile at this point (in meters)
	double ns_indexed_meters = ( polar_circumference / 2.0 ) / max_size; // Dividing by two to get pole-to-pole distance
	
	uint_fast8_t shift = fast_log2_double( search_radius / ns_indexed_meters );
	
	shift += tile_adjust;
	
	//  Make sure the shift we computed lies within the index levels
	if (shift < 0) {
		shift = 0;
	} else if (shift >= max_level) {	
		shift = max_level - 1;
	}
	
	//  Shift is relative to the highest-resolution zoom level
	//  Determine grid level to use
	grid_level = max_level - shift;
	
	grid_size = 1 << (grid_level+1);
	max_grid_idx = grid_size - 1;
	
	//  Determine which grid tiles need to be checked
	
	//  Get search point's grid indices
	
	double lat_meter_in_degrees = 360.0 / polar_circumference;
	
	double lat_radius = search_radius * lat_meter_in_degrees;
	double lat_radius_rad = DEG2RAD( lat_radius );
	double lon_radius = RAD2DEG( atan2( sin(lat_radius_rad), cos(lat_radius_rad) * cos(p_lat_rad) ) );
	
	double lat_0 = p_lat - lat_radius;
	double lat_1 = p_lat + lat_radius;
	
	double lon_0 = p_lon - lon_radius;
	double lon_1 = p_lon + lon_radius;
	
	
	if (lat_0 <= -90) {
		lat_0 = -90;
	}
	
	if (lat_1 >= 90) {
		lat_1 = 90;
	}
	
	if      ( lon_0 < -180.0 ) { lon_0 += 360.0; }
	else if ( lon_0 > 180.0 )  { lon_0 -= 360.0; }
	
	if      ( lon_1 < -180.0 ) { lon_1 += 360.0; }
	else if ( lon_1 > 180.0 )  { lon_1 -= 360.0; }
	
	if      ( lat_0 < -90.0 ) { lat_0 = -90.0; }
	else if ( lat_0 >  90.0 ) { lat_0 =  90.0; }
	
	if      ( lat_1 < -90.0 ) { lat_1 = -90.0; }
	else if ( lat_1 >  90.0 ) { lat_1 =  90.0; }
	
	uint_fast32_t lat_0_idx = (uint_fast32_t)( ( lat_0 + 90.0 )  * max_size / 180.0 );
	if (lat_0_idx >= max_size) lat_0_idx = max_size - 1;
	lat_0_idx >>= shift;
	
	uint_fast32_t lat_1_idx = (uint_fast32_t)( ( lat_1 + 90.0 )  * max_size / 180.0 );
	if (lat_1_idx >= max_size) lat_1_idx = max_size - 1;
	lat_1_idx >>= shift;
	
	uint_fast32_t lon_0_idx = ( (uint_fast32_t)( ( lon_0 + 180.0 ) * max_size / 360.0 ) % max_size ) >> shift;
	
	uint_fast32_t lon_1_idx = ( (uint_fast32_t)( ( lon_1 + 180.0 ) * max_size / 360.0 ) % max_size ) >> shift;
	
	if (lat_0_idx > lat_1_idx) {
		uint_fast32_t tmp = lat_1_idx;
		lat_1_idx = lat_0_idx;
		lat_0_idx = tmp;
	}
	
	/* Populate return values (all unsigned integers) */
	
	Inline_Stack_Reset;
	Inline_Stack_Push(sv_2mortal(newSVuv( grid_level )));
	Inline_Stack_Push(sv_2mortal(newSVuv( grid_size )));
	Inline_Stack_Push(sv_2mortal(newSVuv( max_grid_idx )));
	Inline_Stack_Push(sv_2mortal(newSVuv( lat_0_idx )));
	Inline_Stack_Push(sv_2mortal(newSVuv( lat_1_idx )));
	Inline_Stack_Push(sv_2mortal(newSVuv( lon_0_idx )));
	Inline_Stack_Push(sv_2mortal(newSVuv( lon_1_idx )));
	Inline_Stack_Done;
}




/*
   Compute distance between two points on a sphere
   
   diameter is in meters
   lat_0, lon_0, lat_1, and lon_1 are in radians
   Distance returned is in meters
   
   To compute a distance first call SetUpDistance(...) with the first point 
   then call HaversineDistance(...) to get the distance to a second point.
   
   The C version can use either floats or doubles whereas Perl uses doubles.  
   When using floats instead of doubles the loss of precision is typically less 
   than a meter (about 2 meters in the worst case).   On modern hardware there 
   should be little noticable difference between using floats and doubles.  On 
   older hardware or in embedded systems floats may give better performance.
*/


/* Functions using floats */

float f_diameter, f_lat_1, f_lon_1;
float f_cos_lat_1;

void SetUpDistance_float(float new_diameter, float new_lat_1, float new_lon_1) {
	f_diameter = new_diameter;
	f_lat_1 = new_lat_1;
	f_lon_1 = new_lon_1;
	f_cos_lat_1 = cosf( new_lat_1 );
}

float HaversineDistance_float(float lat_0, float lon_0) {
	float sin_lat_diff_over_2 = sinf( ( lat_0 - f_lat_1 ) / 2.0 );
	float sin_lon_diff_over_2 = sinf( ( lon_0 - f_lon_1 ) / 2.0 );
	
	float n = ( sin_lat_diff_over_2 * sin_lat_diff_over_2 ) 
	          + (
	              ( sin_lon_diff_over_2 * sin_lon_diff_over_2 )
	              * f_cos_lat_1
	              * cosf( lat_0 )
	            );
	
	/* The haversine formula may get messy around antipodal points so clip to the largest sane value. */
	if ( n < 0.0 ) { n = 0.0; }
	
	return f_diameter  * asinf( sqrtf(n) );
}



/* Functions using doubles */

double d_diameter, d_lat_1, d_lon_1;
double d_cos_lat_1;

void SetUpDistance_double(double new_diameter, double new_lat_1, double new_lon_1) {
	d_diameter = new_diameter;
	d_lat_1 = new_lat_1;
	d_lon_1 = new_lon_1;
	d_cos_lat_1 = cos( new_lat_1 );
}

double HaversineDistance_double(double lat_0, double lon_0) {
	double sin_lat_diff_over_2 = sin( ( lat_0 - d_lat_1 ) / 2.0 );
	double sin_lon_diff_over_2 = sin( ( lon_0 - d_lon_1 ) / 2.0 );
	
	double n = ( sin_lat_diff_over_2 * sin_lat_diff_over_2 ) 
	          + (
	              ( sin_lon_diff_over_2 * sin_lon_diff_over_2 )
	              * d_cos_lat_1
	              * cos( lat_0 )
	            );
	
	/* The haversine formula may get messy around antipodal points so clip to the largest sane value. */
	if ( n < 0.0 ) { n = 0.0; }
	
	return d_diameter  * asin( sqrt(n) );
}

/* End of C code */

MODULE = Geo::Index  PACKAGE = Geo::Index  

PROTOTYPES: DISABLE


unsigned int
GetCCodeVersion ()

unsigned int
fast_log2_double (n)
	double	n

unsigned int
fast_log2_float (n)
	float	n

void
ComputeAreaExtrema_float (tile_adjust, max_size, max_level, p_lat, p_lat_rad, p_lon, polar_circumference, search_radius)
	int	tile_adjust
	unsigned long	max_size
	unsigned int	max_level
	float	p_lat
	float	p_lat_rad
	float	p_lon
	float	polar_circumference
	float	search_radius
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        ComputeAreaExtrema_float(tile_adjust, max_size, max_level, p_lat, p_lat_rad, p_lon, polar_circumference, search_radius);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
ComputeAreaExtrema_double (tile_adjust, max_size, max_level, p_lat, p_lat_rad, p_lon, polar_circumference, search_radius)
	int	tile_adjust
	unsigned long	max_size
	unsigned int	max_level
	double	p_lat
	double	p_lat_rad
	double	p_lon
	double	polar_circumference
	double	search_radius
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        ComputeAreaExtrema_double(tile_adjust, max_size, max_level, p_lat, p_lat_rad, p_lon, polar_circumference, search_radius);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
SetUpDistance_float (new_diameter, new_lat_1, new_lon_1)
	float	new_diameter
	float	new_lat_1
	float	new_lon_1
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        SetUpDistance_float(new_diameter, new_lat_1, new_lon_1);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

float
HaversineDistance_float (lat_0, lon_0)
	float	lat_0
	float	lon_0

void
SetUpDistance_double (new_diameter, new_lat_1, new_lon_1)
	double	new_diameter
	double	new_lat_1
	double	new_lon_1
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        SetUpDistance_double(new_diameter, new_lat_1, new_lon_1);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

double
HaversineDistance_double (lat_0, lon_0)
	double	lat_0
	double	lon_0

