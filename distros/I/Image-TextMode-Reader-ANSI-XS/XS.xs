#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

typedef PerlIO *	InputStream;

#define S_TXT      0
#define S_CHK_B    1
#define S_WAIT_LTR 2
#define S_END      3

#define WRAP       80
#define TABSTOP    8

static void
store( image, x, y, c, attr, is_truecolor, rgb_f, rgb_b, wrap, width, height, pal )
    SV *image;
    int *x;
    int *y;
    unsigned char c;
    int attr;
    int is_truecolor;
    int *rgb_f;
    int *rgb_b;
    int wrap;
    int *width;
    int *height;
    AV *pal;
{
    HV *pixel = newHV();
    hv_store( pixel, "char", 4, newSVpvn( &c, 1 ), 0 );

    if( is_truecolor == 1 ) {
        AV *rgb = newAV();
        av_push( rgb, newSViv( rgb_f[ 0 ] ) );
        av_push( rgb, newSViv( rgb_f[ 1 ] ) );
        av_push( rgb, newSViv( rgb_f[ 2 ] ) );
        av_push( pal, newRV_noinc((SV *) rgb ) );
        hv_store( pixel, "fg", 2, newSViv( av_len( pal ) ), 0 );

        rgb = newAV();
        av_push( rgb, newSViv( rgb_b[ 0 ] ) );
        av_push( rgb, newSViv( rgb_b[ 1 ] ) );
        av_push( rgb, newSViv( rgb_b[ 2 ] ) );
        av_push( pal, newRV_noinc((SV *) rgb ) );
        hv_store( pixel, "bg", 2, newSViv( av_len( pal ) ), 0 );
    }
    else {
        hv_store( pixel, "attr", 4, newSViv( attr ), 0 );
    }

    AV *rows = (AV *) SvRV( *hv_fetch( (HV *) SvRV( image ), "pixeldata", 9, 0 ) );

    int newrow = 1;
    AV *row = newAV();
    SV **elem_p = av_fetch( rows, *y, FALSE );

    if( elem_p ) {
        row = (AV *) SvRV( *elem_p );
        newrow = 0;
    }

    av_store( row, *x, newRV_noinc((SV *) pixel ) );

    if( newrow ) {
        av_store( rows, *y, newRV_noinc((SV *) row) );
    }

    if( *x + 1 > *width ){
        *width = *x + 1;
    }

    if( *y + 1 > *height ){
        *height = *y + 1;
    }

    (*x)++;
    if( *x == wrap ) {
        *x = 0; (*y)++;
    }
}

