#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <stdio.h>
#include <stdlib.h>
#include "wiimote.h"
#include "wiimote_api.h"

wiimote_t wiimote = WIIMOTE_INIT;

MODULE = Linux::Input::Wiimote         PACKAGE = Linux::Input::Wiimote

PROTOTYPES: DISABLE

char * c_wiimote_discover()
     CODE:
          wiimote_t wiimote[4];
          int nmotes = 0;
          int i = 0;
          nmotes = wiimote_discover(wiimote, 4);
          RETVAL = " ";
          if ( nmotes > 0 ) {
             for (i=0; i<nmotes; i++) {
                RETVAL =  wiimote[i].link.r_addr;
             }
          } else {
             RETVAL = "0";
          }

     OUTPUT:
          RETVAL


int c_wiimote_connect(const char *arg)
     CODE:
          RETVAL = wiimote_connect(&wiimote, arg );
     OUTPUT:
          RETVAL

int c_wiimote_is_open()
     CODE:
          RETVAL = wiimote_is_open(&wiimote);
     OUTPUT:
          RETVAL

int c_wiimote_update()
     CODE:
          RETVAL = wiimote_update(&wiimote);
     OUTPUT:
          RETVAL

int c_wiimote_disconnect()
     CODE:
          RETVAL =  wiimote_disconnect(&wiimote);
     OUTPUT:
          RETVAL

int c_get_wiimote_keys_raw_bits()
     CODE:
          RETVAL =  wiimote.keys.bits;
     OUTPUT:
          RETVAL
    
int c_get_wiimote_rumble()
     CODE:
          RETVAL =  wiimote.rumble;
     OUTPUT:
          RETVAL

void c_set_wiimote_rumble(int arg)
     CODE:
          wiimote.rumble = arg;
          
int c_get_wiimote_ir()
     CODE:
          RETVAL =  wiimote.mode.ir;
     OUTPUT:
          RETVAL

void c_set_wiimote_ir(int arg)
     CODE:
          wiimote.mode.ir = arg;
          
int c_get_wiimote_ext_nunchuk_joyx()
     CODE:
          RETVAL =  wiimote.ext.nunchuk.joyx;
     OUTPUT:
          RETVAL

int c_get_wiimote_ext_nunchuk_joyy()
     CODE:
          RETVAL =  wiimote.ext.nunchuk.joyy;
     OUTPUT:
          RETVAL

int c_get_wiimote_ext_nunchuk_keys_c()
     CODE:
          RETVAL =  wiimote.ext.nunchuk.keys.c;
     OUTPUT:
          RETVAL

int c_get_wiimote_ext_nunchuk_keys_z()
     CODE:
          RETVAL =  wiimote.ext.nunchuk.keys.z;
     OUTPUT:
          RETVAL

int c_get_wiimote_ext_nunchuk_axis_x()
     CODE:
          RETVAL =  wiimote.ext.nunchuk.axis.x;
     OUTPUT:
          RETVAL

int c_get_wiimote_ext_nunchuk_axis_y()
     CODE:
          RETVAL =  wiimote.ext.nunchuk.axis.y;
     OUTPUT:
          RETVAL

int c_get_wiimote_ext_nunchuk_axis_z()
     CODE:
          RETVAL =  wiimote.ext.nunchuk.axis.z;
     OUTPUT:
          RETVAL

int c_get_wiimote_axis_x()
     CODE:
          RETVAL =  wiimote.axis.x;
     OUTPUT:
          RETVAL

int c_get_wiimote_axis_y()
     CODE:
          RETVAL =  wiimote.axis.y;
     OUTPUT:
          RETVAL

int c_get_wiimote_axis_z()
     CODE:
          RETVAL =  wiimote.axis.z;
     OUTPUT:
          RETVAL

float c_get_wiimote_tilt_x()
     CODE:
          RETVAL =  wiimote.tilt.x;
     OUTPUT:
          RETVAL


float c_get_wiimote_tilt_y()
     CODE:
          RETVAL =  wiimote.tilt.y;
     OUTPUT:
          RETVAL

float c_get_wiimote_tilt_z()
     CODE:
          RETVAL =  wiimote.tilt.z;
     OUTPUT:
          RETVAL

void c_activate_wiimote_accelerometer()
     CODE:
           wiimote.mode.acc = 1;

void c_deactivate_wiimote_accelerometer()
     CODE:
           wiimote.mode.acc = 0;

int c_get_wiimote_ir1_x()
     CODE:
          RETVAL =  wiimote.ir1.x;
     OUTPUT:
          RETVAL

int c_get_wiimote_ir1_y()
     CODE:
          RETVAL =  wiimote.ir1.y;
     OUTPUT:
          RETVAL

int c_get_wiimote_ir1_size()
     CODE:
          RETVAL =  wiimote.ir1.size;
     OUTPUT:
          RETVAL

int c_get_wiimote_ir2_x()
     CODE:
          RETVAL =  wiimote.ir2.x;
     OUTPUT:
          RETVAL

int c_get_wiimote_ir2_y()
     CODE:
          RETVAL =  wiimote.ir2.y;
     OUTPUT:
          RETVAL

int c_get_wiimote_ir2_size()
     CODE:
          RETVAL =  wiimote.ir2.size;
     OUTPUT:
          RETVAL

int c_get_wiimote_ir3_x()
     CODE:
          RETVAL =  wiimote.ir3.x;
     OUTPUT:
          RETVAL

int c_get_wiimote_ir3_y()
     CODE:
          RETVAL =  wiimote.ir3.y;
     OUTPUT:
          RETVAL

int c_get_wiimote_ir3_size()
     CODE:
          RETVAL =  wiimote.ir3.size;
     OUTPUT:
          RETVAL

int c_get_wiimote_ir4_x()
     CODE:
          RETVAL =  wiimote.ir4.x;
     OUTPUT:
          RETVAL

int c_get_wiimote_ir4_y()
     CODE:
          RETVAL =  wiimote.ir4.y;
     OUTPUT:
          RETVAL

int c_get_wiimote_ir4_size()
     CODE:
          RETVAL =  wiimote.ir4.size;
     OUTPUT:
          RETVAL

float c_get_wiimote_force_x()
     CODE:
          RETVAL =  wiimote.force.x;
     OUTPUT:
          RETVAL

float c_get_wiimote_force_y()
     CODE:
          RETVAL =  wiimote.force.y;
     OUTPUT:
          RETVAL

float c_get_wiimote_force_z()
     CODE:
          RETVAL =  wiimote.force.z;
     OUTPUT:
          RETVAL
