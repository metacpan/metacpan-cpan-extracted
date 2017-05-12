///////////////////////////////////////////////////////////////////////////////////////
// File          wiring/Wiring.xs
// Description:  XS module for MyPi::Wiring
// Created       Fri Nov 23 12:13:43 2012
// SVN Id        $Id:$
// Copyright:    Copyright (c) 2012 Mark Dootson
// Licence:      This work is free software; you can redistribute it and/or modify it 
//               under the terms of the GNU General Public License as published by the 
//               Free Software Foundation; either version 3 of the License, or any later 
//               version.
///////////////////////////////////////////////////////////////////////////////////////

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "mylib/include/ppport.h"
#include <wiringPi.h>
#include <wiringSerial.h>
#include <wiringShift.h>
#include <wiringPiSPI.h>
#include <wiringPiI2C.h>

MODULE = HiPi::Wiring  PACKAGE = HiPi::Wiring

int
wiringPiSetup()

int
wiringPiSetupSys()

int
wiringPiSetupGpio()

int
piBoardRev()

int
wpiPinToGpio(wpiPin)
    int wpiPin

void
pinMode(pin, mode)
    int pin
    int mode
    
void
pullUpDnControl(pin, pud)
    int pin
    int pud

void
digitalWrite(pin, value)
    int pin
    int value

void
digitalWriteByte(value)
    int value
    
void
pwmWrite(pin, value)
    int pin
    int value

void
setPadDrive(group, value)
    int group
    int value
    
int
digitalRead(pin)
    int pin
    
void
delayMicroseconds(howLong)
    unsigned int howLong
    
void
pwmSetMode(mode)
    int mode
    
void
pwmSetRange(range)
    unsigned int range
    
void
pwmSetClock(divisor)
    int divisor


int
waitForInterrupt(pin, mS)
    int pin
    int mS

##// int
##// wiringPiISR(int pin, int mode, void (*function)(void)) ;

##// int
##// piThreadCreate (void *(*fn)(void *)) ;


void
piLock(key)
    int key

void
piUnlock(key)
    int key

int
piHiPri(pri)
    int pri


void
delay(howLong)
    unsigned int howLong

unsigned int
millis()

##// Gertboard

void
gertboardAnalogWrite(chan, value)
    int chan
    int value

int
gertboardAnalogRead(chan)
    int chan

int
gertboardSPISetup()

##// LCD

void
lcdHome(fd)
    int fd
    
void
lcdClear(fd)
    int fd
    
void
lcdPosition(fd, x, y)
    int fd
    int x
    int y
    
void
lcdPutchar(fd, data)
    int fd
    uint8_t data

void
lcdPuts(fd, putstring)
    int fd
    char* putstring

## //void
## //lcdPrintf(int fd, char *message, ...)

int
lcdInit (rows, cols, bits, rs, strb, d0, d1, d2, d3, d4, d5, d6, d7)
    int rows
    int cols
    int bits
    int rs
    int strb
    int d0
    int d1
    int d2
    int d3
    int d4
    int d5
    int d6
    int d7

##// NES Joystick

int
setupNesJoystick (dPin, cPin, lPin)
    int dPin
    int cPin
    int lPin
    
unsigned int
readNesJoystick (joystick)
    int joystick

##// Soft PWM

int
softPwmCreate(pin, value, range)
    int pin
    int value
    int range

void
softPwmWrite(pin, value)
    int pin
    int value
    
  
##// Soft Tone

int
softToneCreate(pin)
    int pin

void
softToneWrite(pin, frewq)
    int pin
    int frewq
    
##// I2C

int
wiringPiI2CRead(fd)
    int fd

int
wiringPiI2CReadReg8(fd, reg)
    int fd
    int reg

int
wiringPiI2CReadReg16(fd, reg)
    int fd
    int reg

int
wiringPiI2CWrite(fd, data)
    int fd
    int data

int
wiringPiI2CWriteReg8(fd, reg, data)
    int fd
    int reg
    int data
    
int
wiringPiI2CWriteReg16(fd, reg, data)
    int fd
    int reg
    int data
    
int
wiringPiI2CSetup(devId)
    int devId
    
##// SPI    

int
wiringPiSPIGetFd(channel)
    int channel

int
wiringPiSPIDataRW(channel, data, len)
    int channel
    unsigned char* data
    int len

int
wiringPiSPISetup(channel, speed)
    int channel
    int speed
    

##// Serial Port

int
serialOpen(device, baud)
    char* device
    int baud
    
void
serialClose(fd)
    int fd

void
serialFlush(fd)
    int fd
    
void
serialPutchar(fd, c)
    int fd
    unsigned char c

void
serialPuts(fd, s)
    int fd
    char* s

##// void  serialPrintf    (int fd, char *message, ...)

int
serialDataAvail(fd)
    int fd

int
serialGetchar(fd)
    int fd
    
##// Arduino type functions
uint8_t
shiftIn(dPin, cPin, order)
    uint8_t dPin
    uint8_t cPin
    uint8_t order

void
shiftOut(dPin, cPin, order, val)
    uint8_t dPin
    uint8_t cPin
    uint8_t order
    uint8_t val
