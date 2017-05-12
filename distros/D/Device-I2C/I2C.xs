#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include "i2c-dev.h"


MODULE = Device::I2C		PACKAGE = Device::I2C PREFIX = I2C_
PROTOTYPES: DISABLE

int I2C__writeQuick(file, value)
    int file
    int value
  CODE:
    RETVAL = i2c_smbus_write_quick(file, value);
  OUTPUT:
    RETVAL

int I2C__checkDevice(file, value)
    int file
    int value
  CODE:
    RETVAL = i2c_smbus_check_device(file, value);
  OUTPUT:
    RETVAL

int I2C__readByte(file)
    int file
  CODE:
    RETVAL = i2c_smbus_read_byte(file);
  OUTPUT:
    RETVAL

int I2C__writeByte(file, value)
    int file
    int value
  CODE:
    RETVAL = i2c_smbus_write_byte(file, value);
  OUTPUT:
    RETVAL

int I2C__readByteData(file,command)
    int file
    int command
  CODE:
    RETVAL = i2c_smbus_read_byte_data(file, command);
  OUTPUT:
    RETVAL

int I2C__writeByteData(file, command, value)
    int file
    int command
    int value
  CODE:
    RETVAL = i2c_smbus_write_byte_data(file, command, value);
  OUTPUT:
    RETVAL

int I2C__readWordData(file, command)
    int file
    int command
  CODE:
    RETVAL = i2c_smbus_read_word_data(file, command);
  OUTPUT:
    RETVAL

int I2C__writeWordData(file, command, value)
    int file
    int command
    int value
  CODE:
    RETVAL = i2c_smbus_write_word_data(file, command, value);
  OUTPUT:
    RETVAL

int I2C__processCall(file, command, value)
    int file
    int command
    int value
  CODE:
    RETVAL = i2c_smbus_process_call(file, command, value);
  OUTPUT:
    RETVAL

int I2C__readBlockData(file, command, output)
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

int I2C__writeBlockData(file,command,value)
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

int I2C__blockProcessCall(file, command, value)
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

int I2C__readI2CBlockData(file, command, output)
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

int I2C__writeI2CBlockData(file, command, value)
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
