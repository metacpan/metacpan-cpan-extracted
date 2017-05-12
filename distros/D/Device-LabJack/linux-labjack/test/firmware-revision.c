/*
 * Makefile for labjack test applications
 *
 * Copyright (c) 2003 Eric Sorton <erics@cfl.rr.com>
 *
 * This program is free software; you can redistribute it and/or modify it
 * under the terms of the GNU General Public License as published by the Free
 * Software Foundation; either version 2 of the License, or (at your option)
 * any later version.
 */


#include <ljackul.h>
#include <unistd.h>
#include <stdlib.h>
#include <stdio.h>

int main(int argc, char *argv[])
{
    long idnum = -1;
    float version;
    
    version = GetFirmwareVersion(&idnum);
    printf("version: %f\n", version);
    return 0;
 
}
