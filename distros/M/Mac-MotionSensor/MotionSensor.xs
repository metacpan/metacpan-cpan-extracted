#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

#include "unimotion.h"
#include <stdio.h>

int _get_raw_x(int type) {
	int x, y, z;
	if( read_sms_raw(type, &x, &y, &z) ) {
		return x;
	}
}

int _get_raw_y(int type) {
	int x, y, z;
	if( read_sms_raw(type, &x, &y, &z) ) {
		return y;
	}
}

int _get_raw_z(int type) {
	int x, y, z;
	if( read_sms_raw(type, &x, &y, &z) ) {
		return z;
	}
}

int _get_x(int type) {
	int x, y, z;
	if( read_sms(type, &x, &y, &z) ) {
		return x;
	}
}

int _get_y(int type) {
	int x, y, z;
	if( read_sms(type, &x, &y, &z) ) {
		return y;
	}
}

int _get_z(int type) {
	int x, y, z;
	if( read_sms(type, &x, &y, &z) ) {
		return z;
	}
}

MODULE = Mac::MotionSensor		PACKAGE = Mac::MotionSensor		

int
detect_sms()

int
_get_raw_x(type)
	int type

int
_get_raw_y(type)
	int type

int
_get_raw_z(type)
	int type

int
_get_x(type)
	int type

int
_get_y(type)
	int type

int
_get_z(type)
	int type
