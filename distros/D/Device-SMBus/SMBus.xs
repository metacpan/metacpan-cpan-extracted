#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include "i2c-dev.h"


MODULE = Device::SMBus		PACKAGE = Device::SMBus PREFIX = SMBus_
PROTOTYPES: DISABLE

int SMBus__writeQuick(file, value)
    int file
    int value
  CODE:
    RETVAL = i2c_smbus_write_quick(file, value);
  OUTPUT:
    RETVAL

int SMBus__readByte(file)
    int file
  CODE:
    RETVAL = i2c_smbus_read_byte(file);
  OUTPUT:
    RETVAL

int SMBus__writeByte(file, value)
    int file
    int value
  CODE:
    RETVAL = i2c_smbus_write_byte(file, value);
  OUTPUT:
    RETVAL

int SMBus__readByteData(file,command)
    int file
    int command
  CODE:
    RETVAL = i2c_smbus_read_byte_data(file, command);
  OUTPUT:
    RETVAL
  

int SMBus__writeByteData(file, command, value)
    int file
    int command
    int value
  CODE:
    RETVAL = i2c_smbus_write_byte_data(file, command, value);
  OUTPUT:
    RETVAL

int SMBus__readWordData(file, command)
    int file
    int command
  CODE:
    RETVAL = i2c_smbus_read_word_data(file, command);
  OUTPUT:
    RETVAL

int SMBus__writeWordData(file, command, value)
    int file
    int command
    int value
  CODE:
    RETVAL = i2c_smbus_write_word_data(file, command, value);
  OUTPUT:
    RETVAL

int SMBus__processCall(file, command, value)
    int file
    int command
    int value
  CODE:
    RETVAL = i2c_smbus_process_call(file, command, value);
  OUTPUT:
    RETVAL

int SMBus__readBlockData(file, command, output)
    int file
    int command
    SV * output
  INIT:
    char buf[ 32 ];
    int ret;
  CODE:
    ret = i2c_smbus_read_block_data(file, command, buf);
    if (ret == -1)
      RETVAL = ret;
    sv_setpvn(output, buf, ret);
    RETVAL = ret;
  OUTPUT:
    RETVAL

int SMBus__writeBlockData(file,command,value)
    int file
    int command
    SV * value
  INIT:
    STRLEN len;
    char *buf = SvPV(value, len);
  CODE:
    RETVAL = i2c_smbus_write_block_data(file, command, len, buf);
  OUTPUT:
    RETVAL

int SMBus__blockProcessCall(file, command, value)
    int file
    int command
    SV * value
  INIT:
    STRLEN len;
    char *buf = SvPV(value, len);
  CODE:
    RETVAL = i2c_smbus_block_process_call(file, command, len, buf);
  OUTPUT:
    RETVAL

int SMBus__readI2CBlockData(file, command, output)
    int file
    int command
    SV * output 
  INIT:
    STRLEN len;
    char *buf = SvPV(output, len);
    int ret;
  CODE:
    ret = i2c_smbus_read_i2c_block_data(file, command, len, buf);
    if (ret == -1)
      RETVAL = ret;
    sv_setpvn(output, buf, ret);
    RETVAL = ret;
  OUTPUT:
    RETVAL

int SMBus__writeI2CBlockData(file, command, value)
    int file
    int command
    SV * value
  INIT:
    STRLEN len;
    char *buf = SvPV(value, len);
  CODE:
    RETVAL = i2c_smbus_write_i2c_block_data(file, command, len, buf);
  OUTPUT:
    RETVAL
