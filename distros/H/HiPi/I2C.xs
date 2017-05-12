///////////////////////////////////////////////////////////////////////////////////////
// File          I2C.xs
// Description:  XS module for HiPi::Device::I2C
// Copyright:    Copyright (c) 2013-2017 Mark Dootson
// License:      This is free software; you can redistribute it and/or modify it under
//               the same terms as the Perl 5 programming language system itself.
///////////////////////////////////////////////////////////////////////////////////////

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "mylib/include/ppport.h"
#include "mylib/include/local-i2c-dev.h"
#include <linux/swab.h>

#define SCAN_MODE_AUTO    0
#define SCAN_MODE_QUICK   1
#define SCAN_MODE_READ    2

MODULE = HiPi::Device::I2C  PACKAGE = HiPi::Device::I2C

__s32
i2c_smbus_write_quick(file, value)
    int  file
    __u8 value
  CODE:
    RETVAL = i2c_smbus_write_quick(file, value);
    
  OUTPUT: RETVAL


__s32
i2c_smbus_read_byte( file )
    int file
  CODE:
    RETVAL = i2c_smbus_read_byte( file );
    
  OUTPUT: RETVAL


__s32
i2c_smbus_write_byte(file, value)
    int  file
    __u8 value
  CODE:
    RETVAL = i2c_smbus_write_byte( file, value );
    
  OUTPUT: RETVAL


__s32
i2c_smbus_read_byte_data(file, command )
    int  file
    __u8 command
  CODE:
    RETVAL = i2c_smbus_read_byte_data(file, command );
    
  OUTPUT: RETVAL


__s32
i2c_smbus_write_byte_data( file, command, value)
    int  file
    __u8 command
    __u8 value
  CODE:
    RETVAL = i2c_smbus_write_byte_data(file, command, value );
    
  OUTPUT: RETVAL


__s32
i2c_smbus_read_word_data(file, command)
    int  file
    __u8 command
  CODE:
    RETVAL = i2c_smbus_read_word_data(file, command );
    
  OUTPUT: RETVAL    


__s32
i2c_smbus_write_word_data( file, command, value)
    int   file
    __u8  command
    __u16 value
  CODE:
    RETVAL = i2c_smbus_write_word_data(file, command, value );
    
  OUTPUT: RETVAL


__s32
i2c_smbus_read_word_swapped(file, command)
    int  file
    __u8 command
  CODE:
    __s32 rval = i2c_smbus_read_word_data(file, command );
    RETVAL = (rval < 0) ? rval : __swab16(rval);
    
  OUTPUT: RETVAL    


__s32
i2c_smbus_write_word_swapped( file, command, value)
    int   file
    __u8  command
    __u16 value
  CODE:
    RETVAL = i2c_smbus_write_word_data(file, command, __swab16(value) );
    
  OUTPUT: RETVAL


__s32
i2c_smbus_process_call( file, command, value )
    int   file
    __u8  command
    __u16 value
  CODE:
    RETVAL = i2c_smbus_process_call(file, command, value );
    
  OUTPUT: RETVAL
  

void
i2c_smbus_read_block_data( file, command )
    int  file
    __u8 command
  PPCODE:
    int i;
    __u8 buf[32];
    int result = i2c_smbus_read_block_data(file, command, buf);
    if (result < 0) {
        EXTEND( SP, 1 );
        PUSHs(  &PL_sv_undef );
    } else {
        EXTEND( SP, (IV)result );
        for( i = 0; i < result; ++i )
        {
            SV* var = sv_newmortal();
            sv_setuv( var, (UV)buf[i] );
            PUSHs( var );
        }
    }
    

void
i2c_smbus_read_i2c_block_data( file, command, len )
    int  file
    __u8 command
    __u8 len
  PPCODE:
    int i;
    __u8 *buffer;
    buffer = malloc(len * sizeof(__u8));
    int result = i2c_smbus_read_i2c_block_data(file, command, len, buffer);
    if (result < 0) {
        EXTEND( SP, 1 );
        PUSHs(  &PL_sv_undef );
    } else {
        EXTEND( SP, (IV)result );
        for( i = 0; i < result; ++i )
        {
            SV* var = sv_newmortal();
            sv_setuv( var, (UV)buffer[i] );
            PUSHs( var );
        }
    }
    free( buffer );
    


__s32
i2c_smbus_write_block_data( file,  command, dataarray )
    int  file
    __u8 command
    SV*  dataarray
  CODE:
    STRLEN len;
    AV*  av;
    __u8 *buffer;
    int  i;
    
    if( !SvROK( dataarray ) || ( SvTYPE( (SV*) ( av = (AV*) SvRV( dataarray ) ) ) != SVt_PVAV ) )
    {
        croak( "the data array is not an array reference" );
        return;
    }
    
    len = av_len( av ) + 1;
    
    buffer = malloc(len * sizeof(__u8));
    
    for( i = 0; i < (int)len; ++i )
        buffer[i] = (__u8)SvUV(*av_fetch( av, i, 0 ));
    
    RETVAL = i2c_smbus_write_block_data(file, command, len, buffer);
    
    free( buffer);
    
  OUTPUT: RETVAL