static void
set_attrs( attr, args, pal, rgb_f, rgb_b ) // set the current attribute byte
    int *attr;
    AV *args;
    AV *pal;
    int *rgb_f;
    int *rgb_b;
{
    int i;
    int arg;
    int oldfg;
    int oldbg;
    AV *c;

    for( i = 0; i <= av_len( args ); i++ ) {
        arg = SvIV(* av_fetch( args, i, 0 ) );
        if ( arg == 0 ) {
            *attr = 7;
            c = (AV *) SvRV( *av_fetch( pal, 7, 0 ) );
            rgb_f[ 0 ] = SvIV(* av_fetch( c, 0, 0 ) ); 
            rgb_f[ 1 ] = SvIV(* av_fetch( c, 1, 0 ) ); 
            rgb_f[ 2 ] = SvIV(* av_fetch( c, 2, 0 ) ); 
            c = (AV *) SvRV( *av_fetch( pal, 0, 0 ) );
            rgb_b[ 0 ] = SvIV(* av_fetch( c, 0, 0 ) ); 
            rgb_b[ 1 ] = SvIV(* av_fetch( c, 1, 0 ) ); 
            rgb_b[ 2 ] = SvIV(* av_fetch( c, 2, 0 ) ); 
        }
        else if ( arg == 1 ) {
            *attr |= 8;
            c = (AV *) SvRV( *av_fetch( pal, *attr & 15, 0 ) );
            rgb_f[ 0 ] = SvIV(* av_fetch( c, 0, 0 ) ); 
            rgb_f[ 1 ] = SvIV(* av_fetch( c, 1, 0 ) ); 
            rgb_f[ 2 ] = SvIV(* av_fetch( c, 2, 0 ) ); 
        }
        else if ( arg == 2 || arg == 22 ) {
            *attr &= 247;
            c = (AV *) SvRV( *av_fetch( pal, *attr & 15, 0 ) );
            rgb_f[ 0 ] = SvIV(* av_fetch( c, 0, 0 ) ); 
            rgb_f[ 1 ] = SvIV(* av_fetch( c, 1, 0 ) ); 
            rgb_f[ 2 ] = SvIV(* av_fetch( c, 2, 0 ) ); 
        }
        else if ( arg == 5 ) {
            *attr |= 128;
            c = (AV *) SvRV( *av_fetch( pal, ( *attr & 240 ) >> 4, 0 ) );
            rgb_b[ 0 ] = SvIV(* av_fetch( c, 0, 0 ) ); 
            rgb_b[ 1 ] = SvIV(* av_fetch( c, 1, 0 ) ); 
            rgb_b[ 2 ] = SvIV(* av_fetch( c, 2, 0 ) ); 
        }
        else if ( arg == 7 || arg == 27 ) {
            oldfg = *attr & 15;
            oldbg = ( *attr & 240 ) >> 4;
            *attr = oldbg | ( oldfg << 4 );
            c = (AV *) SvRV( *av_fetch( pal, *attr & 15, 0 ) );
            rgb_f[ 0 ] = SvIV(* av_fetch( c, 0, 0 ) ); 
            rgb_f[ 1 ] = SvIV(* av_fetch( c, 1, 0 ) ); 
            rgb_f[ 2 ] = SvIV(* av_fetch( c, 2, 0 ) ); 
            c = (AV *) SvRV( *av_fetch( pal, ( *attr & 240 ) >> 4, 0 ) );
            rgb_b[ 0 ] = SvIV(* av_fetch( c, 0, 0 ) ); 
            rgb_b[ 1 ] = SvIV(* av_fetch( c, 1, 0 ) ); 
            rgb_b[ 2 ] = SvIV(* av_fetch( c, 2, 0 ) ); 
        }
        else if ( arg == 25 ) {
            *attr &= 127;
            c = (AV *) SvRV( *av_fetch( pal, ( *attr & 240 ) >> 4, 0 ) );
            rgb_b[ 0 ] = SvIV(* av_fetch( c, 0, 0 ) ); 
            rgb_b[ 1 ] = SvIV(* av_fetch( c, 1, 0 ) ); 
            rgb_b[ 2 ] = SvIV(* av_fetch( c, 2, 0 ) ); 
        }
        else if ( arg >= 30 && arg <= 37 ) {
            *attr &= 248;
            *attr |= ( arg - 30 );
            c = (AV *) SvRV( *av_fetch( pal, *attr & 15, 0 ) );
            rgb_f[ 0 ] = SvIV(* av_fetch( c, 0, 0 ) ); 
            rgb_f[ 1 ] = SvIV(* av_fetch( c, 1, 0 ) ); 
            rgb_f[ 2 ] = SvIV(* av_fetch( c, 2, 0 ) ); 
        }
        else if ( arg >= 40 && arg <= 47 ) {
            *attr &= 143;
            *attr |= ( ( arg - 40 ) << 4 );
            c = (AV *) SvRV( *av_fetch( pal, ( *attr & 240 ) >> 4, 0 ) );
            rgb_b[ 0 ] = SvIV(* av_fetch( c, 0, 0 ) ); 
            rgb_b[ 1 ] = SvIV(* av_fetch( c, 1, 0 ) ); 
            rgb_b[ 2 ] = SvIV(* av_fetch( c, 2, 0 ) ); 
        }
    }
}

MODULE = Image::TextMode::Reader::ANSI::XS		PACKAGE = Image::TextMode::Reader::ANSI::XS

PROTOTYPES: DISABLE

SV *
_read( self, image, file, options )
    SV *self
    SV *image
    InputStream file
    HV *options
PREINIT:
    unsigned char c;
    int state = S_TXT;
    unsigned char argbuf[ 255 ];
    int arg_index = 0;
    int x = 0;
    int y = 0;
    int save_x = 0;
    int save_y = 0;
    int attr = 7;
    int wrap = WRAP;
    int width = 0;
    int height = 0;
    int filesize = 0;
    int is_truecolor = 0;
    int rgb_f[3];
    int rgb_b[3];
    AV *args = newAV();
