#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <k8055.h>

#include "const-c.inc"

MODULE = Device::Velleman::K8055::libk8055		PACKAGE = Device::Velleman::K8055::libk8055		

INCLUDE: const-xs.inc

int
ClearAllAnalog()

int
ClearAllDigital()

int
ClearAnalogChannel(channel)
	long	channel

int
ClearDigitalChannel(channel)
	long	channel

int
CloseDevice()

int
OpenDevice(board_address)
	long	board_address

int
OutputAllAnalog(data1, data2)
	long	data1
	long	data2

int
OutputAnalogChannel(channel, data)
	long	channel
	long	data

int
ReadAllAnalog(data1, data2)
	long *	data1
	long *	data2

long
ReadAllDigital()

long
ReadAnalogChannel(Channelno)
	long	Channelno

long
ReadCounter(counterno)
	long	counterno

int
ReadDigitalChannel(channel)
	long	channel

int
ResetCounter(counternr)
	long	counternr

int
SetAllAnalog()

int
SetAllDigital()

int
SetAnalogChannel(channel)
	long	channel

int
SetCounterDebounceTime(counterno, debouncetime)
	long	counterno
	long	debouncetime

int
SetDigitalChannel(channel)
	long	channel

int
WriteAllDigital(data)
	long	data
