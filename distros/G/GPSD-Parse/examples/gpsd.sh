#!/bin/sh

sudo gpsd /dev/ttyUSB0 -n -F /var/log/gpsd.sock