CODE:
    int i;
    int count;
    char *feature;
    SV **temp_pv;
    sv_2mortal( (SV * ) args );

    // render options hashref
    HV *render_opts = (HV *) SvRV( *hv_fetch( (HV *) SvRV( image ), "render_options", 14, 0 ) );

    // palette
    AV *pal = (AV *) SvRV( *hv_fetch( (HV *) SvRV( *hv_fetch( (HV *) SvRV( image ), "palette", 7, 0 ) ), "colors", 6, 0 ) );

    // get options
    if( hv_exists( options, "width", 5 ) ) {
        wrap = SvIV(* hv_fetch( options, "width", 5, 0 ) );
    }

    if( !wrap ) {
        wrap = WRAP;
    }

    // blink mode
    SV *saucerec  = *hv_fetch( (HV *) SvRV( image ), "sauce", 5, 0 );
        if( hv_exists( (HV *) SvRV( saucerec ), "has_sauce", 9 ) ) {
        SV *has_sauce = *hv_fetch( (HV *) SvRV( saucerec ), "has_sauce", 9, 0 );
        if( SvOK( has_sauce ) && SvTRUE( has_sauce ) ) {
            int flags = SvIV( *hv_fetch( (HV *) SvRV( saucerec ), "flags_id", 8, 0 ) );
            hv_store( render_opts, "blink_mode", 10, newSViv( 0 ), (flags & 1) ^ 1 );
        }
    }

    filesize = SvIV(* hv_fetch( options, "filesize", 8, 0 ) );

    PerlIO_rewind( file );

    while ( state != S_END && ( c = PerlIO_getc( file ) ) != -1 && !PerlIO_eof( file ) && PerlIO_tell( file ) <= filesize ) {
        switch ( state ) {
            case S_TXT      : // parse text
                switch( c ) {
                    case '\x1a' : state = S_END; break;
                    case '\x1b' : state = S_CHK_B; break;
                    case '\n'   :
                        x = 0; y++;
                    case '\r'   : break;
                    case '\t'   :
                        count = ( x + 1 ) % TABSTOP;
                        if( count ) {
                            count = TABSTOP - count;
                            for ( i = 0; i < count; i++ ) {
                                store( image, &x, &y, ' ', attr, is_truecolor, &rgb_f, &rgb_b, wrap, &width, &height, pal );
                            }
                        }
                        break;
                    default :
                        store( image, &x, &y, c, attr, is_truecolor, &rgb_f, &rgb_b, wrap, &width, &height, pal );
                        break;
                }
                break;
            case S_CHK_B    : // check for a left square bracket
                if( c != '[' ) {
                    store( image, &x, &y, '\x1b', attr, is_truecolor, &rgb_f, &rgb_b, wrap, &width, &height, pal );
                    store( image, &x, &y, c, attr, is_truecolor, &rgb_f, &rgb_b, wrap, &width, &height, pal );
                    state = S_TXT;
                }
                else {
                    state = S_WAIT_LTR;
                }
                break;
            case S_WAIT_LTR : // wait for a letter to exec. a command
                if ( isALPHA( c ) || c == ';' ) {
                    argbuf[arg_index] = 0;
                    av_push( args, newSVpv( argbuf, 0 ) );
                    arg_index = 0;
                    if( c == ';' )
                        break;
                }

                if ( isALPHA( c ) ) {
                    switch( c ) {
                        case 'm' : // set attributes
                            set_attrs( &attr, args, pal, rgb_f, rgb_b );
                            break;
                        case 'H' : // set position
                        case 'f' :
                            temp_pv = av_fetch( args, 0, TRUE );
                            y = looks_like_number( *temp_pv ) ? SvIV( *temp_pv ) : 1;
                            temp_pv = av_fetch( args, 1, TRUE );
                            x = looks_like_number( *temp_pv ) ? SvIV( *temp_pv ) : 1;
                            y--;
                            x--;
                            if( y < 0 ) y = 0;
                            if( x < 0 ) x = 0;
                            break;
                        case 'A' : // move up
                            temp_pv = av_fetch( args, 0, TRUE );
                            i = looks_like_number( *temp_pv ) ? SvIV( *temp_pv ) : 1;
                            y -= i;
                            if( y < 0 ) y = 0;
                            break;
                        case 'B' : // move down
                            temp_pv = av_fetch( args, 0, TRUE );
                            i = looks_like_number( *temp_pv ) ? SvIV( *temp_pv ) : 1;
                            y += i;
                            break;
                        case 'C' : // move right
                            temp_pv = av_fetch( args, 0, TRUE );
                            i = looks_like_number( *temp_pv ) ? SvIV( *temp_pv ) : 1;
                            x += i;
                            break;
                        case 'D' : // move left
                            temp_pv = av_fetch( args, 0, TRUE );
                            i = looks_like_number( *temp_pv ) ? SvIV( *temp_pv ) : 1;
                            x -= i;
                            if( x < 0 ) x = 0;
                            break;
                        case 'E' : // next line
                            temp_pv = av_fetch( args, 0, TRUE );
                            i = looks_like_number( *temp_pv ) ? SvIV( *temp_pv ) : 1;
                            x = 0;
                            y += i;
                            break;
                        case 'F' : // previous line
                            temp_pv = av_fetch( args, 0, TRUE );
                            i = looks_like_number( *temp_pv ) ? SvIV( *temp_pv ) : 1;
                            x = 0;
                            y -= i;
                            if( y < 0 ) y = 0;
                            break;
                        case 'G' : // horizontal move
                            temp_pv = av_fetch( args, 0, TRUE );
                            i = looks_like_number( *temp_pv ) ? SvIV( *temp_pv ) : 1;
                            x = i - 1;
                            break;
                        case 'h' : // feature on
                            feature = av_len( args ) < 0 ? "" : SvPV_nolen(* av_fetch( args, 0, 0 ) );
                            if( strcmp( feature, "?33" ) == 0 ) {
                                hv_store( render_opts, "blink_mode", 10, newSViv( 0 ), 0 );
                            }
                            break;
                        case 'l' : // feature off
                            feature = av_len( args ) < 0 ? "" : SvPV_nolen(* av_fetch( args, 0, 0 ) );
                            if( strcmp( feature, "?33" ) == 0 ) {
                                hv_store( render_opts, "blink_mode", 10, newSViv( 1 ), 0 );
                            }
                            break;
                        case 's' : // save position
                            save_x = x; save_y = y;
                            break;
                        case 't' : // rgb palette set
                            hv_store( render_opts, "truecolor", 9, newSViv( 1 ), 0 );
                            is_truecolor = 1;
                            i = SvIV(* av_fetch( args, 0, TRUE ) );
                            if( i == 0 ) {
                                rgb_b[ 0 ] = SvIV(* av_fetch( args, 1, TRUE ) );
                                rgb_b[ 1 ] = SvIV(* av_fetch( args, 2, TRUE ) );
                                rgb_b[ 2 ] = SvIV(* av_fetch( args, 3, TRUE ) );
                            }
                            else {
                                rgb_f[ 0 ] = SvIV(* av_fetch( args, 1, TRUE ) );
                                rgb_f[ 1 ] = SvIV(* av_fetch( args, 2, TRUE ) );
                                rgb_f[ 2 ] = SvIV(* av_fetch( args, 3, TRUE ) );
                            }
                            break;
                        case 'u' : // restore position
                            x = save_x; y = save_y;
                            break;
                        case 'J' : // clear screen
                            temp_pv = av_fetch( args, 0, TRUE );
                            i = looks_like_number( *temp_pv ) ? SvIV( *temp_pv ) : 0;

                            if( !i ) {
                                int row;
                                int next = y + 1;
                                for( row = 1; row <= height - next + 1; row++ ) {
                                    ENTER;
                                    SAVETMPS;
                                    PUSHMARK( SP );
                                    XPUSHs( image );
                                    XPUSHs( sv_2mortal( newSViv( next ) ) );
                                    PUTBACK;
                                    call_method( "delete_line", G_DISCARD | G_VOID );
                                    SPAGAIN;
                                    FREETMPS;
                                    LEAVE;
                                    height--;
                                }

                                ENTER;
                                SAVETMPS;
                                PUSHMARK( SP );
                                XPUSHs( image );
                                XPUSHs( sv_2mortal( newSViv( y ) ) );
                                AV *cols = newAV();
                                av_store( cols, 0, newSViv( x ) );
                                av_store( cols, 1, newSViv( -1 ) );
                                XPUSHs( sv_2mortal( newRV_noinc((SV *) cols) ) );
                                PUTBACK;
                                call_method( "clear_line", G_DISCARD | G_VOID );
                                SPAGAIN;
                                FREETMPS;
                                LEAVE;
                            }
                            else if( i == 1 ) {
                                int row;
                                for( row = 0; row < y; row++ ) {
                                    ENTER;
                                    SAVETMPS;
                                    PUSHMARK( SP );
                                    XPUSHs( image );
                                    XPUSHs( sv_2mortal( newSViv( row ) ) );
                                    PUTBACK;
                                    call_method( "clear_line", G_DISCARD | G_VOID );
                                    SPAGAIN;
                                    FREETMPS;
                                    LEAVE;
                                }

                                ENTER;
                                SAVETMPS;
                                PUSHMARK( SP );
                                XPUSHs( image );
                                XPUSHs( sv_2mortal( newSViv( y ) ) );
                                AV *cols = newAV();
                                av_store( cols, 0, newSViv( 0 ) );
                                av_store( cols, 1, newSViv( x ) );
                                XPUSHs( sv_2mortal( newRV_noinc((SV *) cols) ) );
                                PUTBACK;
                                call_method( "clear_line", G_DISCARD | G_VOID );
                                SPAGAIN;
                                FREETMPS;
                                LEAVE;
                            }
                            else if( i == 2 ) {
                                ENTER;
                                SAVETMPS;
                                PUSHMARK( SP );
                                XPUSHs( image );
                                PUTBACK;
                                call_method( "clear_screen", G_DISCARD | G_VOID );
                                SPAGAIN;
                                FREETMPS;
                                LEAVE;
                                width = 0;
                                height = 0;
                                x = 0;
                                y = 0;
                            }
                            break;
                        case 'K' : // clear line
                            temp_pv = av_fetch( args, 0, TRUE );
                            i = looks_like_number( *temp_pv ) ? SvIV( *temp_pv ) : 0;

                            ENTER;
                            SAVETMPS;
                            PUSHMARK( SP );
                            XPUSHs( image );
                            XPUSHs( sv_2mortal( newSViv( y ) ) );

                            if( !i ) {
                                AV *cols = newAV();
                                av_store( cols, 0, newSViv( x ) );
                                av_store( cols, 1, newSViv( -1 ) );
                                XPUSHs( sv_2mortal( newRV_noinc((SV *) cols) ) );
                            }
                            else if( i == 1 ) {
                                AV *cols = newAV();
                                av_store( cols, 0, newSViv( 0 ) );
                                av_store( cols, 1, newSViv( x ) );
                                XPUSHs( sv_2mortal( newRV_noinc((SV *) cols) ) );
                            }
                            else if( i == 2 ) { // no additional args
                            }

                            PUTBACK;
                            call_method( "clear_line", G_DISCARD | G_VOID );
                            SPAGAIN;
                            FREETMPS;
                            LEAVE;

                            break;
                        default:
                            break;
                    }
                    av_clear( args );
                    state = S_TXT;
                    break;
                }
                argbuf[ arg_index ] = c; 
                arg_index++;
                break;
            case S_END      : // done parsing
            default         : break;
        }
    }

    // set width + height of the image
    ENTER;
    SAVETMPS;
    PUSHMARK( SP );
    XPUSHs( image );
    XPUSHs( sv_2mortal( newSViv( width ) ) );
    PUTBACK;
    call_method( "width", G_DISCARD | G_VOID );
    SPAGAIN;
    FREETMPS;
    LEAVE;

    ENTER;
    SAVETMPS;
    PUSHMARK( SP );
    XPUSHs( image );
    XPUSHs( sv_2mortal( newSViv( height ) ) );
    PUTBACK;
    call_method( "height", G_DISCARD | G_VOID );
    SPAGAIN;
    FREETMPS;
    LEAVE;

    RETVAL = SvREFCNT_inc( image );
OUTPUT:
    RETVAL
