/*----------------------------------------------------------------*
 * This program is free software; you can redistribute it and/or
 * modify it under the same terms as Perl itself.
 *
 * Copyright (C) 2002-2014 Jens Thoms Toerring <jt@toerring.de>
 *----------------------------------------------------------------*/  


#include <stdio.h>
#include <stddef.h>
#include <stdlib.h>
#include <string.h>
#include <fcntl.h>
#include <limits.h>


#define membersize( type, member ) ( sizeof( ( ( type * ) NULL )->member ) )
#define NUM_ELEMS( p ) ( sizeof p / sizeof *p )


/* Structure for names, sizes and offsets of the flcok struct */

typedef struct {
    const char * name;
    size_t       size;
    size_t       offset;
}  Params;


/*-------------------------------------------------*
 * Called from qsort() for sorting an array of Params structures
 * in ascending order of their 'offset' members
 *-------------------------------------------------*/

static int
comp( const void * a,
      const void * b )
{
    if ( a == b )
        return 0;
    return ( ( Params * ) a )->offset < ( ( Params * ) b )->offset ? -1 : 1;
}


/*-------------------------------------------------*
 *-------------------------------------------------*/

int
main( void )
{
    Params params[ ] = { { "l_type",
                           CHAR_BIT * membersize( struct flock, l_type ),
                           CHAR_BIT * offsetof( struct flock, l_type ) },
                         { "l_whence",
                           CHAR_BIT * membersize( struct flock, l_whence ),
                           CHAR_BIT * offsetof( struct flock, l_whence ) },
                         { "l_start",
                           CHAR_BIT * membersize( struct flock, l_start ),
                           CHAR_BIT * offsetof( struct flock, l_start ) },
                         { "l_len",
                           CHAR_BIT * membersize( struct flock, l_len ),
                           CHAR_BIT * offsetof( struct flock, l_len ) },
                         { "l_pid",
                           CHAR_BIT * membersize( struct flock, l_pid ),
                           CHAR_BIT * offsetof( struct flock, l_pid ) } };
    size_t size = CHAR_BIT * sizeof( struct flock );
    size_t i;
    size_t pos = 0;
    char packstr[ 128 ] = "";

    /* All sizes and offsets must be divisable by 8 and the sizes of the
       members must be either 8-, 16-, 32- or 64-bit values, otherwise
       there's no good way to pack them. */

    if ( size % 8 )
        exit( EXIT_FAILURE );

    size /= 8;

    for ( i = 0; i < NUM_ELEMS( params ); ++i )
    {
        if (    params[ i ].size   % 8
             || params[ i ].offset % 8
             || (    params[ i ].size   != 8
                  && params[ i ].size   != 16
                  && params[ i ].size   != 32
                  && params[ i ].size   != 64 ) )
            exit( EXIT_FAILURE );

        params[ i ].size   /= 8;
        params[ i ].offset /= 8;
    }

    /* Sort the array of structures for the members in ascending order of
       the offset */

    qsort( params, NUM_ELEMS( params ), sizeof *params, comp );
    
    /* Cobble together the template string to be passed to pack(), taking
       care of padding and also extra members we're not interested in. All
       the interesting members have signed integer types. */

    for ( i = 0; i < NUM_ELEMS( params ); ++i )
    {
		if ( pos != params[ i ].offset )
			sprintf( packstr + strlen( packstr ), "x%lu",
					 ( unsigned long )( params[ i ].offset - pos ) );
		pos = params[ i ].offset;

        switch ( params[ i ].size )
        {
            case 1 :
				strcat( packstr, "c" );
                break;

            case 2 :
				strcat( packstr, "s" );
                break;

            case 4 :
				strcat( packstr, "l" );
                break;

            case 8 :
#if defined NO_Q_FORMAT
                /* There seem to be some 32-bit systems out there where off_t
                   is a 64-bit integer but Perl has no 'q' format for its
                   pack() and unpack() functions. For these  systemsthere
                   doesn't seem to be a good way for setting up the flock
                   structure properly using pure Perl. */

                exit( EXIT_FAILURE );
#endif
				strcat( packstr, "q" );
                break;

            default :
                exit( EXIT_FAILURE );
        }

		pos += params[ i ].size;
    }

    if ( pos < size )
        sprintf( packstr + strlen( packstr ), "x%lu",
                 (unsigned long ) ( size - pos ) );

    printf( "###########################################################\n\n"
            "# Method created automatically while running 'perl Makefile.PL'\n"
            "# (based on the the C 'struct flock' in <fcntl.h>) for packing\n"
            "# the data from the 'flock_struct' into a binary blob to be\n"
            "# passed to fcntl().\n\n"
            "sub pack_flock {\n"
            "    my $self = shift;\n"
            "    return pack( '%s',\n", packstr );
    for ( i = 0; i < NUM_ELEMS( params ); ++i )
		printf( "                 $self->{ %s }%s", params[ i ].name,
				i == NUM_ELEMS( params ) - 1 ? " " : ",\n" );

    printf( ");\n}\n\n\n"
            "###########################################################\n\n"
            "# Method created automatically while running 'perl Makefile.PL'\n"
            "# (based on the the C 'struct flock' in <fcntl.h>) for unpacking\n"
            "# the binary blob received from a call of fcntl() into the\n"
            "# 'flock_struct'.\n\n"
            "sub unpack_flock {\n"
            "     my ( $self, $data ) = @_;\n"
			"     ( " );

    for ( i = 0; i < NUM_ELEMS( params ); ++i )
        printf( "$self->{ %-8s }%s", params[ i ].name,
				i == NUM_ELEMS( params ) - 1 ? " " : ",\n       " );
	printf( ") = unpack( '%s', $data );\n}\n", packstr );

    return 0;
}

/*
 * Local variables:
 * tab-width: 4
 * indent-tabs-mode: nil
 * End:
 */