__s32
i2c_smbus_write_i2c_block_data( file,  command, dataarray )
    int  file
    __u8 command
    SV*  dataarray
  CODE:
    STRLEN len;
    AV*    av;
    __u8   *buffer;
    int    i;
    
    if( !SvROK( dataarray ) || ( SvTYPE( (SV*) ( av = (AV*) SvRV( dataarray ) ) ) != SVt_PVAV ) )
    {
        croak( "the data array is not an array reference" );
        return;
    }
    
    len = av_len( av ) + 1;
    
    buffer = malloc(len * sizeof(__u8));
    
    for( i = 0; i < (int)len; ++i )
        buffer[i] = (__u8)SvUV(*av_fetch( av, i, 0 ));
    
    RETVAL = i2c_smbus_write_i2c_block_data(file, command, len, buffer);
    
    free( buffer );
    
  OUTPUT: RETVAL
  
int
_i2c_write( int file, __u16 address, unsigned char *wbuf,  __u16 wlen )
  CODE:
    int ret;
    struct i2c_rdwr_ioctl_data i2c_data;
    struct i2c_msg msg[1];
    i2c_data.msgs = msg;
    i2c_data.nmsgs = 1;             // use one message structure

    i2c_data.msgs[0].addr = address;
    i2c_data.msgs[0].flags = 0;     // don't need flags
    i2c_data.msgs[0].len = wlen;
    i2c_data.msgs[0].buf = (__u8 *)wbuf;

    ret = ioctl(file, I2C_RDWR, &i2c_data);
    
    if (ret < 0) {
        RETVAL = ret;
    } else {
        RETVAL = 0;
    }
  OUTPUT: RETVAL
    

int
_i2c_read( int file, __u16 address, unsigned char *rbuf, __u16 rlen)
  CODE:
    int ret;
    struct i2c_rdwr_ioctl_data  i2c_data;
    struct i2c_msg  msg[1];
   
    i2c_data.msgs = msg;
    i2c_data.nmsgs = 1;   
    i2c_data.msgs[0].addr = address;
    i2c_data.msgs[0].flags = I2C_M_RD; 
    i2c_data.msgs[0].len = rlen;
    i2c_data.msgs[0].buf = (__u8 *)rbuf;
    
    ret = ioctl(file, I2C_RDWR, &i2c_data);
    
    if (ret < 0) {
        RETVAL = ret;
    } else {
        RETVAL = 0;
    }

    OUTPUT: RETVAL
    
int
_i2c_read_register( int file, __u16 address, unsigned char *wbuf, unsigned char *rbuf, __u16 rlen)
  CODE:
    int ret;
    struct i2c_rdwr_ioctl_data  i2c_data;
    struct i2c_msg  msg[2];
   
    i2c_data.msgs = msg;
    i2c_data.nmsgs = 2;
    
    i2c_data.msgs[0].addr = address;
    i2c_data.msgs[0].flags = 0; 
    i2c_data.msgs[0].len = 1;
    i2c_data.msgs[0].buf = (__u8 *)wbuf;
    
    i2c_data.msgs[1].addr = address;
    i2c_data.msgs[1].flags = I2C_M_RD;
    i2c_data.msgs[1].len = rlen;
    i2c_data.msgs[1].buf = (__u8 *)rbuf;
    
    ret = ioctl(file, I2C_RDWR, &i2c_data);
    
    if (ret < 0) {
        RETVAL = ret;
    } else {
        RETVAL = 0;
    }

    OUTPUT: RETVAL

void
i2c_scan_bus( file,  mode = SCAN_MODE_AUTO,  first = 0x03, last = 0x77 )
    int file
    int mode
    int first
    int last
  PPCODE:
    int i;
    int j;
    int res;

    for (i = 0; i < 128; i += 16) {
        for(j = 0; j < 16; j++) {
            
            res = -1;
            
            /* Skip unwanted addresses */
            if (i+j < first || i+j > last) {
                continue;
            }

            /* Set slave address */
            if (ioctl(file, I2C_SLAVE, i+j) < 0) {
                continue;
            }

            /* Probe this address */
            switch (mode) {
                case SCAN_MODE_QUICK:
                    res = i2c_smbus_write_quick(file, I2C_SMBUS_WRITE);
                    break;
                case SCAN_MODE_READ:
                    res = i2c_smbus_read_byte(file);
                    break;
                default:
                    if ((i+j >= 0x30 && i+j <= 0x37) || (i+j >= 0x50 && i+j <= 0x5F))  {
                        res = i2c_smbus_read_byte(file);
                    } else {
                        res = i2c_smbus_write_quick(file, I2C_SMBUS_WRITE );
                    }
            }
            
            if (res >= 0) {
                EXTEND( SP, 1 );
                SV* var = sv_newmortal();
                sv_setuv( var, (UV)(i + j) );
                PUSHs( var );
            }
        }
    }

