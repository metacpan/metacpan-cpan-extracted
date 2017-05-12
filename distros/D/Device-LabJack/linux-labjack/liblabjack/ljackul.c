//---------------------------------------------------------------------------
//
//  ljackul.c        
//
//  support@labjack.com
//  6/2004
//
// This program is free software; you can redistribute it and/or modify it
// under the terms of the GNU General Public License as published by the Free
// Software Foundation; either version 2 of the License, or (at your option)
// any later version.
//----------------------------------------------------------------------
//
// Based on Windows ljackuw.dll V1.16 and ljackv112.c (modified by 
// Eric Sorton) template code
//
//
// The key functions that will require customization for a
// particular OS are:
//
// OpenLabJack
// WriteLabJack
// ReadLabJack
// CloseAll
//
// The LabJack U12 is an HID V1.1 device.  Input and Output reports
// are both 8 bytes (although Windows throws on an extra byte
// at the beginning).  Feature reports are used to transfer stream
// and burst data from the LabJack to the PC, and are 16*8 or 128
// bytes (plus the extra Windows byte at the beginning).
//
// The first time after enumeration that the LabJack is supposed to
// write 8 bytes to the interrupt IN endpoint, the write does not
// happen.  Windows reads nothing. This initial non-response provides
// a good test of the thread timeout we use in our Windows HID
// read function.  You will probably see this behavior on other
// operating systems.
//
//----------------------------------------------------------------------
//
// Changes
// 
// (08/18/2005) Fixed problem in OpenLabJack when *idnum is 0.  Updated
//              version to 1.181.
// 
// (01/17/2005) Added a read after the dummy write in OpenLabJack and 
//              ListAll.  Should help with programs only working once.
//
//-----------------------------------------------------------------------

#include <stdio.h>
#include <math.h>
#include <sys/time.h>
#include <unistd.h>
#include <string.h>
//#include <pthread.h>

/* (efs) Macros to replace those lost in bitops.h
 */
#define BitSet(arg,posn) ((arg) | (1L << (posn)))
#define BitClr(arg,posn) ((arg) & ~(1L << (posn)))
#define BitFlp(arg,posn) ((arg) ^ (1L << (posn)))
#define BitTst(arg,posn) (!(!((arg) & (1L << (posn)))))

/* (efs) added include files, these are probably needed in the real driver for
 * standards compliance */
#include <stdlib.h>

/* (efs) Needed for open
 */
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>

/* (efs) typedefs to convert from windows to Linux */
typedef int HANDLE;
typedef long DWORD;
typedef unsigned short USHORT;
typedef unsigned long ULONG;
#define WINAPI
#define _stdcall

/* (efs) Are these defined somewhere standard? */
#define TRUE 1
#define FALSE 0

/* (efs) sleep in windows is milliseconds, convert to microseconds for Linux */
#define Sleep(a) usleep((a)*1000)

/* (efs) implement GetTickCount() for Linux */
long GetTickCount() {
	struct timeval tv;

	gettimeofday(&tv, NULL);

	return (tv.tv_sec * 1000) + (tv.tv_usec / 1000);
}

#include "ljackul.h"

#define VERSION (float)1.181
#define LABJACK_VENDOR_ID (USHORT)3285
#define LABJACK_U12_PRODUCT_ID (USHORT)0001
#define INPUT_BUFFER_SIZE_LJ (ULONG)198
#define RAM_BUFF_ROWS 64
#define MAX_DEVICES_LJ 256	//local ID range determines this
#define FCDD_MAX 128
#define READ_TIMEOUT_MS 2000
#define MAX_LABJACKS 16

#define NO_ERROR_LJ (long)0   //must be 0
#define UNKNOWN_ERROR_LJ (long)1
#define NO_DEVICES_FOUND_LJ (long)2
#define DEVICE_N_NOT_FOUND_LJ (long)3
#define	SET_BUFFER_ERROR_LJ (long)4
#define OPEN_HANDLE_ERROR_LJ (long)5
#define CLOSE_HANDLE_ERROR_LJ (long)6
#define INVALID_ID_LJ (long)7
#define ARRAY_SIZE_OR_VALUE_ERROR_LJ (long)8
#define	INVALID_POWER_INDEX_LJ (long)9
#define FCDD_SIZE_LJ (long)10
#define HVC_SIZE_LJ (long)11

#define READ_ERROR_LJ (long)12
#define READ_TIMEOUT_ERROR_LJ (long)13
#define WRITE_ERROR_LJ (long)14
#define FEATURE_ERROR_LJ (long)15

#define ILLEGAL_CHANNEL_LJ (long)16
#define ILLEGAL_GAIN_INDEX_LJ (long)17
#define ILLEGAL_AI_COMMAND_LJ (long)18
#define ILLEGAL_AO_COMMAND_LJ (long)19
#define BITS_OUT_OF_RANGE_LJ (long)20
#define ILLEGAL_NUMBER_OF_CHANNELS_LJ (long)21
#define ILLEGAL_SCAN_RATE_LJ (long)22
#define ILLEGAL_NUM_SAMPLES_LJ (long)23

#define AI_RESPONSE_ERROR_LJ (long)24
#define RAM_CS_ERROR_LJ (long)25
#define AI_SEQUENCE_ERROR_LJ (long)26
#define NUM_STREAMS_ERROR_LJ (long)27
#define AI_STREAM_START_LJ (long)28
#define PC_BUFF_OVERFLOW_LJ (long)29
#define LJ_BUFF_OVERFLOW_LJ (long)30
#define STREAM_READ_TIMEOUT_LJ (long)31
#define ILLEGAL_NUM_SCANS_LJ (long)32
#define NO_STREAM_FOUND_LJ (long)33

#define ILLEGAL_INPUT_ERROR_LJ (long)40
#define ECHO_ERROR_LJ (long)41
#define DATA_ECHO_ERROR_LJ (long)42
#define RESPONSE_ERROR_LJ (long)43

#define ASYNCH_TIMEOUT_ERROR_LJ (long)44
#define ASYNCH_START_ERROR_LJ (long)45
#define ASYNCH_FRAME_ERROR_LJ (long)46
#define ASYNCH_DIO_CONFIG_ERROR_LJ (long)47

#define INPUT_CAPS_ERROR_LJ (long)48
#define OUTPUT_CAPS_ERROR_LJ (long)49
#define FEATURE_CAPS_ERROR_LJ (long)50
#define NUM_CAPS_ERROR_LJ (long)51
#define GET_ATTRIBUTES_WARNING_LJ (long)52

#define WRONG_FIRMWARE_VERSION_LJ (long)57
#define	DIO_CONFIG_ERROR_LJ (long)58

#define CLAIM_ALL_DEVICES_LJ (long)64
#define RELEASE_ALL_DEVICES_LJ (long)65
#define CLAIM_DEVICE_LJ (long)66
#define RELEASE_DEVICE_LJ (long)67
#define CLAIMED_ABANDONED_LJ (long)68
#define LOCALID_NEG_LJ (long)69
#define STOP_THREAD_TIMEOUT_LJ (long)70
#define TERMINATE_THREAD_LJ (long)71
#define FEATURE_HANDLE_LJ (long)72
#define CREATE_MUTEX_LJ (long)73

#define SYNCH_CSSTATETRIS_ERROR_LJ (long)80
#define SYNCH_SCKTRIS_ERROR_LJ (long)81
#define SYNCH_MISOTRIS_ERROR_LJ (long)82
#define SYNCH_MOSITRIS_ERROR_LJ (long)83
#define SHT1X_CRC_ERROR_LJ (long)89
#define SHT1X_MEASREADY_ERROR_LJ (long)90
#define SHT1X_ACK_ERROR_LJ (long)91
#define SHT1X_SERIAL_RESET_ERROR_LJ (long)92

#define STREAMBUFF_ERROR_OFFSET_LJ (long)256  //bit 8 is set for errors in the stream thread
#define GETFIRMWAREVERSION_ERROR_OFFSET_LJ (long)512  //bit 9 is set
#define WINDOWS_ERROR_OFFSET_LJ (long)1024  //bit 10 is set for Windows API errors


typedef struct _LABJACK_INFO
{
	HANDLE				hMutex;		//mutex
	HANDLE				hDevice;
	HANDLE				hReadThread;	//HANDLE
	HANDLE				hFeature;
	DWORD				threadID;       //threads not used
    long 				serialnum;      //used to store a LabJacks serial number
    long 				caliData[20];	//used to store calibration data
	unsigned char 			*buffer;
} LABJACK_INFO;

typedef struct _LABJACK_TRACK
{
    long locid;
    long found;		//used to indicate if a LabJack device was found previously
} LABJACK_TRACK;

typedef struct _STREAM_INFO
{
	long errorcode;
	float streamBuff[RAM_BUFF_ROWS][7];  //V1,(V2),(V3),(V4),stateIO,overvoltage,ljbacklog
	long numScansBuff;	//number of processed scans in the buffer
	long previousCount;
	long localID;  //-1 means not owned
	long demo;
	unsigned long demoTick;
	long scanCount;
	long turbo;
	long disableCal;
	long numChannels;
	long scanMult;
	float scanRate;
	long readCount;	//>0 means return the counter reading
	long ch1num;
	long ch2num;
	long ch3num;
	long ch4num;
	long ch1gain;
	long ch2gain;
	long ch3gain;
	long ch4gain;
} STREAM_INFO;

//TODO
//Define an area of common memory which will be shared by all
//processes which load this DLL.

/*
 * (efs) This would require a shared memory segment under Linux.  At this
 * time, we ignore this requirement and simply initialize them as statics.
 * Until this is fixed, it is best not to access the Labjack from multiple
 * processes.
 */
long numProcessAttaches=0;
long noThreadArray[MAX_DEVICES_LJ]={0};  //array of noThread booleans for each labjack
STREAM_INFO streamInfo={0};
long gTrisD[MAX_DEVICES_LJ]={0};  //referenced to PIC, 0=Output
long gTrisIO[MAX_DEVICES_LJ]={0};  //referenced to PIC, 0=Output
long gStateD[MAX_DEVICES_LJ]={0};  //output states
long gStateIO[MAX_DEVICES_LJ]={0};  //output states
float gAO0[MAX_DEVICES_LJ]={0};  //current AO0 setting
float gAO1[MAX_DEVICES_LJ]={0};  //current AO1 setting


//Globals
LABJACK_INFO labjackInfo[MAX_DEVICES_LJ]={0}; //1 structure for each labjack
LABJACK_TRACK labjackTrack[MAX_LABJACKS]={0};
char ljmutexName[12]={'l','j','a','c','k','u','w','i','0','0','0','\000'};  //put index in bits 8,9,10
char streammutexName[12]={'l','j','a','c','k','u','w','s','0','0','0','\000'};

//array of device names
char labjack[16][19] = { 
	{'/','d','e','v','/','u','s','b','/','l','a','b','j','a','c','k','0', '\000'}, 
	{'/','d','e','v','/','u','s','b','/','l','a','b','j','a','c','k','1', '\000'}, 
	{'/','d','e','v','/','u','s','b','/','l','a','b','j','a','c','k','2', '\000'}, 
	{'/','d','e','v','/','u','s','b','/','l','a','b','j','a','c','k','3', '\000'}, 
	{'/','d','e','v','/','u','s','b','/','l','a','b','j','a','c','k','4', '\000'}, 
	{'/','d','e','v','/','u','s','b','/','l','a','b','j','a','c','k','5', '\000'}, 
	{'/','d','e','v','/','u','s','b','/','l','a','b','j','a','c','k','6', '\000'}, 
	{'/','d','e','v','/','u','s','b','/','l','a','b','j','a','c','k','7', '\000'}, 
	{'/','d','e','v','/','u','s','b','/','l','a','b','j','a','c','k','8', '\000'}, 
	{'/','d','e','v','/','u','s','b','/','l','a','b','j','a','c','k','9', '\000'}, 
	{'/','d','e','v','/','u','s','b','/','l','a','b','j','a','c','k','1','0', '\000'}, 
	{'/','d','e','v','/','u','s','b','/','l','a','b','j','a','c','k','1','1', '\000'}, 
	{'/','d','e','v','/','u','s','b','/','l','a','b','j','a','c','k','1','2', '\000'}, 
	{'/','d','e','v','/','u','s','b','/','l','a','b','j','a','c','k','1','3', '\000'}, 
	{'/','d','e','v','/','u','s','b','/','l','a','b','j','a','c','k','1','4', '\000'}, 
	{'/','d','e','v','/','u','s','b','/','l','a','b','j','a','c','k','1','5', '\000'} };


typedef struct _SP_DEVICE_INTERFACE_DETAIL_DATA_LJ {
    DWORD  cbSize;
    char   DevicePath[FCDD_MAX];
} SP_DEVICE_INTERFACE_DETAIL_DATA_LJ, *PSP_DEVICE_INTERFACE_DETAIL_DATA_LJ;

 
//local functions
long OpenLabJack (long			*errorcode,
				  unsigned int	vendorID,
				  unsigned int	productID,
				  long			*idnum,
				  long			*serialnum,
				  long			*calData);

long WriteRead (long localID,
				long timeoutms,
			   unsigned char	*sendBuffer,
			   unsigned char	*readBuffer);

long WriteLabJack (long localID,
				   unsigned char *sendBuffer);

long ReadLabJack (long localID,
				  long timeout,
				  long feature,
				  unsigned char *buffer);

DWORD ReadInputThread (long *localID);

DWORD ReadFeatureThread (long *localID);

long CloseAll (long localID);

long BuildAICommand (long command,	//4-bit command, 1CCC, 12=C/R,10=burst,9=stream
					unsigned char sendBuff5,	//buffer+4
					unsigned char sendBuff7,	//buffer+6
					unsigned char sendBuff8,	//buffer+7
					long stateIO,
					long ch1num,
					long ch2num,
					long ch3num,
					long ch4num,
					long ch1gain,
					long ch2gain,
					long ch3gain,
					long ch4gain,
					unsigned char *sendBuffer);

long BuildGainMuxCommand (long chnum,
						 long chgain,
						 unsigned char *gainmux);

long ParseAIResponse (unsigned char *sendBuffer,
					 unsigned char *readBuffer,
					 long disableCal,
					 long *calData,	//20 element array
					 long *stateIO,
				 	 long *overVoltage,
					 float *voltage1,
					 float *voltage2,
					 float *voltage3,
					 float *voltage4,
					 unsigned char *echoIn,
					 long *ofchecksumError,
					 long *backlog,
					 long *iterationCount,
					 long readCount);

long ApplyCal (unsigned char gainmux,
			   long *calData,
			   long *bits);

long BuildAOCommand (long trisD,
					 long trisIO,
					 long stateD,
					 long stateIO,
					 long updateDigital,
					 long resetCounter,
					 float analogOut0,
					 float analogOut1,
					 unsigned char *sendBuffer);

long ParseAOResponse (unsigned char *readBuffer,
					  long *stateD,
					  long *stateIO,
				 	  unsigned long *count);

long RoundFL (float fp);

long SHTWriteRead(	long localID,
					long softComm,		// >0 means bit-bang in software
					long waitMeas,		// >0 means wait for measurement ready
					long serialReset,	// >0 means start with a serialReset
					long dataRate,		// 0=default,1=300us delay,2=1ms delay
					long numWrite,		// 0-4
					long numRead,		// 0-4
					unsigned char *datatx,  //4 byte write array
					unsigned char *datarx);	//4 byte read array

unsigned char ReverseByte(unsigned char byteIn);

long ReadMemNoOpen(long *fd,		//file descriptor
			 long address,
			 long *data3,
			 long *data2,
			 long *data1,
			 long *data0);
			 
long twoscomplement(long val);

//Possibly TODO
//Windows has a function where some things can be initialized
//when the DLL is loaded.

/* (efs) for now force the user to call the initialization routine manually.
 * Again, not ideal, but it lets us make progress.
 */
 
void InitLabjack() {
	int i;
	
	for(i=0;i<MAX_DEVICES_LJ;i++)
	{
		noThreadArray[i] = 0;
		gTrisD[i]=65535;  //referenced to PIC, 0=Output
		gTrisIO[i]=15;  //referenced to PIC, 0=Output
		gStateD[i]=0;  //output states
		gStateIO[i]=0;  //output states
		gAO0[i]=0.0F;
		gAO1[i]=0.0F;
        	if(i<MAX_LABJACKS) {
            		labjackTrack[i].found = FALSE;
	        }
	}
	streamInfo.localID = -1;
	streamInfo.errorcode = 0;
}


//======================================================================
// EAnalogIn: Easy function reads the voltage from 1 analog input.  Calling
//			  this function turns/leaves the status LED on.
//
//	Returns:	LabJack errorcodes or 0 for no error (I32).
//	Inputs:		*idnum		-Local ID, Serial Number, or -1 for first
//							 found (I32).
//				demo		-Send 0 for normal operation, >0 for demo
//							 mode (I32).  Demo mode allows this function
//							 to be called without a LabJack, and does
//							 little but simulate execution time.
//				channel		-Channel command is 0-7 for SE or 8-11 for Diff.
//				gain		-Gain command is 0=1,1=2,...,7=20.  Gain only
//							 available for differential channels.
//	Outputs:	*idnum		-Returns the Local ID or -1 if no LabJack is
//							 found (I32).
//				*overVoltage	-If >0, an overvoltage has been detected
//								 on the analog input (I32).
//				voltage		-Returns the voltage reading (SGL).
//
//	Time:		20 ms
//----------------------------------------------------------------------
long EAnalogIn(long *idnum,
			   long demo,
			   long channel,
			   long gain,
			   long *overVoltage,
			   float *voltage)
{
	long errorcode;
	long localID=0;
	float avgVolts;
	long avgBits;
	unsigned char echoOut,echoIn;
	unsigned char sendBuff5=0;
	long junk=0;
	unsigned char sendBuffer[9]={0,0,0,0,0,0,0,0,0};
	unsigned char readBuffer[9]={0,0,0,0,0,0,0,0,0};
	long calData[20]={0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0};
	long ch1num,ch2num,ch3num,ch4num,ch1gain,ch2gain,ch3gain,ch4gain;
	long stateIO=0,disableCal=0;
	float voltages[4]={0,0,0,0};
	long serialnum=0;
	
	if(!demo)
	{
		//Open the specified or first found LabJack
        	localID = OpenLabJack(&errorcode,LABJACK_VENDOR_ID,LABJACK_U12_PRODUCT_ID,idnum,&serialnum,calData);
	        if(errorcode)
		{
			*idnum=-1;
			*overVoltage=0;
			return errorcode;
		}
	}

	//The LabJack echos 1 byte so we can make sure we are getting the expected response
	echoOut = (unsigned char)GetTickCount();

	//set bit 0 to turn the LED on
	sendBuff5 = BitSet(sendBuff5,0);

	//Fill sendBuffer with the proper values.
	ch1num=channel;
	ch2num=channel;
	ch3num=channel;
	ch4num=channel;
	ch1gain=gain;
	ch2gain=gain;
	ch3gain=gain;
	ch4gain=gain;
	errorcode = BuildAICommand(12,sendBuff5,0,echoOut,stateIO,ch1num,ch2num,ch3num,ch4num,ch1gain,ch2gain,ch3gain,ch4gain,sendBuffer);
	if(errorcode)
	{
		*overVoltage=0;
		CloseAll(localID);
		return errorcode;
	}

	if(!demo)
	{
		//Write & Read data to/from the LabJack
		errorcode = WriteRead(localID,1000,sendBuffer,readBuffer);
		if(errorcode)
		{
			*overVoltage=0;
			CloseAll(localID);
			return errorcode;
		}

		//Parse the response
		errorcode = ParseAIResponse(sendBuffer,readBuffer,disableCal,calData,&stateIO,overVoltage,&voltages[0],&voltages[1],&voltages[2],&voltages[3],&echoIn,&junk,&junk,&junk,0);
		if(errorcode)
		{
			*overVoltage=0;
			voltage=0;
			CloseAll(localID);
			return errorcode;
		}

		if(echoOut != echoIn)
		{
			errorcode=ECHO_ERROR_LJ;
			*overVoltage=0;
			voltage=0;
			CloseAll(localID);
			return errorcode;
		}
	}
	else
	{
		//Demo Mode

		Sleep(14+((long)(6.0F * (float)rand()/(float)RAND_MAX)));

		voltages[0]=2.5F;
		voltages[1]=2.5F;
		voltages[2]=2.5F;
		voltages[3]=2.5F;
	}
	
	//Only 1 channel so average 4 readings to get voltage.
	avgVolts = (voltages[0]+voltages[1]+voltages[2]+voltages[3])/4.0F;
	errorcode = VoltsToBits(ch1num,ch1gain,avgVolts,&avgBits);
	errorcode = BitsToVolts(ch1num,ch1gain,avgBits,voltage);

	if(!demo)
	{
		errorcode = CloseAll(localID);
	}

	return errorcode;
}


//======================================================================
// EAnalogOut: Easy function sets the voltages of both analog outputs.
//
//	Returns:	LabJack errorcodes or 0 for no error (I32).
//	Inputs:		*idnum		-Local ID, Serial Number, or -1 for first
//							 found (I32).
//				demo		-Send 0 for normal operation, >0 for demo
//							 mode (I32).  Demo mode allows this function
//							 to be called without a LabJack, and does little
//							 but simulate execution time.
//				analogOut0	-Voltage from 0 to 5 for AO0 (SGL).
//				analogOut1	-Voltage from 0 to 5 for AO1 (SGL).
//	Outputs:	*idnum		-Returns the Local ID or -1 if no LabJack is
//							 found (I32).
//
//	Time:		20 ms
//----------------------------------------------------------------------
long EAnalogOut(long *idnum,
			    long demo,
			    float analogOut0,
			    float analogOut1)
{
	long errorcode;
	long localID;
	unsigned char sendBuffer[9]={0,0,0,0,0,0,0,0,0};
	unsigned char readBuffer[9]={0,0,0,0,0,0,0,0,0};
	long calData[20]={0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0};
	long stateD=0,stateIO=0;
	unsigned long count=0;
	long serialnum=0;


	//Do demo here
	if(demo)
	{
		Sleep(14+((long)(6.0F * (float)rand()/(float)RAND_MAX)));
		return NO_ERROR_LJ;
	}

	//Open the specified or first found LabJack
	localID = OpenLabJack(&errorcode,LABJACK_VENDOR_ID,LABJACK_U12_PRODUCT_ID,idnum,&serialnum,calData);
	if(errorcode)
	{
		*idnum=-1;
		return errorcode;
	}

	if(analogOut0<0)
	{
		analogOut0=gAO0[localID];
	}

	if(analogOut1<0)
	{
		analogOut1=gAO1[localID];
	}

	//Fill sendBuffer with the proper values.
	errorcode = BuildAOCommand(0,0,0,0,0,0,analogOut0,analogOut1,sendBuffer);
	if(errorcode)
	{
		CloseAll(localID);
		return errorcode;
	}

	//Write & Read data to/from the LabJack
	errorcode = WriteRead(localID,1000,sendBuffer,readBuffer);
	if(errorcode)
	{
		CloseAll(localID);
		return errorcode;
	}

	//update globals
	gAO0[localID]=analogOut0;
	gAO1[localID]=analogOut1;

	//Parse the response
	errorcode = ParseAOResponse(readBuffer,&stateD,&stateIO,&count);
	if(errorcode)
	{
		CloseAll(localID);
		return errorcode;
	}
	
	errorcode = CloseAll(localID);

	return errorcode;
}



//======================================================================
// ECount:	Easy function to read & reset the counter.  Calling this
//			function disables STB (which is the default anyway).
//
//	Returns:	LabJack errorcodes or 0 for no error (I32).
//	Inputs:		*idnum		-Local ID, Serial Number, or -1 for first
//							 found (I32).
//				demo		-Send 0 for normal operation, >0 for demo
//							 mode (I32).  Demo mode allows this function to
//							 be called without a LabJack, and does little but
//							 simulate execution time.
//				resetCounter	-If >0, the counter is reset to zero after
//								 being read (I32).
//	Outputs:	*idnum		-Returns the Local ID or -1 if no LabJack is
//							 found (I32).
//				*count		-Current count, before reset.
//				*ms			-Value of Windows millisecond timer at the
//							 time of the counter read (within a few ms).
//							 Note that the millisecond timer rolls over
//							 about every 50 days.  In general, the
//							 millisecond timer starts counting from zero
//							 whenever the computer reboots.
//
//	Time:		20 ms
//----------------------------------------------------------------------
long ECount	(long *idnum,
			 long demo,
			 long resetCounter,
			 double *count,
			 double *ms)
{
	long errorcode;
	long localID;
	long stateD=0,stateIO=0;
	unsigned long ucount=0;
	unsigned long initial,final;
	unsigned char sendBuffer[9]={0,0,0,0,0,0,0,0,0};
	unsigned char readBuffer[9]={0,0,0,0,0,0,0,0,0};
	long calData[20]={0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0};
	long serialnum=0;


	//Do demo here
	if(demo)
	{
		Sleep(14+((long)(6.0F * (float)rand()/(float)RAND_MAX)));
		*count=GetTickCount();
		return NO_ERROR_LJ;
	}

	//Open the specified or first found LabJack
	localID = OpenLabJack(&errorcode,LABJACK_VENDOR_ID,LABJACK_U12_PRODUCT_ID,idnum,&serialnum,calData);
	if(errorcode)
	{
		*idnum=-1;
		*count=0;
		*ms=0;
		return errorcode;
	}

	//Fill sendBuffer with the proper values.
	sendBuffer[6]=82;
	sendBuffer[1]=0;
	if(resetCounter)
	{
		sendBuffer[1] = BitSet(sendBuffer[1],0);  //set bit
	}

	//Get millisecond count before sending command
	initial=GetTickCount();

	//Write & Read data to/from the LabJack
	errorcode = WriteRead(localID,1000,sendBuffer,readBuffer);
	if(errorcode)
	{
		*ms=0;
		*count=0;
		CloseAll(localID);
		return errorcode;
	}

	//Get millisecond count after receiving response
	final=GetTickCount();

	//Estimate time when counter was actual read.
	if(final>initial)
	{
		*ms=initial+((final-initial)/2);
	}
	else
	{
		*ms=(double)(initial+((((4294967295U-initial)+1)+final)/2));
	}

	//Parse the response
	errorcode = ParseAOResponse(readBuffer,&stateD,&stateIO,&ucount);
	if(errorcode)
	{
		*ms=0;
		*count=0;
		CloseAll(localID);
		return errorcode;
	}
	
	errorcode = CloseAll(localID);

	*count = (double)ucount;

	return errorcode;
}


//======================================================================
// EDigitalIn:	Easy function reads 1 digital input.  Also configures
//				the requested pin to input and leaves it that way.
//
//				Note that this is a simplified version of the lower
//				level function DigitalIO, which operates on all 20
//				digital lines.  The DLL keeps track of the current
//				direction and output state of all lines, so that this
//				easy function can operate on a single line without
//				changing the others.  When the DLL is first loaded,
//				though, it does not know the direction and state of
//				the lines and assumes all directions are input and
//				output states are low.
//
//	Returns:	LabJack errorcodes or 0 for no error (I32).
//	Inputs:		*idnum		-Local ID, Serial Number, or -1 for first
//							 found (I32).
//				demo		-Send 0 for normal operation, >0 for demo
//							 mode (I32).  Demo mode allows this function to
//							 be called without a LabJack, and does little but
//							 simulate execution time.
//				channel		-Line to read.  0-3 for IO or 0-15 for D.
//				readD		-If >0, a D line is read instead of an IO line.
//	Outputs:	*idnum		-Returns the Local ID or -1 if no LabJack is
//							 found (I32).
//				*state		-TRUE/Set if >0.  FALSE/Clear if 0.
//
//	Time:		20 ms
//----------------------------------------------------------------------
long EDigitalIn(long *idnum,
			    long demo,
			    long channel,
			    long readD,
			    long *state)
{
	long errorcode;
	long localID;
	unsigned char sendBuffer[9]={0,0,0,0,0,0,0,0,0};
	unsigned char readBuffer[9]={0,0,0,0,0,0,0,0,0};
	long calData[20]={0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0};
	long trisD=0,trisIO=0,stateD=0,stateIO=0;
	long serialnum=0;


	//Make sure each DIO input is within the proper range
	if (readD)
	{
		if ((channel<0) || (channel>15))
		{
			errorcode=ILLEGAL_INPUT_ERROR_LJ;
			*idnum=-1;
			*state=-1;
			return errorcode;
		}
	}
	else
	{
		if ((channel<0) || (channel>3))
		{
			errorcode=ILLEGAL_INPUT_ERROR_LJ;
			*idnum=-1;
			*state=-1;
			return errorcode;
		}
	}

	//Do demo here
	if(demo)
	{
		Sleep(14+((long)(6.0F * (float)rand()/(float)RAND_MAX)));
		return NO_ERROR_LJ;
	}

	//Open the specified or first found LabJack
	localID = OpenLabJack(&errorcode,LABJACK_VENDOR_ID,LABJACK_U12_PRODUCT_ID,idnum,&serialnum,calData);
	if(errorcode)
	{
		*idnum=-1;
		*state=-1;
		return errorcode;
	}

	//Set the desired line to input
	if(readD)
	{
		trisD=BitSet(gTrisD[localID],channel);
		trisIO=gTrisIO[localID];
	}
	else
	{
		trisD=gTrisD[localID];
		trisIO=BitSet(gTrisIO[localID],channel);
	}

	//Fill sendBuffer with the proper values.
	sendBuffer[1]=(unsigned char)(trisD/256);	//upper byte of trisD
	sendBuffer[2]=(unsigned char)(trisD%256);	//lower byte of trisD
	sendBuffer[3]=(unsigned char)(gStateD[localID]/256);	//upper byte of stateD
	sendBuffer[4]=(unsigned char)(gStateD[localID]%256);	//lower byte of stateD
	sendBuffer[5]=((unsigned char)(trisIO*16)) + ((unsigned char)gStateIO[localID]);
	sendBuffer[6]=87;
	sendBuffer[7]=0;

	//Set updateDigital TRUE
	sendBuffer[7] = BitSet(sendBuffer[7],0);  //set bit 0
	
	//Write & Read data to/from the LabJack
	errorcode = WriteRead(localID,1000,sendBuffer,readBuffer);
	if(errorcode)
	{
		*state=-1;
		CloseAll(localID);
		return errorcode;
	}

	//Update tris and state globals with current output values
	gTrisD[localID]=trisD;
	gTrisIO[localID]=trisIO;

	//Parse the response
	if (!((readBuffer[1]==87)||(readBuffer[1]==119)))
	{
		errorcode=RESPONSE_ERROR_LJ;
	}

	stateD = ((long)readBuffer[2]) * 256;
	stateD += ((long)readBuffer[3]);
	stateIO = ((long)readBuffer[4]) / 16;

	if(readD)
	{
		*state=BitTst(stateD,channel);
	}
	else
	{
		*state=BitTst(stateIO,channel);
	}

	errorcode = CloseAll(localID);

	return errorcode;
}


//======================================================================
// EDigitalOut:	Easy function writes 1 digital output.  Also configures the
//				the requested pin to output and leaves it that way.
//
//				Note that this is a simplified version of the lower
//				level function DigitalIO, which operates on all 20
//				digital lines.  The DLL keeps track of the current
//				direction and output state of all lines, so that this
//				easy function can operate on a single line without
//				changing the others.  When the DLL is first loaded,
//				though, it does not know the direction and state of
//				the lines and assumes all directions are input and
//				output states are low.
//
//	Returns:	LabJack errorcodes or 0 for no error (I32).
//	Inputs:		*idnum		-Local ID, Serial Number, or -1 for first
//							 found (I32).
//				demo		-Send 0 for normal operation, >0 for demo
//							 mode (I32).  Demo mode allows this function to
//							 be called without a LabJack, and does little but
//							 simulate execution time.
//				channel		-Line to write.  0-3 for IO or 0-15 for D.
//				writeD		-If >0, a D line is written instead of an IO line.
//				state		-TRUE/Set if >0.  FALSE/Clear if 0.
//	Outputs:	*idnum		-Returns the Local ID or -1 if no LabJack is
//							 found (I32).
//
//	Time:		20 ms
//----------------------------------------------------------------------
long EDigitalOut(long *idnum,
			     long demo,
			     long channel,
			     long writeD,
			     long state)
{
	long errorcode;
	long localID;
	unsigned char sendBuffer[9]={0,0,0,0,0,0,0,0,0};
	unsigned char readBuffer[9]={0,0,0,0,0,0,0,0,0};
	long calData[20]={0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0};
	long trisD=0,trisIO=0,stateD=0,stateIO=0;
	long serialnum=0;


	//Make sure each DIO input is within the proper range
	if (writeD)
	{
		if ((channel<0) || (channel>15))
		{
			errorcode=ILLEGAL_INPUT_ERROR_LJ;
			*idnum=-1;
			return errorcode;
		}
	}
	else
	{
		if ((channel<0) || (channel>3))
		{
			errorcode=ILLEGAL_INPUT_ERROR_LJ;
			*idnum=-1;
			return errorcode;
		}
	}

	//Do demo here
	if(demo)
	{
		Sleep(14+((long)(6.0F * (float)rand()/(float)RAND_MAX)));
		return NO_ERROR_LJ;
	}

	//Open the specified or first found LabJack
	localID = OpenLabJack(&errorcode,LABJACK_VENDOR_ID,LABJACK_U12_PRODUCT_ID,idnum,&serialnum,calData);
	if(errorcode)
	{
		*idnum=-1;
		return errorcode;
	}

	
	//Set the desired line to output and set state
	if(writeD)
	{
		trisD=BitClr(gTrisD[localID],channel);
		if(state)
		{
			stateD=BitSet(gStateD[localID],channel);
		}
		else
		{
			stateD=BitClr(gStateD[localID],channel);
		}
		trisIO=gTrisIO[localID];
		stateIO=gStateIO[localID];
	}
	else
	{
		trisD=gTrisD[localID];
		stateD=gStateD[localID];
		trisIO=BitClr(gTrisIO[localID],channel);
		if(state)
		{
			stateIO=BitSet(gStateIO[localID],channel);
		}
		else
		{
			stateIO=BitClr(gStateIO[localID],channel);
		}
	}

	//Fill sendBuffer with the proper values.
	sendBuffer[1]=(unsigned char)(trisD/256);	//upper byte of trisD
	sendBuffer[2]=(unsigned char)(trisD%256);	//lower byte of trisD
	sendBuffer[3]=(unsigned char)(stateD/256);	//upper byte of stateD
	sendBuffer[4]=(unsigned char)(stateD%256);	//lower byte of stateD
	sendBuffer[5]=((unsigned char)(trisIO*16)) + ((unsigned char)stateIO);
	sendBuffer[6]=87;
	sendBuffer[7]=0;
	
	//Set updateDigital TRUE.
	sendBuffer[7] = BitSet(sendBuffer[7],0);  //set bit 0
	
	//Write & Read data to/from the LabJack
	errorcode = WriteRead(localID,1000,sendBuffer,readBuffer);
	if(errorcode)
	{
		CloseAll(localID);
		return errorcode;
	}

	//Update tris and state globals with current output values
	gTrisD[localID]=trisD;
	gTrisIO[localID]=trisIO;
	gStateD[localID]=stateD;
	gStateIO[localID]=stateIO;

	//Parse the response
	if (!((readBuffer[1]==87)||(readBuffer[1]==119)))
	{
		errorcode=RESPONSE_ERROR_LJ;
	}
	
	errorcode = CloseAll(localID);

	return errorcode;
}


//======================================================================
// AsynchConfig:	Requires firmware V1.08 or higher.
//
//				This function writes to the asynch registers and sets the
//				direction of the D lines (input/output) as needed.
//
//				The actual 1-bit time is about 1.833 plus a "full" delay (us).
//				The actual 1/2-bit time is about 1.0 plus a "half" delay (us).
//
//				full/half delay = 0.833 + 0.833C + 0.667BC + 0.5ABC
//
//				Common baud rates (full A,B,C; half A,B,C):
//				1		55,153,232  ;  114,255,34
//				10		63,111,28  ;  34,123,23
//				100		51,191,2  ;  33,97,3
//				300		71,23,4  ;  84,39,1
//				600		183,3,6  ;  236,7,1
//				1000	33,29,2  ;  123,8,1
//				1200	23,17,4  ;  14,54,1
//				2400	21,37,1  ;  44,3,3
//				4800	10,18,2  ;  1,87,1
//				7200	134,2,1  ;  6,9,2
//				9600	200,1,1  ;  48,2,1
//				10000	63,3,1  ;  46,2,1
//				19200	96,1,1  ;  22,2,1
//				38400	3,5,2  ;  9,2,1
//				57600	3,3,2  ;  11,1,1
//				100000	3,3,1  ;  1,2,1
//				115200	9,1,1  ;  2,1,1 or 1,1,1
//
//				
//				When using data rates over 38.4 kbps, the following conditions
//				need to be considered:
//				-When reading the first byte, the start bit is first tested
//				 about 11.5 us after the start of the tx stop bit.
//				-When reading bytes after the first, the start bit is first
//				 tested about "full" + 11 us after the previous bit 8 read,
//				 which probably occurs near the middle of bit 8.
//
//				When enabled, STB does the following to aid in debugging
//				asynchronous reads:
//				-STB is set about 6 us after the start of the last tx stop bit, or
//				 about "full" + 6 us after the previous bit 8 read.
//				-STB is cleared about 0-2 us after the rx start bit is detected.
//				-STB is set after about "half".
//				-STB is cleared after about "full".
//				-Bit 0 is read about 1 us later.
//				-STB is set about 1 us after the bit 0 read.
//				-STB is cleared after about "full".
//				-Bit 1 is read about 1 us later.
//				-STB is set about 1 us after the bit 1 read.
//				-STB is cleared after about "full".
//				-This continues for all 8 data bits and the stop bit, after
//				 which STB remains low.
//
//
//	Returns:	LabJack errorcodes or 0 for no error (I32).
//	Inputs:		*idnum		-Local ID, Serial Number, or -1 for first
//							 found (I32).
//				demo		-Send 0 for normal operation, >0 for demo
//							 mode (I32).  Demo mode allows this function to
//							 be called without a LabJack, and does little but
//							 simulate execution time.
//				timeoutMult	-If enabled, read timeout is about 100
//							 milliseconds times this value (I32, 0-255).
//				configA		-If >0, D8 is set to output-high and D9 is set to
//							 input (I32).
//				configB		-If >0, D10 is set to output-high and D11 is set to
//							 input (I32).
//				configTE	-If >0, D12 is set to output-low (I32).
//				fullA		-A time value for a full bit (I32, 1-255).
//				fullB		-B time value for a full bit (I32, 1-255).
//				fullC		-C time value for a full bit (I32, 1-255).
//				halfA		-A time value for a half bit (I32, 1-255).
//				halfB		-B time value for a half bit (I32, 1-255).
//				halfC		-C time value for a half bit (I32, 1-255).
//	Outputs:	*idnum		-Returns the Local ID or -1 if no LabJack is
//							 found (I32).
//
//	Time:		60 ms
//----------------------------------------------------------------------
long AsynchConfig(	long *idnum,
					long demo,
					long timeoutMult,
					long configA,
					long configB,
					long configTE,
					long fullA,
					long fullB,
					long fullC,
					long halfA,
					long halfB,
					long halfC)
{
	long errorcode;
	long localID;
	unsigned char sendBuffer[9]={0,0,0,0,0,0,0,0,0};
	unsigned char readBuffer[9]={0,0,0,0,0,0,0,0,0};
	long calData[20]={0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0};
	long pulseMS = 0;
	long timeoutMS = 0;
	long serialnum=0;
	long trisD=0,trisIO=0,stateD=0,stateIO=0;


	//Make sure each input is within the proper range
	if ((timeoutMult<0) || (timeoutMult>255))
	{
		errorcode=ILLEGAL_INPUT_ERROR_LJ;
		*idnum=-1;
		return errorcode;
	}
	if ((fullA<1) || (fullA>255))
	{
		errorcode=ILLEGAL_INPUT_ERROR_LJ;
		*idnum=-1;
		return errorcode;
	}
	if ((fullB<1) || (fullB>255))
	{
		errorcode=ILLEGAL_INPUT_ERROR_LJ;
		*idnum=-1;
		return errorcode;
	}
	if ((fullC<1) || (fullC>255))
	{
		errorcode=ILLEGAL_INPUT_ERROR_LJ;
		*idnum=-1;
		return errorcode;
	}
	if ((halfA<1) || (halfA>255))
	{
		errorcode=ILLEGAL_INPUT_ERROR_LJ;
		*idnum=-1;
		return errorcode;
	}
	if ((halfB<1) || (halfB>255))
	{
		errorcode=ILLEGAL_INPUT_ERROR_LJ;
		*idnum=-1;
		return errorcode;
	}
	if ((halfC<1) || (halfC>255))
	{
		errorcode=ILLEGAL_INPUT_ERROR_LJ;
		*idnum=-1;
		return errorcode;
	}

	//Do demo here
	if(demo)
	{
		Sleep(40);
		return NO_ERROR_LJ;
	}

	//Open the specified or first found LabJack
	localID = OpenLabJack(&errorcode,LABJACK_VENDOR_ID,LABJACK_U12_PRODUCT_ID,idnum,&serialnum,calData);
	if(errorcode)
	{
		*idnum=-1;
		return errorcode;
	}

	//Make sure firmware is V1.05 or higher
	if(serialnum < 100010000)
	{
		CloseAll(localID);
		return WRONG_FIRMWARE_VERSION_LJ;
	}

	//Initialize local tris and state variables
	trisD=gTrisD[localID];
	stateD=gStateD[localID];
	trisIO=gTrisIO[localID];
	stateIO=gStateIO[localID];

	//If configA is true, set D8 to output-high, and set D9 to input.
	if(configA)
	{
		trisD=BitClr(trisD,8); //In firmware, 0=Output and 1=Input
		stateD=BitSet(stateD,8);
		trisD=BitSet(trisD,9); //In firmware, 0=Output and 1=Input
	}

	//If configB is true, set D10 to output-high, and set D11 to input.
	if(configB)
	{
		trisD=BitClr(trisD,10); //In firmware, 0=Output and 1=Input
		stateD=BitSet(stateD,10);
		trisD=BitSet(trisD,11); //In firmware, 0=Output and 1=Input
	}

	//If configTE is true, set D12 to output-low.
	if(configA)
	{
		trisD=BitClr(trisD,12); //In firmware, 0=Output and 1=Input
		stateD=BitClr(stateD,12);
	}

	//Fill sendBuffer with the proper values.
	sendBuffer[1]=(unsigned char)(trisD/256);	//upper byte of trisD
	sendBuffer[2]=(unsigned char)(trisD%256);	//lower byte of trisD
	sendBuffer[3]=(unsigned char)(stateD/256);	//upper byte of stateD
	sendBuffer[4]=(unsigned char)(stateD%256);	//lower byte of stateD
	sendBuffer[5]=((unsigned char)(trisIO*16)) + ((unsigned char)stateIO);
	sendBuffer[6]=87; //DigitalIO function
	sendBuffer[7]=0;
	
	//Set updateDigital TRUE.
	sendBuffer[7] = BitSet(sendBuffer[7],0);  //set bit 0
	
	//Write & Read data to/from the LabJack
	errorcode = WriteRead(localID,1000,sendBuffer,readBuffer);
	if(errorcode)
	{
		CloseAll(localID);
		return errorcode;
	}

	//Update tris and state globals with current output values
	gTrisD[localID]=trisD;
	gTrisIO[localID]=trisIO;
	gStateD[localID]=stateD;
	gStateIO[localID]=stateIO;

	//Parse the response
	if (!((readBuffer[1]==87)||(readBuffer[1]==119)))
	{
		errorcode = CloseAll(localID);
		return RESPONSE_ERROR_LJ;
	}
	
	errorcode = CloseAll(localID);
	if(errorcode) return errorcode;

	//Call WriteMem twice to load configuration parameters.
	//Address 0x070 to 0x07F Asynch (fullA,fullB,fullC,halfA,halfB,halfC,tomult,empty ...).
	errorcode = WriteMem(&localID,1,112,fullA,fullB,fullC,halfA);
	if(errorcode) return errorcode;
	errorcode = WriteMem(&localID,1,116,halfB,halfC,timeoutMult,0);

	return errorcode;
}


//======================================================================
// Asynch:		Requires firmware V1.05 or higher.
//
//				This function writes and then reads half-duplex asynchronous
//				data on 1 of two pairs of D lines (8,n,1).  Call AsynchConfig
//				to set the baud rate.  Similar to RS232, except that logic is
//				normal CMOS/TTL (0=low=GND, 1=high=+5V, idle state of
//				transmit line is high).  Connection to a normal RS232 device
//				will probably require a converter chip such as the MAX233.
//
//				PortA =>  TX is D8 and RX is D9
//				PortB =>  TX is D10 and RX is D11
//				Transmit Enable is D12
//
//				Up to 18 bytes can be written and read.  If more than 4 bytes
//				are written or read, this function uses calls to
//				WriteMem/ReadMem to load/read the LabJack's data buffer.
//
//	Returns:	LabJack errorcodes or 0 for no error (I32).
//	Inputs:		*idnum		-Local ID, Serial Number, or -1 for first
//							 found (I32).
//				demo		-Send 0 for normal operation, >0 for demo
//							 mode (I32).  Demo mode allows this function to
//							 be called without a LabJack, and does little but
//							 simulate execution time.
//				portB		-If >0, asynch PortA is used instead of PortA.
//				enableTE	-If >0, D12 (Transmit Enable) is set high during
//							 transmit and low during receive (I32).
//				enableTO	-If >0, timeout is enabled for the receive phase (per byte).
//				enableDel	-If >0, a 1 bit delay is inserted between each
//							 transmit byte.
//				baudrate	-This is the bps as set by AsynchConfig.  Asynch needs this
//							 so it has an idea how long the transfer should take.
//				numWrite	-Number of bytes to write (I32, 0-18).
//				numRead		-Number of bytes to read (I32, 0-18).
//				*data		-Serial data buffer.  Send an 18 element
//							 array.  Fill unused locations with zeros (I32).
//	Outputs:	*idnum		-Returns the Local ID or -1 if no LabJack is
//							 found (I32).
//				*data		-Serial data buffer.  Returns any serial read
//							 data.  Unused locations are filled
//							 with 9999s. (I32).
//
//	Time:		20 ms to read and/or write up to 4 bytes, plus 20 ms for each
//				additional 4 bytes to read or write.  Possibly extra
//				time for slow baud rates.
//----------------------------------------------------------------------
long Asynch(	long *idnum,
				long demo,
				long portB,
				long enableTE,
				long enableTO,
				long enableDel,
				long baudrate,
				long numWrite,
				long numRead,
				long *data)
{
	long errorcode=0,result=0,i=0,j=0, usbTimeout=0;
	long localID;
	unsigned char sendBuffer[9]={0,0,0,0,0,0,0,0,0};
	unsigned char readBuffer[9]={0,0,0,0,0,0,0,0,0};
	long calData[20]={0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0};
	long serialnum=0,numPackets=0,memAddress=0,numFill=0;

	//Make sure each input is within the proper range
	if ((numWrite<0) || (numWrite>18))
	{
		errorcode=ILLEGAL_INPUT_ERROR_LJ;
		*idnum=-1;
		return errorcode;
	}
	if ((numRead<0) || (numRead>18))
	{
		errorcode=ILLEGAL_INPUT_ERROR_LJ;
		*idnum=-1;
		return errorcode;
	}
	for(i=0;i<18;i++)
	{
		if(i >= numWrite)
		{
			if(data[i] != 0)
			{
				return ARRAY_SIZE_OR_VALUE_ERROR_LJ;
			}
		}
		else
		{
			if((data[i]<0)||(data[i]>255))
			{
				return ARRAY_SIZE_OR_VALUE_ERROR_LJ;
			}
		}
	}

	//If we are writing more than 4 bytes, put them in the LabJack's NVRAM buffer.
	numPackets = 0;
	if(numWrite>4)
	{
		numPackets = (numWrite-1)/4;
		for(i=0;i<numPackets;i++)
		{
			memAddress=132+(i*4);
			if(!demo)
			{
				errorcode = WriteMem(idnum,1,memAddress,data[4+(i*4)],data[5+(i*4)],data[6+(i*4)],data[7+(i*4)]);
			}
			else
			{
				Sleep(20);
			}
			if(errorcode) return errorcode;
		}
	}

	if(!demo)
	{
		//Open the specified or first found LabJack and call the asynch function
		localID = OpenLabJack(&errorcode,LABJACK_VENDOR_ID,LABJACK_U12_PRODUCT_ID,idnum,&serialnum,calData);
		if(errorcode)
		{
			*idnum=-1;
			return errorcode;
		}

		//Make sure firmware is V1.05 or higher
		if(serialnum < 100010000)
		{
			CloseAll(localID);
			return WRONG_FIRMWARE_VERSION_LJ;
		}

		//Fill sendBuffer with the proper values.
		sendBuffer[1]=(unsigned char)(data[3]);
		sendBuffer[2]=(unsigned char)(data[2]);
		sendBuffer[3]=(unsigned char)(data[1]);
		sendBuffer[4]=(unsigned char)(data[0]);
		sendBuffer[5]=0;
		if(enableDel) sendBuffer[5]=BitSet(sendBuffer[5],3);
		if(enableTO) sendBuffer[5]=BitSet(sendBuffer[5],2);
		if(enableTE) sendBuffer[5]=BitSet(sendBuffer[5],1);
		if(portB) sendBuffer[5]=BitSet(sendBuffer[5],0);
		sendBuffer[6]=97; //DigitalIO function
		sendBuffer[7]=(unsigned char)numWrite;
		sendBuffer[8]=(unsigned char)numRead;
		
		//Determine proper timeout for WriteRead
		if(enableTO)
		{
			usbTimeout = 35000;
		}
		else
		{
			usbTimeout = (long)(1250.0*((((double)numWrite*8.0)+((double)numRead*8.0))/(double)baudrate));
			if(usbTimeout<1000) usbTimeout=1000;
		}

		//Write & Read data to/from the LabJack
		errorcode = WriteRead(localID,usbTimeout,sendBuffer,readBuffer);
		if(errorcode)
		{
			CloseAll(localID);
			return errorcode;
		}

		//Fill data array with 9999s
		for(i=0;i<18;i++)
		{
			data[i]=9999;
		}

		//Parse the response
		if(BitTst(readBuffer[5],5))
		{
			errorcode = ASYNCH_TIMEOUT_ERROR_LJ;
		}
		if(BitTst(readBuffer[5],4))
		{
			errorcode = ASYNCH_START_ERROR_LJ;
		}
		if(BitTst(readBuffer[5],3))
		{
			errorcode = ASYNCH_FRAME_ERROR_LJ;
		}
		if((BitTst(readBuffer[5],2))||(BitTst(readBuffer[5],1))||(BitTst(readBuffer[5],0)))
		{
			errorcode = ASYNCH_DIO_CONFIG_ERROR_LJ;
		}
		if (!((readBuffer[6]==97)&&(readBuffer[7]==(unsigned char)numWrite)&&(readBuffer[8]==(unsigned char)numRead)))
		{
			errorcode = CloseAll(localID);
			return RESPONSE_ERROR_LJ;
		}

		data[0]=readBuffer[4];
		data[1]=readBuffer[3];
		data[2]=readBuffer[2];
		data[3]=readBuffer[1];

		for(i=0;i<4;i++)
		{
			if(i >= numRead)
			{
				data[i]=9999;
			}
		}

		result = CloseAll(localID);
		if(result) return result;
	}
	else	//demo
	{
		Sleep(20);
	}

	//If we are reading more than 4 bytes, get them from the LabJack's NVRAM buffer.
	numPackets = 0;
	if(numRead>4)
	{
		numPackets = (numRead-1)/4;
		numFill = 4-(numRead%4);
		for(i=0;i<numPackets;i++)
		{
			memAddress=196+(i*4);
			if(!demo)
			{
				result = ReadMem(idnum,memAddress,&data[4+(i*4)],&data[5+(i*4)],&data[6+(i*4)],&data[7+(i*4)]);
			}
			else
			{
				Sleep(20);
			}
			//fill unused locations with 9999
			if(numFill != 4)
			{
				for(j=0;j<numFill;j++)
				{
					data[7-j+(i*4)] = 9999;
				}
			}
			if(result) return result;
		}
	}

	return errorcode;
}


//======================================================================
//GetDriverVersion
//
//	Returns:	Version number of this DLL (SGL).
//	Inputs:		none
//	Outputs:	none
//----------------------------------------------------------------------
float GetDriverVersion(void)
{
	return VERSION;
}


//======================================================================
//GetErrorString
//
//	Returns:	nothing
//  Inputs:		errorcode		-LabJack errorcode (I32)
//				*errorString	-Must point to an array of at least 50
//								 chars (I8).
//	Outputs:	*errorString	-A sequence a characters describing the error
//								 will be copied into the char (I8) array.
//----------------------------------------------------------------------
void GetErrorString	(long errorcode,
					 char *errorString)
{
	if(BitTst(errorcode,10))
	{
		errorString = strcpy(errorString,"Windows error");
		return;
	}
	if(BitTst(errorcode,8))
	{
		errorcode -= STREAMBUFF_ERROR_OFFSET_LJ;
	}
	switch(errorcode)
	{
		case 0:		errorString = strcpy(errorString,"No error");
					break;
		case 1:		errorString = strcpy(errorString,"Unknown error");
					break;
		case 2:		errorString = strcpy(errorString,"No LabJacks found");
					break;
		case 3:		errorString = strcpy(errorString,"LabJack n not found");
					break;
		case 4:		errorString = strcpy(errorString,"Set USB buffer error");
					break;
		case 5:		errorString = strcpy(errorString,"Open handle error");
					break;
		case 6:		errorString = strcpy(errorString,"Close handle error");
					break;
		case 7:		errorString = strcpy(errorString,"Invalid ID");
					break;
		case 8:		errorString = strcpy(errorString,"Invalid array size or value");
					break;
		case 9:		errorString = strcpy(errorString,"Invalid power index");
					break;
		case 10:	errorString = strcpy(errorString,"FCDD size too big");
					break;
		case 11:	errorString = strcpy(errorString,"HVC size too big");
					break;
		case 12:	errorString = strcpy(errorString,"Read error");
					break;
		case 13:	errorString = strcpy(errorString,"Read timeout error");
					break;
		case 14:	errorString = strcpy(errorString,"Write error");
					break;
		case 15:	errorString = strcpy(errorString,"Turbo error");
					break;
		case 16:	errorString = strcpy(errorString,"Illegal channel index");
					break;
		case 17:	errorString = strcpy(errorString,"Illegal gain index");
					break;
		case 18:	errorString = strcpy(errorString,"Illegal AI command");
					break;
		case 19:	errorString = strcpy(errorString,"Illegal AO command");
					break;
		case 20:	errorString = strcpy(errorString,"Bits out of range");
					break;
		case 21:	errorString = strcpy(errorString,"Illegal number of channels");
					break;
		case 22:	errorString = strcpy(errorString,"Illegal scan rate");
					break;
		case 23:	errorString = strcpy(errorString,"Illegal number of samples");
					break;
		case 24:	errorString = strcpy(errorString,"AI response error");
					break;
		case 25:	errorString = strcpy(errorString,"LabJack RAM checksum error");
					break;
		case 26:	errorString = strcpy(errorString,"AI sequence error");
					break;
		case 27:	errorString = strcpy(errorString,"Maximum number of streams reached");
					break;
		case 28:	errorString = strcpy(errorString,"AI stream start error");
					break;
		case 29:	errorString = strcpy(errorString,"PC buffer overflow");
					break;
		case 30:	errorString = strcpy(errorString,"LabJack buffer overflow");
					break;
		case 31:	errorString = strcpy(errorString,"Stream read timeout");
					break;
		case 32:	errorString = strcpy(errorString,"Illegal number of scans");
					break;
		case 33:	errorString = strcpy(errorString,"No stream was found");
					break;
		case 40:	errorString = strcpy(errorString,"Illegal input");
					break;
		case 41:	errorString = strcpy(errorString,"Echo error");
					break;
		case 42:	errorString = strcpy(errorString,"Data echo error");
					break;
		case 43:	errorString = strcpy(errorString,"Response error");
					break;
		case 44:	errorString = strcpy(errorString,"Asynch timeout error");
					break;
		case 45:	errorString = strcpy(errorString,"Asynch start bit error");
					break;
		case 46:	errorString = strcpy(errorString,"Asynch framing error");
					break;
		case 47:	errorString = strcpy(errorString,"Asynch digital I/O state or tris error");
					break;
		case 48:	errorString = strcpy(errorString,"Caps error");
					break;
		case 49:	errorString = strcpy(errorString,"Caps error");
					break;
		case 50:	errorString = strcpy(errorString,"Caps error");
					break;
		case 51:	errorString = strcpy(errorString,"HID number caps error");
					break;
		case 52:	errorString = strcpy(errorString,"HID get attributes warning");
					break;
		case 57:	errorString = strcpy(errorString,"Wrong firmware version error");
					break;
		case 58:	errorString = strcpy(errorString,"Digital I/O state or tris error");
					break;
		case 64:	errorString = strcpy(errorString,"Could not claim all LabJacks");
					break;
		case 65:	errorString = strcpy(errorString,"Error releasing all LabJacks");
					break;
		case 66:	errorString = strcpy(errorString,"Could not claim LabJack");
					break;
		case 67:	errorString = strcpy(errorString,"Error releasing LabJack");
					break;
		case 68:	errorString = strcpy(errorString,"Claimed abandoned LabJack");
					break;
		case 69:	errorString = strcpy(errorString,"Local ID -1 thread stopped");
					break;
		case 70:	errorString = strcpy(errorString,"Stop thread timeout");
					break;
		case 71:	errorString = strcpy(errorString,"Thread termination failed");
					break;
		case 72:	errorString = strcpy(errorString,"Feature handle creation failed");
					break;
		case 73:	errorString = strcpy(errorString,"Mutex creation failed");
					break;
		case 80:	errorString = strcpy(errorString,"Synch CS state or tris error");
					break;
		case 81:	errorString = strcpy(errorString,"Synch SCK tris error");
					break;
		case 82:	errorString = strcpy(errorString,"Synch MISO tris error");
					break;
		case 83:	errorString = strcpy(errorString,"Synch MOSI tris error");
					break;
		case 89:	errorString = strcpy(errorString,"SHT1X communication error - CRC");
					break;
		case 90:	errorString = strcpy(errorString,"SHT1X communication error - MeasReady");
					break;
		case 91:	errorString = strcpy(errorString,"SHT1X communication error - ACK");
					break;
		case 92:	errorString = strcpy(errorString,"SHT1X serial reset error");
					break;

		default:	errorString=strcpy(errorString,"Unknown error code");
	}
	return;
}


//======================================================================
//GetFirmwareVersion:  Used to retrieve the firmware version from
//						the LabJack's processor.
//
//	Returns:	Version number of the LabJack firmware or 0 for error (SGL).
//	Inputs:		*idnum		-Local ID, Serial Number, or -1 for first
//							 found (I32).
//	Outputs:	*idnum		-Returns the Local ID or -1 if no LabJack is
//							 found (I32).  If error, returns 512 plus
//							 a normal LabJack errorcode.
//
//	Time:		20 ms
//----------------------------------------------------------------------
float GetFirmwareVersion (long *idnum)
{
	unsigned long dummy1=0;
	unsigned long dummy2=0;
	long errorcode;
	unsigned long dummy3=0;
	long localID;
	unsigned char sendBuffer[9]={0,0,0,0,0,0,0,0,0};
	unsigned char readBuffer[9]={0,0,0,0,0,0,0,0,0};
	long calData[20]={0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0};
	float version;
	long serialnum=0;

	//Open the specified or first found LabJack
	localID = OpenLabJack(&errorcode,LABJACK_VENDOR_ID,LABJACK_U12_PRODUCT_ID,idnum,&serialnum,calData);
	if(errorcode)
	{
		*idnum= errorcode + GETFIRMWAREVERSION_ERROR_OFFSET_LJ;
		return 0;
	}

	sendBuffer[1]=1;   //set the "ignore commands" bit
	sendBuffer[6]=83;  //watchdog command

	//Write data to the LabJack
	//errorcode = WriteRead(localID,1000,sendBuffer,readBuffer);
	errorcode = WriteRead(localID,READ_TIMEOUT_MS,sendBuffer,readBuffer);
	if(errorcode)
	{
		CloseAll(localID);
		*idnum= errorcode + GETFIRMWAREVERSION_ERROR_OFFSET_LJ;
		return 0;
	}

	version = ((float)readBuffer[1]) + (((float)readBuffer[2])/100);

	if(CloseAll(localID))
	{
		*idnum= errorcode + GETFIRMWAREVERSION_ERROR_OFFSET_LJ;
		return 0;
	}
	
	return version;
}


//======================================================================
//GetWinVersion:  Uses a Windows API function to get the OS version.
//
//	Returns:	LabJack errorcodes or 0 for no error (I32).
//	Inputs:		none
//
//	Outputs: (U32)

//----------------------------------------------------------------------
long GetWinVersion(unsigned long *majorVersion,
				   unsigned long *minorVersion,
				   unsigned long *buildNumber,
				   unsigned long *platformID,
				   unsigned long *servicePackMajor,
				   unsigned long *servicePackMinor)
{

	return -1; // -- (efs) Do we need to implement this?
}




//======================================================================
// LocalID:  Change the local ID number of a LabJack.  Changes will not take
//			 effect until the LabJack is re-enumerated.
//
//	Returns:	LabJack errorcodes or 0 for no error (I32).
//	Inputs:		*idnum		-Local ID, Serial Number, or -1 for first
//							 found (I32).
//				localID		-New local ID (I32).
//	Outputs:	*idnum		-Returns the Local ID or -1 if no LabJack is
//							 found (I32).
//
//	Time:		20 ms
//----------------------------------------------------------------------
long LocalID(long *idnum,
			 long localID)
{
	long errorcode;

	//Make sure inputs are valid
	if ((localID<0) || (localID>255))
	{
		errorcode=INVALID_ID_LJ;
		return errorcode;
	}

	errorcode = WriteMem(idnum,1,8,0,0,0,localID);

	return errorcode;
}



//======================================================================
// NoThread:  Use this function to disable/enable (enabled by default)
//            thread creation when this DLL reads data from a particular
//			  LabJack.  If noThread is TRUE, it also sends a dummy write
//			  followed by a dummy write/read to initialize that LabJack,
//			  since in normal operation the LabJack does not respond to
//			  the first command after reset/enumeration.
//
//			  Normally, the DLL creates a thread when it attempts to
//			  read data from the LabJack.  This way, if something goes
//			  wrong, the thread can be terminated after a timeout
//			  period rather than the the program just getting stuck
//			  while it waits for a read that might never complete.
//			  This would happen if Windows thinks the LabJack is
//			  present and operating correctly, but the LabJack does
//			  not send data, or Windows doesn't realize the LabJack
//			  has sent data.  We are not sure if this is possible, but
//			  just to be safe we normally lauch the read in a thread
//			  that can be terminated after a timeout period.
//
//			  We have found 2 situations where creating the thread
//			  causes a problem:
//			  1.  When using TestPoint on Windows 98SE (and ME?),
//			      the Windows API call CreateThread cannot be used
//				  in a DLL that is being interfaced.
//			  2.  In VC, creating a thread is very slow in the
//				  debugger.  If you call a function like AISample
//				  while in the debugger, it might take 200 ms to
//				  execute instead of 20 ms.
//
//			  If you fall into case #1 above, or if case #2 is too
//			  slow for your VC debugging needs, you should call this
//			  function, NoThread, before calling any other LabJack
//			  functions.  NoThread must be called first thing any
//			  time the LabJack enumerates.  If you use NoThread, but
//			  are concerned about your program getting stuck, you
//			  can use the Watchdog function to configure the LabJack
//			  to reset if it does not communicate with the PC within
//			  a given time.  When the LabJacks resets, the read
//			  function should stop waiting for data and return
//			  an error.
//
//			  If the read thread is disabled, the "timeout"
//			  specified in AIBurst and AIStreamRead is also disabled.
// 
//
//	Returns:	LabJack errorcodes or 0 for no error (I32).
//	Inputs:		*idnum		-Local ID, Serial Number, or -1 for first
//							 found (I32).
//				noThread	-If >0, the thread will not be used (I32).
//	Outputs:	*idnum		-Returns the Local ID or -1 if no LabJack is
//							 found (I32).
//
//	Time:		80 ms
//----------------------------------------------------------------------
long NoThread(long *idnum, long noThread)
{
	long errorcode;
	long localID;
	unsigned char sendBuffer[9]={0,0,0,0,0,0,0,0,0};
	long calData[20]={0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0};
	long stateIO=0;
	long channels[4]={0,0,0,0};
	long gains[4]={0,0,0,0};
	long ov;
	float voltages[4]={0,0,0,0};
	long serialnum=0;


	//Open the specified or first found LabJack
	localID = OpenLabJack(&errorcode,LABJACK_VENDOR_ID,LABJACK_U12_PRODUCT_ID,idnum,&serialnum,calData);
	if(errorcode)
	{
		*idnum=-1;
		return errorcode;
	}

	//Use the noThread input to set the noThread parameter of
	//the labjackInfo structure for this LabJack.
	noThreadArray[localID] = noThread;

	sendBuffer[6]=80;  //read FRAM

    //Write data to the LabJack to initialize
	if(noThread)
	{
		errorcode = WriteLabJack(localID,sendBuffer);
		if(errorcode)
		{
			CloseAll(localID);
			return errorcode;
		}
	}

	errorcode = CloseAll(localID);

	Sleep(25);
	voltages[0]=0;
	voltages[1]=0;
	voltages[2]=0;
	voltages[3]=0;
	AISample (idnum,0,&stateIO,0,1,1,channels,gains,0,&ov,voltages);
	Sleep(25);
	return errorcode;
}



//======================================================================
// PulseOut:	Requires firmware V1.05 or higher.
//
//				The timeout of this function, in milliseconds, is set to:
//					5000+numPulses*((B1*C1*0.02)+(B2*C2*0.02))
//
//				This command creates pulses on any/all of D0-D7.  The
//				desired D lines must be set to output using another
//				function (DigitalIO or AOUpdate).  All selected lines
//				are pulsed at the same time, at the same rate, for the
//				same number of pulses.
//
//				This function commands the time for the first half cycle
//				of each pulse, and the second half cycle of each pulse.
//				Each time is commanded by sending a value B & C, where
//				the time is,
//
//				1st half-cycle microseconds = ~17 + 0.83*C + 20.17*B*C
//				2nd half-cycle microseconds = ~12 + 0.83*C + 20.17*B*C
//
//				which can be approximated as,
//
//				microseconds = 20*B*C
//
//				For best accuracy when using the approximation, minimize C.
//				B and C must be between 1 and 255, so each half cycle can
//				vary from about 38/33 microseconds to just over 1.3 seconds.
//
//				If you have enabled the LabJack Watchdog function, make sure
//				it's timeout is longer than the time it takes to output all
//				pulses.
//
//	Returns:	LabJack errorcodes or 0 for no error (I32).
//	Inputs:		*idnum		-Local ID, Serial Number, or -1 for first
//							 found (I32).
//				demo		-Send 0 for normal operation, >0 for demo
//							 mode (I32).  Demo mode allows this function to
//							 be called without a LabJack, and does little but
//							 simulate execution time.
//				lowFirst	-If >0, each line is set low then high, otherwise
//							 the lines are set high then low (I32).
//				bitSelect	-Set bits 0 to 7 to enable pulsing on each of
//							 D0-D7 (I32, 0-255).
//				numPulses	-Number of pulses for all lines (I32, 1-32767).
//				timeB1		-B value for first half cycle (I32, 1-255).
//				timeC1		-C value for first half cycle (I32, 1-255).
//				timeB2		-B value for second half cycle (I32, 1-255).
//				timeC2		-C value for second half cycle (I32, 1-255).
//	Outputs:	*idnum		-Returns the Local ID or -1 if no LabJack is
//							 found (I32).
//
//	Time:		20 ms plus pulse time (make sure watchdog is longer if active)
//----------------------------------------------------------------------
long PulseOut(long *idnum,
			  long demo,
			  long lowFirst,
			  long bitSelect,
			  long numPulses,
			  long timeB1,
			  long timeC1,
			  long timeB2,
			  long timeC2)
{
	long errorcode;
	long localID;
	unsigned char sendBuffer[9]={0,0,0,0,0,0,0,0,0};
	unsigned char readBuffer[9]={0,0,0,0,0,0,0,0,0};
	long calData[20]={0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0};
	long pulseMS = 0;
	long timeoutMS = 0;
	long serialnum=0;


	//Make sure each input is within the proper range
	if ((bitSelect<0) || (bitSelect>255))
	{
		errorcode=ILLEGAL_INPUT_ERROR_LJ;
		*idnum=-1;
		return errorcode;
	}
	if ((numPulses<1) || (numPulses>32767))
	{
		errorcode=ILLEGAL_INPUT_ERROR_LJ;
		*idnum=-1;
		return errorcode;
	}
	if ((timeB1<1) || (timeB1>255))
	{
		errorcode=ILLEGAL_INPUT_ERROR_LJ;
		*idnum=-1;
		return errorcode;
	}
	if ((timeC1<1) || (timeC1>255))
	{
		errorcode=ILLEGAL_INPUT_ERROR_LJ;
		*idnum=-1;
		return errorcode;
	}
	if ((timeB2<1) || (timeB2>255))
	{
		errorcode=ILLEGAL_INPUT_ERROR_LJ;
		*idnum=-1;
		return errorcode;
	}
	if ((timeC2<1) || (timeC2>255))
	{
		errorcode=ILLEGAL_INPUT_ERROR_LJ;
		*idnum=-1;
		return errorcode;
	}


	pulseMS = (long)((float)numPulses * (((float)(timeB1*timeC1)*0.02) + ((float)(timeB2*timeC2)*0.02)));
	timeoutMS = pulseMS + 5000;

	//Do demo here
	if(demo)
	{
		Sleep(14 + ((long)(6.0F * (float)rand()/(float)RAND_MAX)) + pulseMS);
		return NO_ERROR_LJ;
	}

	//Open the specified or first found LabJack
	localID = OpenLabJack(&errorcode,LABJACK_VENDOR_ID,LABJACK_U12_PRODUCT_ID,idnum,&serialnum,calData);
	if(errorcode)
	{
		*idnum=-1;
		return errorcode;
	}

	//Make sure firmware is V1.05 or higher
    printf("serial number is %ld", serialnum);
	if(serialnum < 100010000)
	{
		CloseAll(localID);
		return WRONG_FIRMWARE_VERSION_LJ;
	}

	//Fill sendBuffer with the proper values.
	//	buffer		 B1
	//	buffer+1	 C1  
	//	buffer+2	 B2
	//	buffer+3	 C2
	//	buffer+4	 Bit Mask for D7..D0  (set a bit to pulse that D line)
	//	buffer+5	 011XX100  (Command)
	//	buffer+6	 H,MSB  (L=Clear First?, MSB Number of Pulses is upper 7 bits)
	//	buffer+7	 LSB Number of Pulses

	sendBuffer[6]=100;  //Pulseout command
	sendBuffer[1]=(unsigned char)timeB1;
	sendBuffer[2]=(unsigned char)timeC1;
	sendBuffer[3]=(unsigned char)timeB2;
	sendBuffer[4]=(unsigned char)timeC2;
	sendBuffer[5]=(unsigned char)bitSelect;
	sendBuffer[7]=(unsigned char)(numPulses/256);
	sendBuffer[8]=(unsigned char)(numPulses%256);
	if(lowFirst)
	{
		sendBuffer[7] = BitSet(sendBuffer[7],7);  //set bit 7
	}

	//Write & Read data to/from the LabJack
	errorcode = WriteRead(localID,timeoutMS,sendBuffer,readBuffer);
	if(errorcode)
	{
		CloseAll(localID);
		return errorcode;
	}

	if(readBuffer[5] != 0)
	{
		CloseAll(localID);
		return DIO_CONFIG_ERROR_LJ;
	}

	if(readBuffer[6] != 100)
	{
		CloseAll(localID);
		return ECHO_ERROR_LJ;
	}

	errorcode = CloseAll(localID);

	return errorcode;
}




//======================================================================
// PulseOutStart:	Requires firmware V1.07 or higher.
//
//					PulseOutStart and PulseOutFinish are used as an
//					alternative to PulseOut.  PulseOutStart starts the
//					pulse output and returns without waiting for the
//					finish.  PulseOutFinish waits for the LabJack's
//					response which signifies the end of the pulse
//					output.  If anything besides PulseOutFinish is
//					called after PulseOutStart, the pulse output
//					will be terminated and the LabJack will execute
//					the new command.  
//
//					Note that due to boot-up tests on the LabJack
//					U12, if PulseOutStart is the first command sent
//					to the LabJack after reset or power-up, there
//					would be no response for PulseOutFinish.  In
//					practice, even if no precautions were taken, this
//					would probably never happen, since before calling
//					PulseOutStart a call is needed to set the desired
//					D lines to output.
//
//					Also note that PulseOutFinish must be called before
//					the LabJack completes the pulse output to read the
//					response.  If PulseOutFinish is not called until
//					after the LabJack sends it's response, the function
//					will never receive the response and will timeout.
//
//				This command creates pulses on any/all of D0-D7.  The
//				desired D lines must be set to output using another
//				function (DigitalIO or AOUpdate).  All selected lines
//				are pulsed at the same time, at the same rate, for the
//				same number of pulses.
//
//				This function commands the time for the first half cycle
//				of each pulse, and the second half cycle of each pulse.
//				Each time is commanded by sending a value B & C, where
//				the time is,
//
//				1st half-cycle microseconds = ~17 + 0.83*C + 20.17*B*C
//				2nd half-cycle microseconds = ~12 + 0.83*C + 20.17*B*C
//
//				which can be approximated as,
//
//				microseconds = 20*B*C
//
//				For best accuracy when using the approximation, minimize C.
//				B and C must be between 1 and 255, so each half cycle can
//				vary from about 38/33 microseconds to just over 1.3 seconds.
//
//				If you have enabled the LabJack Watchdog function, make sure
//				it's timeout is longer than the time it takes to output all
//				pulses.
//
//	Returns:	LabJack errorcodes or 0 for no error (I32).
//	Inputs:		*idnum		-Local ID, Serial Number, or -1 for first
//							 found (I32).
//				demo		-Send 0 for normal operation, >0 for demo
//							 mode (I32).  Demo mode allows this function to
//							 be called without a LabJack, and does little but
//							 simulate execution time.
//				lowFirst	-If >0, each line is set low then high, otherwise
//							 the lines are set high then low (I32).
//				bitSelect	-Set bits 0 to 7 to enable pulsing on each of
//							 D0-D7 (I32, 0-255).
//				numPulses	-Number of pulses for all lines (I32, 1-32767).
//				timeB1		-B value for first half cycle (I32, 1-255).
//				timeC1		-C value for first half cycle (I32, 1-255).
//				timeB2		-B value for second half cycle (I32, 1-255).
//				timeC2		-C value for second half cycle (I32, 1-255).
//	Outputs:	*idnum		-Returns the Local ID or -1 if no LabJack is
//							 found (I32).
//
//----------------------------------------------------------------------
long PulseOutStart	(long *idnum,
					 long demo,
					 long lowFirst,
					 long bitSelect,
					 long numPulses,
					 long timeB1,
					 long timeC1,
					 long timeB2,
					 long timeC2)
{
	long errorcode;
	long localID;
	unsigned char sendBuffer[9]={0,0,0,0,0,0,0,0,0};
//	unsigned char readBuffer[9]={0,0,0,0,0,0,0,0,0};
	long calData[20]={0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0};
	long pulseMS = 0;
	long timeoutMS = 0;
	long serialnum=0;


	//Make sure each input is within the proper range
	if ((bitSelect<0) || (bitSelect>255))
	{
		errorcode=ILLEGAL_INPUT_ERROR_LJ;
		*idnum=-1;
		return errorcode;
	}
	if ((numPulses<1) || (numPulses>32767))
	{
		errorcode=ILLEGAL_INPUT_ERROR_LJ;
		*idnum=-1;
		return errorcode;
	}
	if ((timeB1<1) || (timeB1>255))
	{
		errorcode=ILLEGAL_INPUT_ERROR_LJ;
		*idnum=-1;
		return errorcode;
	}
	if ((timeC1<1) || (timeC1>255))
	{
		errorcode=ILLEGAL_INPUT_ERROR_LJ;
		*idnum=-1;
		return errorcode;
	}
	if ((timeB2<1) || (timeB2>255))
	{
		errorcode=ILLEGAL_INPUT_ERROR_LJ;
		*idnum=-1;
		return errorcode;
	}
	if ((timeC2<1) || (timeC2>255))
	{
		errorcode=ILLEGAL_INPUT_ERROR_LJ;
		*idnum=-1;
		return errorcode;
	}


	pulseMS = (long)((float)numPulses * (((float)(timeB1*timeC1)*0.02) + ((float)(timeB2*timeC2)*0.02)));
	timeoutMS = pulseMS + 5000;

	//Do demo here
	if(demo)
	{
		return NO_ERROR_LJ;
	}

	//Open the specified or first found LabJack
	localID = OpenLabJack(&errorcode,LABJACK_VENDOR_ID,LABJACK_U12_PRODUCT_ID,idnum,&serialnum,calData);
	if(errorcode)
	{
		*idnum=-1;
		return errorcode;
	}

	//Make sure firmware is V1.07 or higher
	if(serialnum < 100011007)
	{
		CloseAll(localID);
		return WRONG_FIRMWARE_VERSION_LJ;
	}

	//Fill sendBuffer with the proper values.
	//	buffer		 B1
	//	buffer+1	 C1  
	//	buffer+2	 B2
	//	buffer+3	 C2
	//	buffer+4	 Bit Mask for D7..D0  (set a bit to pulse that D line)
	//	buffer+5	 011XX100  (Command)
	//	buffer+6	 H,MSB  (L=Clear First?, MSB Number of Pulses is upper 7 bits)
	//	buffer+7	 LSB Number of Pulses

	sendBuffer[6]=100;  //Pulseout command
	sendBuffer[1]=(unsigned char)timeB1;
	sendBuffer[2]=(unsigned char)timeC1;
	sendBuffer[3]=(unsigned char)timeB2;
	sendBuffer[4]=(unsigned char)timeC2;
	sendBuffer[5]=(unsigned char)bitSelect;
	sendBuffer[7]=(unsigned char)(numPulses/256);
	sendBuffer[8]=(unsigned char)(numPulses%256);
	if(lowFirst)
	{
		sendBuffer[7] = BitSet(sendBuffer[7],7);  //set bit 7
	}

	//Write to the LabJack
	errorcode = WriteLabJack(localID,sendBuffer);
	if(errorcode)
	{
		CloseAll(localID);
		return errorcode;
	}

	errorcode = CloseAll(localID);

	return errorcode;
}



//======================================================================
// PulseOutFinish:	Requires firmware V1.07 or higher.
//
//					PulseOutStart and PulseOutFinish are used as an
//					alternative to PulseOut.  PulseOutStart starts the
//					pulse output and returns without waiting for the
//					finish.  PulseOutFinish waits for the LabJack's
//					response which signifies the end of the pulse
//					output.  If anything besides PulseOutFinish is
//					called after PulseOutStart, the pulse output
//					will be terminated and the LabJack will execute
//					the new command.  
//
//					Note that due to boot-up tests on the LabJack
//					U12, if PulseOutStart is the first command sent
//					to the LabJack after reset or power-up, there
//					would be no response for PulseOutFinish.  In
//					practice, even if no precautions were taken, this
//					would probably never happen, since before calling
//					PulseOutStart a call is needed to set the desired
//					D lines to output.
//
//					Also note that PulseOutFinish must be called before
//					the LabJack completes the pulse output to read the
//					response.  If PulseOutFinish is not called until
//					after the LabJack sends it's response, the function
//					will never receive the response and will timeout.
//
//	Returns:	LabJack errorcodes or 0 for no error (I32).
//	Inputs:		*idnum		-Local ID, Serial Number, or -1 for first
//							 found (I32).
//				demo		-Send 0 for normal operation, >0 for demo
//							 mode (I32).  Demo mode allows this function to
//							 be called without a LabJack, and does little but
//							 simulate execution time.
//				timeoutMS	-Amount of time, in milliseconds, that this
//							 function will wait for the Pulseout response (I32).
//	Outputs:	*idnum		-Returns the Local ID or -1 if no LabJack is
//							 found (I32).
//
//----------------------------------------------------------------------
long PulseOutFinish	(long *idnum,
					 long demo,
					 long timeoutMS)
{
	long errorcode;
	long localID;
//	unsigned char sendBuffer[9]={0,0,0,0,0,0,0,0,0};
	unsigned char readBuffer[9]={0,0,0,0,0,0,0,0,0};
	long calData[20]={0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0};
	long serialnum=0;


	//Do demo here
	if(demo)
	{
		return NO_ERROR_LJ;
	}

	//Open the specified or first found LabJack
	localID = OpenLabJack(&errorcode,LABJACK_VENDOR_ID,LABJACK_U12_PRODUCT_ID,idnum,&serialnum,calData);
	if(errorcode)
	{
		*idnum=-1;
		return errorcode;
	}

	//Make sure firmware is V1.07 or higher
	if(serialnum < 100011007)
	{
		CloseAll(localID);
		return WRONG_FIRMWARE_VERSION_LJ;
	}

	//Read the Pulseout response
	errorcode = ReadLabJack(localID,timeoutMS,0,readBuffer);
	if(errorcode)
	{
		CloseAll(localID);
		return errorcode;
	}

	if(readBuffer[5] != 0)
	{
		CloseAll(localID);
		return DIO_CONFIG_ERROR_LJ;
	}

	if(readBuffer[6] != 100)
	{
		CloseAll(localID);
		return ECHO_ERROR_LJ;
	}

	errorcode = CloseAll(localID);

	return errorcode;
}



//======================================================================
// PulseOutCalc:
//
//				This function can be used to calculate the cycle times
//				for PulseOut or PulseOutStart.
//
//	Returns:	LabJack errorcodes or 0 for no error (I32).
//	Inputs:		*frequency	-Desired frequency in Hz (SGL).
//	Outputs:	*frequency	-Actual best frequency found in Hz (SGL).
//				*timeB		-B value for first and second half cycle (I32).
//				*timeC		-C value for first and second half cycle (I32).
//
//	Time:		
//----------------------------------------------------------------------
long PulseOutCalc(	float *frequency,
					long *timeB,
					long *timeC)
{
	long errorcode;
	long b,c;
	float bf,cf;
	float ferror=999999.0;
	float ferrorbest=999999.0;
	float fdesired,fcurrent;

	fdesired = *frequency;

	//Make sure each input is within the proper range
	if ((fdesired<0.763) || (fdesired>28436))
	{
		errorcode=ILLEGAL_INPUT_ERROR_LJ;
		return errorcode;
	}

	for(b=1;b<256;b++)
	{
		for(c=1;c<256;c++)
		{
			bf=(float)b;
			cf=(float)c;
			fcurrent=1000000/((85+5*cf+121*bf*cf)/3);
			ferror=fdesired-fcurrent;
			if(ferror<0)
			{
				ferror = -1.0F*ferror;
			}
			if(ferror<ferrorbest)
			{
				ferrorbest=ferror;
				*timeB=b;
				*timeC=c;
				*frequency=fcurrent;
			}
			//if f is too large, no need to check every c
			if((fdesired-fcurrent)>0) break;
		}
	}
	
	return 0;
}



//======================================================================
// ReEnum:  Causes the LabJack to detach and re-attach from the bus
//			so it will re-enumerate.  Configuration constants (local ID,
//			power allowance, calibration data) are updated.
//
//	Returns:	LabJack errorcodes or 0 for no error (I32).
//	Inputs:		*idnum		-Local ID, Serial Number, or -1 for first
//							 found (I32).
//	Outputs:	*idnum		-Returns the Local ID or -1 if no LabJack is
//							 found (I32).
//
//	Time:		10 ms
//----------------------------------------------------------------------
long ReEnum(long *idnum)
{
	long errorcode;
	long localID;
	unsigned char sendBuffer[9]={0,0,0,0,0,0,0,0,0};
	long calData[20]={0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0};
	long serialnum=0;


	//Open the specified or first found LabJack
	localID = OpenLabJack(&errorcode,LABJACK_VENDOR_ID,LABJACK_U12_PRODUCT_ID,idnum,&serialnum,calData);
	if(errorcode)
	{
		*idnum=-1;
		return errorcode;
	}

	sendBuffer[6]=64;

	//Write data to the LabJack
	errorcode = WriteLabJack(localID,sendBuffer);
	if(errorcode)
	{
		CloseAll(localID);
		return errorcode;
	}
	errorcode = CloseAll(localID);

	return errorcode;
}



//======================================================================
// Reset:	Causes the LabJack to reset after about 2 seconds.
//
//	Returns:	LabJack errorcodes or 0 for no error (I32).
//	Inputs:		*idnum		-Local ID, Serial Number, or -1 for first
//							 found (I32).
//	Outputs:	*idnum		-Returns the Local ID or -1 if no LabJack is
//							 found (I32).
//
//	Time:		10 ms
//----------------------------------------------------------------------
long Reset(long *idnum)
{
	long errorcode;
	long localID;
	unsigned char sendBuffer[9]={0,0,0,0,0,0,0,0,0};
	long calData[20]={0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0};
	long serialnum=0;


	//Open the specified or first found LabJack
	localID = OpenLabJack(&errorcode,LABJACK_VENDOR_ID,LABJACK_U12_PRODUCT_ID,idnum,&serialnum,calData);
	if(errorcode)
	{
		*idnum=-1;
		return errorcode;
	}

	sendBuffer[6]=95;

	//Write data to the LabJack
	errorcode = WriteLabJack(localID,sendBuffer);
	if(errorcode)
	{
		CloseAll(localID);
		return errorcode;
	}

	errorcode = CloseAll(localID);

	gTrisD[localID]=65535;  //referenced to PIC, 0=Output
	gTrisIO[localID]=15;  //referenced to PIC, 0=Output
	gStateD[localID]=0;  //output states
	gStateIO[localID]=0;  //output states
	gAO0[localID]=0.0F;  //current AO0 setting
	gAO1[localID]=0.0F;  //current AO1 setting

	return errorcode;
}



//======================================================================
// ResetLJ:	Same as "Reset".
//
//	Returns:	LabJack errorcodes or 0 for no error (I32).
//	Inputs:		*idnum		-Local ID, Serial Number, or -1 for first
//							 found (I32).
//	Outputs:	*idnum		-Returns the Local ID or -1 if no LabJack is
//							 found (I32).
//
//	Time:		10 ms
//----------------------------------------------------------------------
long ResetLJ(long *idnum)
{
	long errorcode;
	long localID;
	unsigned char sendBuffer[9]={0,0,0,0,0,0,0,0,0};
	long calData[20]={0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0};
	long serialnum=0;


	//Open the specified or first found LabJack
	localID = OpenLabJack(&errorcode,LABJACK_VENDOR_ID,LABJACK_U12_PRODUCT_ID,idnum,&serialnum,calData);
	if(errorcode)
	{
		*idnum=-1;
		return errorcode;
	}

	sendBuffer[6]=95;

	//Write data to the LabJack
	errorcode = WriteLabJack(localID,sendBuffer);
	if(errorcode)
	{
		CloseAll(localID);
		return errorcode;
	}

	errorcode = CloseAll(localID);

	gTrisD[localID]=65535;  //referenced to PIC, 0=Output
	gTrisIO[localID]=15;  //referenced to PIC, 0=Output
	gStateD[localID]=0;  //output states
	gStateIO[localID]=0;  //output states
	gAO0[localID]=0.0F;  //current AO0 setting
	gAO1[localID]=0.0F;  //current AO1 setting

	return errorcode;
}


//======================================================================
// SHT1X:		This function retrieves temperature and/or humidity
//				readings from a SHT1X sensor.  Data rate is about 2 kbps
//				with firmware V1.09 or higher (hardware communication).
//				If firmware is less than V1.09, or TRUE is passed for
//				softComm, data rate is about 20 bps.
//
//				DATA = IO0
//				SCK = IO1
//
//				The EI-1050 has an extra enable line that allows multiple
//				probes to be connected at the same time using only the one
//				line for DATA and one line for SCK.  This function does not
//				control the enable line.
//
//				This function automatically configures IO0 has an input
//				and IO1 as an output.
//
//				Note that internally this function operates on the state and
//				direction of IO0 and IO1, and to operate on any of the IO
//				lines the LabJack must operate on all 4.  The DLL keeps track
//				of the current direction and output state of all lines, so that
//				this function can operate on IO0 and IO1 without changing
//				IO2 and IO3.  When the DLL is first loaded,
//				though, it does not know the direction and state of
//				the lines and assumes all directions are input and
//				output states are low.
//
//	Returns:	LabJack errorcodes or 0 for no error (I32).
//	Inputs:		*idnum		-Local ID, Serial Number, or -1 for first
//							 found (I32).
//				demo		-Send 0 for normal operation, >0 for demo
//							 mode (I32).  Demo mode allows this function to
//							 be called without a LabJack, and does little but
//							 simulate execution time.
//				softComm	-If >0, forces software based communication.  Otherwise
//							 software communication is only used if the LabJack U12
//							 firmware version is less than V1.09.
//				mode		-0=temp and RH,1=temp only,2=RH only.  If mode is 2,
//							 the current temperature must be passed in for the
//							 RH corrections using *tempC.
//				statusReg	-Current value of the SHT1X status register.  The
//							 value of the status register is 0 unless you
//							 have used advanced functions to write to the
//							 status register (enabled heater, low resolution, or
//							 no reload from OTP).
//	Outputs:	*idnum		-Returns the Local ID or -1 if no LabJack is
//							 found (I32).
//				*tempC		-Returns temperature in degrees C.  If mode is 2,
//							 the current temperature must be passed in for the
//							 RH corrections.
//				*tempF		-Returns temperature in degrees F.
//				*rh			-Returns RH in percent.
//
//	Time:		About 20 ms plus SHT1X measurement time for hardware comm.
//				Default measurement time is 210 ms for temp and 55 ms for RH.
//				About 2 s per measurement for software comm.
//----------------------------------------------------------------------
long SHT1X(	long *idnum,
			long demo,
			long softComm,
			long mode,
			long statusReg,
			float *tempC,
			float *tempF,
			float *rh)
{
	long errorcode=0,result=0,i=0;
	long localID;
	unsigned char sendBuffer[9]={0,0,0,0,0,0,0,0,0};
	unsigned char readBuffer[9]={0,0,0,0,0,0,0,0,0};
	long calData[20]={0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0};
	unsigned char datatx[4]={0,0,0,0};
	unsigned char datarx[4]={0,0,0,0};
	unsigned char resettx[4]={30,0,0,0};
	long serialnum=0;
	long trisIO=0,stateIO=0;
	long numComms=0,maxNumComms=4;
	long needTemp=1,needRH=1;
	float sorh=0,rhlinear=0;
	long serialReset;

	if(demo)
	{
		Sleep(20);
		*tempC=25.0;
		*tempF=77.0;
		*rh=50.0;
		return errorcode;
	}

	//Open the specified or first found LabJack and call the asynch function
	localID = OpenLabJack(&errorcode,LABJACK_VENDOR_ID,LABJACK_U12_PRODUCT_ID,idnum,&serialnum,calData);
	if(errorcode)
	{
		*idnum=-1;
		return errorcode;
	}

	//Use software communication if requested or if firmware is < V1.09
	softComm = softComm || (serialnum < 100012000);

	//first get temperature if requested
	if(mode<=1)
	{
		serialReset=0;
		//attempt to get reading until no error or too many retries
		while(needTemp && (numComms<maxNumComms))
		{
			numComms++;
			datatx[0]=3; //temp measurement opcode
			//SHTWriteRead(localID,softComm,waitMeas,serialReset,dataRate,numWrite,numRead,*datatx,*datarx).
			errorcode=SHTWriteRead(localID,softComm,1,serialReset,0,1,3,datatx,datarx);
			if(errorcode)
			{
				if((errorcode==SHT1X_SERIAL_RESET_ERROR_LJ)||(errorcode==SHT1X_MEASREADY_ERROR_LJ)||(errorcode==SHT1X_ACK_ERROR_LJ))
				{
					serialReset=1;
					needTemp=1;
				}
				else
				{
					CloseAll(localID);
					return errorcode;
				}
			}
			else
			{
				errorcode=SHTCRC(statusReg,1,3,datatx,datarx);
				if(errorcode)
				{
					//Reset SHT1X.
					//SHTWriteRead(localID,softComm,waitMeas,serialReset,dataRate,numWrite,numRead,*datatx,*datarx).
					SHTWriteRead(localID,softComm,0,1,0,1,0,resettx,datarx);
					Sleep(12);  //just to make sure
					//if statusReg was not the default, we need to reload it
					if(statusReg!=0)
					{
						datatx[0]=6;  //write status opcode
						datatx[1]=(unsigned char)statusReg;
						//SHTWriteRead(localID,softComm,waitMeas,serialReset,dataRate,numWrite,numRead,*datatx,*datarx).
						SHTWriteRead(localID,softComm,0,1,0,2,0,datatx,datarx);
					}
					needTemp=1;
					errorcode=SHT1X_CRC_ERROR_LJ;
				}
				else
				{
					if(BitTst(statusReg,0))
					{
						//low res
						*tempC=(((float)datarx[0])*256.0F)+((float)datarx[1]);  //bits
						*tempC=(*tempC * 0.04F)-40.0F;
					}
					else
					{
						//high res
						*tempC=(((float)datarx[0])*256.0F)+((float)datarx[1]);  //bits
						*tempC=(*tempC * 0.01F)-40.0F;
					}
					*tempF=(*tempC * 9.0F / 5.0F) + 32.0F;
					needTemp=0;
					errorcode=0;
				}
			} // end else no SHTWriteRead error
		} // end while
	}
	else
	{
		//use passed tempC
		*tempF=(*tempC * 9.0F/5.0F)+32.0F;
	}

	//now get RH if requested
	if(((mode==0)||(mode>1))&&(errorcode==0))
	{
		serialReset=0;
		//attempt to get reading until no error or too many retries
		while(needRH && (numComms<=maxNumComms))
		{
			numComms++;
			datatx[0]=5;  //RH measurement opcode
			//SHTWriteRead(localID,softComm,waitMeas,serialReset,dataRate,numWrite,numRead,*datatx,*datarx).
			errorcode=SHTWriteRead(localID,softComm,1,serialReset,0,1,3,datatx,datarx);
			if(errorcode)
			{
				if((errorcode==SHT1X_SERIAL_RESET_ERROR_LJ)||(errorcode==SHT1X_MEASREADY_ERROR_LJ)||(errorcode==SHT1X_ACK_ERROR_LJ))
				{
					serialReset=1;
					needRH=1;
				}
				else
				{
					CloseAll(localID);
					return errorcode;
				}
			}
			else
			{
				errorcode=SHTCRC(statusReg,1,3,datatx,datarx);
				if(errorcode)
				{
					//Reset SHT1X.
					//SHTWriteRead(localID,softComm,waitMeas,serialReset,dataRate,numWrite,numRead,*datatx,*datarx).
					SHTWriteRead(localID,softComm,0,1,0,1,0,resettx,datarx);
					Sleep(12);  //just to make sure
					//if statusReg was not the default, we need to reload it
					if(statusReg!=0)
					{
						datatx[0]=6;  //write status opcode
						datatx[1]=(unsigned char)statusReg;
						//SHTWriteRead(localID,softComm,waitMeas,serialReset,dataRate,numWrite,numRead,*datatx,*datarx).
						SHTWriteRead(localID,softComm,0,1,0,2,0,datatx,datarx);
					}
					needRH=1;
					errorcode=SHT1X_CRC_ERROR_LJ;
				}
				else
				{
					sorh=(((float)datarx[0])*256.0F)+((float)datarx[1]);
					if(BitTst(statusReg,0))
					{
						rhlinear=(-0.00072F*sorh*sorh)+(0.648F*sorh)-4.0F;
						*rh=((*tempC-25.0F)*(0.01F+(0.00128F*sorh)))+rhlinear;
					}
					else
					{
						rhlinear=(-0.0000028F*sorh*sorh)+(0.0405F*sorh)-4.0F;
						*rh=((*tempC-25.0F)*(0.01F+(0.00008F*sorh)))+rhlinear;
					}
					needRH=0;
					errorcode=0;
				}
			} // end else no SHTWriteRead error
		} // end while
	}
	else
	{
		*rh=9999.0F;
	}

	if(errorcode)
	{
		CloseAll(localID);
	}
	else
	{
		errorcode=CloseAll(localID);
	}

	return errorcode;
}


//======================================================================
// SHTWriteRead:		Handles data communication with an SHT1X.
//----------------------------------------------------------------------
long SHTWriteRead(	long localID,
					long softComm,		// >0 means bit-bang in software
					long waitMeas,		// >0 means wait for measurement ready
					long serialReset,	// >0 means start with a serialReset
					long dataRate,		// 0=default,1=300us delay,2=1ms delay (hardware comm only)
					long numWrite,		// 0-4
					long numRead,		// 0-4
					unsigned char *datatx,  //4 byte write array
					unsigned char *datarx)	//4 byte read array
{
	long errorcode=0,i=0,j=0;
	unsigned char sendBuffer[9]={0,0,0,0,0,0,0,0,0};
	unsigned char readBuffer[9]={0,0,0,0,0,0,0,0,0};
	long trisD,stateD,trisIO,stateIO;
	long numToggles,totToggles,DATA;

	if(softComm)
	{
		//Initialize local tris and state variables
		trisD=gTrisD[localID];
		stateD=gStateD[localID];
		trisIO=gTrisIO[localID];
		stateIO=gStateIO[localID];

		//sendBuffer never changes for D lines
		sendBuffer[1]=(unsigned char)(trisD/256);	//upper byte of trisD
		sendBuffer[2]=(unsigned char)(trisD%256);	//lower byte of trisD
		sendBuffer[3]=(unsigned char)(stateD/256);	//upper byte of stateD
		sendBuffer[4]=(unsigned char)(stateD%256);	//lower byte of stateD
		sendBuffer[6]=87; //DigitalIO function
		sendBuffer[7]=1;  //update digital is true

		//Initialize DATA as input and SCK as output low
		trisIO=BitSet(trisIO,0); //In firmware, 0=Output and 1=Input
		stateIO=BitClr(stateIO,0);
		trisIO=BitClr(trisIO,1); //In firmware, 0=Output and 1=Input
		stateIO=BitClr(stateIO,1);
		sendBuffer[5]=((unsigned char)(trisIO*16)) + ((unsigned char)stateIO);
		//errorcode = WriteRead(localID,1000,sendBuffer,readBuffer);
		errorcode = WriteRead(localID,READ_TIMEOUT_MS,sendBuffer,readBuffer);
		if(errorcode) return errorcode;

		//Start with serial reset if enabled
		if(serialReset)
		{
			numToggles=10;
			totToggles=0;
			while(numToggles>0)
			{
				stateIO=BitSet(stateIO,1); //Set SCK
				sendBuffer[5]=((unsigned char)(trisIO*16)) + ((unsigned char)stateIO);
				//errorcode = WriteRead(localID,1000,sendBuffer,readBuffer);
				errorcode = WriteRead(localID,READ_TIMEOUT_MS,sendBuffer,readBuffer);
				if(errorcode) return errorcode;
				//errorcode = WriteRead(localID,1000,sendBuffer,readBuffer); //Read DATA
				errorcode = WriteRead(localID,READ_TIMEOUT_MS,sendBuffer,readBuffer); //Read DATA
				DATA=BitTst(readBuffer[4],4);
				if(errorcode) return errorcode;
				stateIO=BitClr(stateIO,1); //Clear SCK
				sendBuffer[5]=((unsigned char)(trisIO*16)) + ((unsigned char)stateIO);
				//errorcode = WriteRead(localID,1000,sendBuffer,readBuffer);
				errorcode = WriteRead(localID,READ_TIMEOUT_MS,sendBuffer,readBuffer);
				if(errorcode) return errorcode;
				if(!DATA) numToggles=11;
				numToggles--;
				totToggles++;
				if(totToggles>60) return SHT1X_SERIAL_RESET_ERROR_LJ;
			}
		}

		//Transaction start
		stateIO=BitSet(stateIO,1); //Set SCK
		sendBuffer[5]=((unsigned char)(trisIO*16)) + ((unsigned char)stateIO);
		errorcode = WriteRead(localID,READ_TIMEOUT_MS,sendBuffer,readBuffer);
		if(errorcode) return errorcode;
		trisIO=BitClr(trisIO,0); //DATA Low
		sendBuffer[5]=((unsigned char)(trisIO*16)) + ((unsigned char)stateIO);
		errorcode = WriteRead(localID,READ_TIMEOUT_MS,sendBuffer,readBuffer);
		if(errorcode) return errorcode;
		stateIO=BitClr(stateIO,1); //Clear SCK
		sendBuffer[5]=((unsigned char)(trisIO*16)) + ((unsigned char)stateIO);
		errorcode = WriteRead(localID,READ_TIMEOUT_MS,sendBuffer,readBuffer);
		if(errorcode) return errorcode;
		stateIO=BitSet(stateIO,1); //Set SCK
		sendBuffer[5]=((unsigned char)(trisIO*16)) + ((unsigned char)stateIO);
		errorcode = WriteRead(localID,READ_TIMEOUT_MS,sendBuffer,readBuffer);
		if(errorcode) return errorcode;
		trisIO=BitSet(trisIO,0); //Release DATA
		sendBuffer[5]=((unsigned char)(trisIO*16)) + ((unsigned char)stateIO);
		errorcode = WriteRead(localID,READ_TIMEOUT_MS,sendBuffer,readBuffer);
		if(errorcode) return errorcode;
		stateIO=BitClr(stateIO,1); //Clear SCK
		sendBuffer[5]=((unsigned char)(trisIO*16)) + ((unsigned char)stateIO);
		errorcode = WriteRead(localID,READ_TIMEOUT_MS,sendBuffer,readBuffer);
		if(errorcode) return errorcode;

		//Write Bytes
		if(numWrite>0)
		{
			//Each byte
			for(i=0;i<numWrite;i++)
			{
				//Each bit
				for(j=0;j<8;j++)
				{
					//Update DATA
					trisIO=BitSet(trisIO,0);
					if(!BitTst(datatx[i],(7-j))) trisIO=BitClr(trisIO,0);
					sendBuffer[5]=((unsigned char)(trisIO*16)) + ((unsigned char)stateIO);
					errorcode = WriteRead(localID,READ_TIMEOUT_MS,sendBuffer,readBuffer);
					if(errorcode) return errorcode;
					stateIO=BitSet(stateIO,1); //Set SCK
					sendBuffer[5]=((unsigned char)(trisIO*16)) + ((unsigned char)stateIO);
					errorcode = WriteRead(localID,READ_TIMEOUT_MS,sendBuffer,readBuffer);
					if(errorcode) return errorcode;
					stateIO=BitClr(stateIO,1); //Clear SCK
					sendBuffer[5]=((unsigned char)(trisIO*16)) + ((unsigned char)stateIO);
					errorcode = WriteRead(localID,READ_TIMEOUT_MS,sendBuffer,readBuffer);
					if(errorcode) return errorcode;
				}
				trisIO=BitSet(trisIO,0); //Release DATA
				sendBuffer[5]=((unsigned char)(trisIO*16)) + ((unsigned char)stateIO);
				errorcode = WriteRead(localID,READ_TIMEOUT_MS,sendBuffer,readBuffer);
				if(errorcode) return errorcode;
				stateIO=BitSet(stateIO,1); //Set SCK
				sendBuffer[5]=((unsigned char)(trisIO*16)) + ((unsigned char)stateIO);
				errorcode = WriteRead(localID,READ_TIMEOUT_MS,sendBuffer,readBuffer);
				if(errorcode) return errorcode;
				errorcode = WriteRead(localID,READ_TIMEOUT_MS,sendBuffer,readBuffer); //Read DATA
				DATA=BitTst(readBuffer[4],4);
				if(errorcode) return errorcode;
				stateIO=BitClr(stateIO,1); //Clear SCK
				sendBuffer[5]=((unsigned char)(trisIO*16)) + ((unsigned char)stateIO);
				errorcode = WriteRead(localID,READ_TIMEOUT_MS,sendBuffer,readBuffer);
				if(errorcode) return errorcode;
				if(DATA) return SHT1X_ACK_ERROR_LJ;
			}
			if(waitMeas)
			{
				//Wait for measurement ready.
				DATA=1;
				i=0;
				while(DATA && (i<30))
				{
					errorcode = WriteRead(localID,READ_TIMEOUT_MS,sendBuffer,readBuffer); //Read DATA
					DATA=BitTst(readBuffer[4],4);
					if(errorcode) return errorcode;
					i++;
				}
				if(DATA) return SHT1X_MEASREADY_ERROR_LJ;
			}
		}

		//Read Bytes
		if(numRead>0)
		{
			//Each byte
			for(i=0;i<numRead;i++)
			{
				datarx[i]=0;
				//Each bit
				for(j=0;j<8;j++)
				{
					stateIO=BitSet(stateIO,1); //Set SCK
					sendBuffer[5]=((unsigned char)(trisIO*16)) + ((unsigned char)stateIO);
					errorcode = WriteRead(localID,READ_TIMEOUT_MS,sendBuffer,readBuffer);
					if(errorcode) return errorcode;
					errorcode = WriteRead(localID,READ_TIMEOUT_MS,sendBuffer,readBuffer); //Read DATA
					DATA=BitTst(readBuffer[4],4);
					if(DATA) datarx[i]=(unsigned char)(BitSet(datarx[i],(7-j)));
					if(errorcode) return errorcode;
					stateIO=BitClr(stateIO,1); //Clear SCK
					sendBuffer[5]=((unsigned char)(trisIO*16)) + ((unsigned char)stateIO);
					errorcode = WriteRead(localID,READ_TIMEOUT_MS,sendBuffer,readBuffer);
					if(errorcode) return errorcode;
				}
				//Send ACK if not last byte.
				if(i<(numRead-1))
				{
					trisIO=BitClr(trisIO,0); //DATA Low
					sendBuffer[5]=((unsigned char)(trisIO*16)) + ((unsigned char)stateIO);
					errorcode = WriteRead(localID,READ_TIMEOUT_MS,sendBuffer,readBuffer);
					if(errorcode) return errorcode;
				}
				stateIO=BitSet(stateIO,1); //Set SCK
				sendBuffer[5]=((unsigned char)(trisIO*16)) + ((unsigned char)stateIO);
				errorcode = WriteRead(localID,READ_TIMEOUT_MS,sendBuffer,readBuffer);
				if(errorcode) return errorcode;
				stateIO=BitClr(stateIO,1); //Clear SCK
				sendBuffer[5]=((unsigned char)(trisIO*16)) + ((unsigned char)stateIO);
				errorcode = WriteRead(localID,READ_TIMEOUT_MS,sendBuffer,readBuffer);
				if(errorcode) return errorcode;
				trisIO=BitSet(trisIO,0); //Release DATA
				sendBuffer[5]=((unsigned char)(trisIO*16)) + ((unsigned char)stateIO);
				errorcode = WriteRead(localID,READ_TIMEOUT_MS,sendBuffer,readBuffer);
				if(errorcode) return errorcode;
			}
		}
		
		//Reload globals with current values
		gTrisD[localID]=trisD;
		gStateD[localID]=stateD;
		gTrisIO[localID]=trisIO;
		gStateIO[localID]=stateIO;
	}
	else
	//hardware communication
	{
		//fill sendBuffer with LabJack command
		sendBuffer[4]=datatx[0];
		sendBuffer[3]=datatx[1];
		sendBuffer[2]=datatx[2];
		sendBuffer[1]=datatx[3];
		sendBuffer[6]=104; //SHT1X function
		sendBuffer[7]=(unsigned char)numWrite;
		sendBuffer[8]=(unsigned char)numRead;
		sendBuffer[5]=0;
		if(waitMeas) sendBuffer[5]=BitSet(sendBuffer[5],7);
		if(serialReset) sendBuffer[5]=BitSet(sendBuffer[5],6);
		//set delay bits if specified
		if(dataRate==1) sendBuffer[5]=BitSet(sendBuffer[5],4);
		if(dataRate==2) sendBuffer[5]=BitSet(sendBuffer[5],5);
		//send IO3 and IO2 info so they are not changed
		if(BitTst(gStateIO[localID],3)) sendBuffer[5]=BitSet(sendBuffer[5],3);
		if(BitTst(gStateIO[localID],2)) sendBuffer[5]=BitSet(sendBuffer[5],2);
		if(BitTst(gTrisIO[localID],3)) sendBuffer[5]=BitSet(sendBuffer[5],1);
		if(BitTst(gTrisIO[localID],2)) sendBuffer[5]=BitSet(sendBuffer[5],0);

		//Write & Read data to/from the LabJack
		errorcode = WriteRead(localID,READ_TIMEOUT_MS,sendBuffer,readBuffer);

		if(!errorcode)
		{
			if(BitTst(readBuffer[5],2))
			{
				errorcode = SHT1X_SERIAL_RESET_ERROR_LJ;
			}
			if(BitTst(readBuffer[5],1))
			{
				errorcode = SHT1X_MEASREADY_ERROR_LJ;
			}
			if(BitTst(readBuffer[5],0))
			{
				errorcode = SHT1X_ACK_ERROR_LJ;
			}
			if (!((readBuffer[6]==104)&&(readBuffer[7]==(unsigned char)numWrite)&&(readBuffer[8]==(unsigned char)numRead)))
			{
				errorcode = RESPONSE_ERROR_LJ;
			}
			datarx[0]=readBuffer[4];
			datarx[1]=readBuffer[3];
			datarx[2]=readBuffer[2];
			datarx[3]=readBuffer[1];
		}
	}

	return errorcode;
}



//======================================================================
// SHTCRC:		Checks the CRC on a SHT1X communication.  Last byte of
//				datarx is the CRC.  Returns 0 if CRC is good, or
//				SHT1X_CRC_ERROR_LJ if CRC is bad.
//----------------------------------------------------------------------
long SHTCRC(	long statusReg,
				long numWrite,		// 0-4
				long numRead,		// 0-4
				unsigned char *datatx,  //4 byte write array
				unsigned char *datarx)	//4 byte read array
{
	long errorcode=0,i=0,numBytes=0;
	unsigned char crc;
	unsigned char crcRead;
	unsigned char data[8]={0};
	unsigned char crcTable[256]={0, 49, 98, 83, 196, 245,166, 151,185, 136,219, 234,125, 76, 31, 46, 67, 114,33, 16,
								135, 182,229, 212,250, 203,152, 169,62, 15, 92, 109,134, 183,228, 213,66, 115,32, 17,
								63, 14, 93, 108,251, 202,153, 168,197, 244,167, 150,1, 48, 99, 82, 124, 77, 30, 47,
								184, 137,218, 235,61, 12, 95, 110,249, 200,155, 170,132, 181,230, 215,64, 113,34, 19,
								126, 79, 28, 45, 186, 139,216, 233,199, 246,165, 148,3, 50, 97, 80, 187, 138,217, 232,
								127, 78, 29, 44, 2, 51, 96, 81, 198, 247,164, 149,248, 201,154, 171,60, 13, 94, 111,
								65, 112,35, 18, 133, 180,231, 214,122, 75, 24, 41, 190, 143,220, 237,195, 242,161, 144,
								7, 54, 101, 84, 57, 8, 91, 106,253, 204,159, 174,128, 177,226, 211,68, 117,38, 23,
								252, 205,158, 175,56, 9, 90, 107,69, 116,39, 22, 129, 176,227, 210,191, 142,221, 236,
								123, 74, 25, 40, 6, 55, 100, 85, 194, 243,160, 145,71, 118,37, 20, 131, 178,225, 208,
								254, 207,156, 173,58, 11, 88, 105,4, 53, 102, 87, 192, 241,162, 147,189, 140,223, 238,
								121, 72, 27, 42, 193, 240,163, 146,5, 52, 103, 86, 120, 73, 26, 43, 188, 141,222, 239,
								130, 179,224, 209,70, 119,36, 21, 59, 10, 89, 104,255, 206,157, 172};

	/* The following is a test transmission that has a good CRC (26)
	statusReg=0;
	numWrite=1;
	numRead=3;
	datatx[0]=5;
	datarx[0]=9;
	datarx[1]=49;
	datarx[2]=26;
	*/

	//We only get a CRC with read operations
	if(numRead<1) return SHT1X_CRC_ERROR_LJ;

	//Initialize CRC
	crc=ReverseByte((unsigned char)statusReg);

	//CRC returned by SHT1X must be reversed
	crcRead=ReverseByte(datarx[numRead-1]);

	//Combine write and read data
	numBytes=numWrite+numRead-1;  //subtract 1 for CRC byte
	for(i=0;i<8;i++)
	{
		if(i<numBytes)
		{
			if(i<numWrite)
			{
				data[i]=datatx[i];
			}
			else
			{
				data[i]=datarx[i-numWrite];
			}
		}
		else data[i]=0;
	}

	for(i=0;i<numBytes;i++)
	{
		crc=crc^data[i];
		crc=crcTable[crc];
	}

	if(crc != crcRead)
	{
		errorcode=SHT1X_CRC_ERROR_LJ;
	}

	return errorcode;
}



//======================================================================
// ReverseByte:		Reverses the bits in a byte.
//----------------------------------------------------------------------
unsigned char ReverseByte(unsigned char byteIn)
{
	long i;
	unsigned char byteOut=0;

	for(i=0;i<8;i++)
	{
		if(BitTst(byteIn,i)) byteOut=(unsigned char)(BitSet(byteOut,7-i));
	}

	return byteOut;
}



//======================================================================
// SHTComm:		Low-level public function to send and receive up to 4 bytes
//				to from an SHT1X sensor.  Data rate is about 2 kbps
//				with firmware V1.09 or higher (hardware communication).
//				If firmware is less than V1.09, or TRUE is passed for
//				softComm, data rate is about 20 bps.
//
//				DATA = IO0
//				SCK = IO1
//
//				The EI-1050 has an extra enable line that allows multiple
//				probes to be connected at the same time using only the one
//				line for DATA and one line for SCK.  This function does not
//				control the enable line.
//
//				This function automatically configures IO0 has an input
//				and IO1 as an output.
//
//				Note that internally this function operates on the state and
//				direction of IO0 and IO1, and to operate on any of the IO
//				lines the LabJack must operate on all 4.  The DLL keeps track
//				of the current direction and output state of all lines, so that
//				this function can operate on IO0 and IO1 without changing
//				IO2 and IO3.  When the DLL is first loaded,
//				though, it does not know the direction and state of
//				the lines and assumes all directions are input and
//				output states are low.
//
//	Returns:	LabJack errorcodes or 0 for no error (I32).
//	Inputs:		*idnum		-Local ID, Serial Number, or -1 for first
//							 found (I32).
//				softComm	-If >0, forces software based communication.  Otherwise
//							 software communication is only used if the LabJack U12
//							 firmware version is less than V1.09.
//				waitMeas	-If >0, this is a T or RH measurement request.
//				serialReset	-If >0, a serial reset is issued before sending and
//							 receiving bytes.
//				dataRate	-0=no extra delay (default),1=medium delay,2=max delay.
//				numWrite	-Number of bytes to write (0-4,I32).
//				numRead		-Number of bytes to read (0-4,I32).
//				*datatx		-Array of 0-4 bytes to send.  Make sure you pass at least
//							 numWrite number of bytes (U8).
//	Outputs:	*idnum		-Returns the Local ID or -1 if no LabJack is
//							 found (I32).
//				*datarx		-Returns 0-4 read bytes as determined by numRead (U8).
//
//	Time:		About 20 ms plus SHT1X measurement time for hardware comm.
//				Default measurement time is 210 ms for temp and 55 ms for RH.
//				About 2 s per measurement for software comm.
//----------------------------------------------------------------------
long SHTComm(	long *idnum,
				long softComm,
				long waitMeas,
				long serialReset,
				long dataRate,
				long numWrite,
				long numRead,
				unsigned char *datatx,
				unsigned char *datarx)
{
	long errorcode=0,i=0;
	long localID;
	unsigned char sendBuffer[9]={0,0,0,0,0,0,0,0,0};
	unsigned char readBuffer[9]={0,0,0,0,0,0,0,0,0};
	long calData[20]={0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0};
	long serialnum=0;


	//Open the specified or first found LabJack and call the asynch function
	localID = OpenLabJack(&errorcode,LABJACK_VENDOR_ID,LABJACK_U12_PRODUCT_ID,idnum,&serialnum,calData);
	if(errorcode)
	{
		*idnum=-1;
		return errorcode;
	}

	//Used software communication if requested of if firmware is < V1.09
	softComm = softComm || (serialnum < 100012000);

	//SHTWriteRead(localID,softComm,waitMeas,serialReset,dataRate,numWrite,numRead,*datatx,*datarx).
	errorcode=SHTWriteRead(localID,softComm,waitMeas,serialReset,dataRate,numWrite,numRead,datatx,datarx);

	if(errorcode)
	{
		CloseAll(localID);
	}
	else
	{
		errorcode=CloseAll(localID);
	}

	return errorcode;
}


//======================================================================
// Synch:		Requires firmware V1.09 or higher.
//
//				This function performs SPI communication.  Data rate is
//				about 160 kbps with no extra delay, although delays of
//				100 us or 1 ms per bit can be enabled.
//
//				Control of CS (chip select) can be enabled in this
//				function for D0-D7 or handled externally via any digital
//				output.
//
//				MOSI is D13
//				MISO is D14
//				SCK	is D15
//
//				If using the CB25, the protection resistors might need to be
//				shorted on all SPI connections (MOSI,MISO,SCK,CS).
//
//				The initial state of SCK is set properly (CPOL), by
//				this function, before !CS is brought low (final state is also
//				set properly before !CS is brought high again).  If chip-select
//				is being handled manually, outside of this function, care
//				must be taken to make sure SCK is initially set to CPOL.
//
//				All modes supported (A, B, C, and D).
//
//				Mode A: CPHA=1, CPOL=1
//				Mode B: CPHA=1, CPOL=0
//				Mode C: CPHA=0, CPOL=1
//				Mode D: CPHA=0, CPOL=0
//
//				If Clock Phase (CPHA) is 1, data is valid on the edge
//				going to CPOL.  If CPHA is 0, data is valid on the edge
//				going away from CPOL.
//				Clock Polarity (CPOL) determines the idle state of SCK.
//
//				Up to 18 bytes can be written/read.  Communication is full
//				duplex so 1	byte is read at the same time each byte is written.
//				If more than 4 bytes are written or read, this function uses
//				calls to WriteMem/ReadMem to load/read the LabJack's data buffer.
//
//				This function has the option (configD) to automatically configure
//				default state and direction for MOSI (D13 Output), MISO (D14 Input),
//				SCK (D15 Output CPOL), and CS (D0-D7 Output High for !CS).  This
//				function uses a call to DigitalIO to do this.  Similar to
//				EDigitalIn and EDigitalOut, the DLL keeps track of the current
//				direction and output state of all lines, so that these 4 D lines
//				can be configured without affecting other digital lines.  When the
//				DLL is first loaded, though, it does not know the direction and
//				state of the lines and assumes all directions are input and
//				output states are low.
//
//				Note that this is a simplified version of the lower
//				level function DigitalIO, which operates on all 20
//				digital lines.  The DLL keeps track of the current
//				direction and output state of all lines, so that this
//				easy function can operate on a single line without
//				changing the others.  When the DLL is first loaded,
//				though, it does not know the direction and state of
//				the lines and assumes all directions are input and
//				output states are low.
//
//	Returns:	LabJack errorcodes or 0 for no error (I32).
//	Inputs:		*idnum		-Local ID, Serial Number, or -1 for first
//							 found (I32).
//				demo		-Send 0 for normal operation, >0 for demo
//							 mode (I32).  Demo mode allows this function to
//							 be called without a LabJack, and does little but
//							 simulate execution time.
//				mode		-Specify SPI mode as: 0=A,1=B,2=C,3=D (I32, 0-3).
//				msDelay		-If >0, a 1 ms delay is added between each bit.
//				husDelay	-If >0, a hundred us delay is added between each bit.
//				controlCS	-If >0, D0-D7 is automatically controlled as CS.  The
//							 state and direction of CS is only tested if control
//							 is enabled.
//				csLine		-D line to use as CS if enabled (I32, 0-7).
//				csState		-Active state for CS line.  This would be 0 for the
//							 normal !CS, or >0 for the less common CS.
//				configD		-If >0, state and tris are configured for D13, D14,
//							 D15, and !CS.
//				numWriteRead	-Number of bytes to write and read (I32, 1-18).
//				*data		-Serial data buffer.  Send an 18 element
//							 array of bytes.  Fill unused locations with zeros (I32).
//	Outputs:	*idnum		-Returns the Local ID or -1 if no LabJack is
//							 found (I32).
//				*data		-Serial data buffer.  Returns any serial read
//							 data.  Unused locations are filled
//							 with 9999s. (I32).
//
//	Time:		20 ms to read & write up to 4 bytes, plus 40 ms for each
//				additional 4 bytes to read or write.  Extra 20 ms if configD
//				is true.  Extra time if delays are enabled.
//----------------------------------------------------------------------
long Synch(	long *idnum,
			long demo,
			long mode,
			long msDelay,
			long husDelay,
			long controlCS,
			long csLine,
			long csState,
			long configD,
			long numWriteRead,
			long *data)
{
	long errorcode=0,result=0,i=0,j=0;
	long localID;
	unsigned char sendBuffer[9]={0,0,0,0,0,0,0,0,0};
	unsigned char readBuffer[9]={0,0,0,0,0,0,0,0,0};
	long calData[20]={0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0};
	long serialnum=0,numPackets=0,memAddress=0,numFill=0;
	long trisD=0,trisIO=0,stateD=0,stateIO=0;

	//Make sure each input is within the proper range
	if ((mode<0) || (mode>3))
	{
		errorcode=ILLEGAL_INPUT_ERROR_LJ;
		*idnum=-1;
		return errorcode;
	}
	if ((numWriteRead<1) || (numWriteRead>18))
	{
		errorcode=ILLEGAL_INPUT_ERROR_LJ;
		*idnum=-1;
		return errorcode;
	}
	if ((csLine<0) || (csLine>7))
	{
		errorcode=ILLEGAL_INPUT_ERROR_LJ;
		*idnum=-1;
		return errorcode;
	}
	for(i=0;i<18;i++)
	{
		if(i >= numWriteRead)
		{
			if(data[i] != 0)
			{
				return ARRAY_SIZE_OR_VALUE_ERROR_LJ;
			}
		}
		else
		{
			if((data[i]<0)||(data[i]>255))
			{
				return ARRAY_SIZE_OR_VALUE_ERROR_LJ;
			}
		}
	}

	//If we are writing more than 4 bytes, put them in the LabJack's NVRAM buffer.
	numPackets = 0;
	if(numWriteRead>4)
	{
		numPackets = (numWriteRead-1)/4;
		for(i=0;i<numPackets;i++)
		{
			memAddress=132+(i*4);
			if(!demo)
			{
				errorcode = WriteMem(idnum,1,memAddress,data[4+(i*4)],data[5+(i*4)],data[6+(i*4)],data[7+(i*4)]);
			}
			else
			{
				Sleep(20);
			}
			if(errorcode) return errorcode;
		}
	}

	if(!demo)
	{
		//Open the specified or first found LabJack and call the asynch function
		localID = OpenLabJack(&errorcode,LABJACK_VENDOR_ID,LABJACK_U12_PRODUCT_ID,idnum,&serialnum,calData);
		if(errorcode)
		{
			*idnum=-1;
			return errorcode;
		}

		//Make sure firmware is V1.09 or higher
		if(serialnum < 100012000)
		{
			CloseAll(localID);
			return WRONG_FIRMWARE_VERSION_LJ;
		}

		//First configure D lines if selected.
		if(configD)
		{
			//Initialize local tris and state variables
			trisD=gTrisD[localID];
			stateD=gStateD[localID];
			trisIO=gTrisIO[localID];
			stateIO=gStateIO[localID];

			//Set MOSI (D13) to output low
			trisD=BitClr(trisD,13); //In firmware, 0=Output and 1=Input
			stateD=BitClr(stateD,13);

			//Set MISO (D14) to input
			trisD=BitSet(trisD,14); //In firmware, 0=Output and 1=Input

			//Set SCK (D15) to output CPOL
			if((mode==0)||(mode==2))
			{
				//Mode A or C so SCK should be high
				trisD=BitClr(trisD,15); //In firmware, 0=Output and 1=Input
				stateD=BitSet(stateD,15);
			}
			else
			{
				//Mode B or D so SCK should be high
				trisD=BitClr(trisD,15); //In firmware, 0=Output and 1=Input
				stateD=BitClr(stateD,15);
			}

			//If controlCS is true, configure CS.
			if(controlCS)
			{
				trisD=BitClr(trisD,csLine); //In firmware, 0=Output and 1=Input
				if(csState)
				{
					stateD=BitClr(stateD,csLine); //clear CS to output-low
				}
				else
				{
					stateD=BitSet(stateD,csLine); //set !CS to output-high.
				}
			}

			//Fill sendBuffer with the proper values.
			sendBuffer[1]=(unsigned char)(trisD/256);	//upper byte of trisD
			sendBuffer[2]=(unsigned char)(trisD%256);	//lower byte of trisD
			sendBuffer[3]=(unsigned char)(stateD/256);	//upper byte of stateD
			sendBuffer[4]=(unsigned char)(stateD%256);	//lower byte of stateD
			sendBuffer[5]=((unsigned char)(trisIO*16)) + ((unsigned char)stateIO);
			sendBuffer[6]=87; //DigitalIO function
			sendBuffer[7]=0;
			
			//Set updateDigital TRUE.
			sendBuffer[7] = BitSet(sendBuffer[7],0);  //set bit 0
			
			//Write & Read data to/from the LabJack
			errorcode = WriteRead(localID,READ_TIMEOUT_MS,sendBuffer,readBuffer);
			if(errorcode)
			{
				CloseAll(localID);
				return errorcode;
			}

			//Update tris and state globals with current output values
			gTrisD[localID]=trisD;
			gTrisIO[localID]=trisIO;
			gStateD[localID]=stateD;
			gStateIO[localID]=stateIO;

			//Parse the response
			if (!((readBuffer[1]==87)||(readBuffer[1]==119)))
			{
				errorcode = CloseAll(localID);
				return RESPONSE_ERROR_LJ;
			}
		}

		//Fill sendBuffer with the proper values for Synch call.
		sendBuffer[1]=(unsigned char)(data[3]);
		sendBuffer[2]=(unsigned char)(data[2]);
		sendBuffer[3]=(unsigned char)(data[1]);
		sendBuffer[4]=(unsigned char)(data[0]);
		sendBuffer[5]=0;
		if(msDelay) sendBuffer[5]=BitSet(sendBuffer[5],7);
		if(husDelay) sendBuffer[5]=BitSet(sendBuffer[5],6);
		if(mode==0) sendBuffer[5]=BitSet(sendBuffer[5],0);
		if(mode==1) sendBuffer[5]=BitSet(sendBuffer[5],1);
		if(mode==2) sendBuffer[5]=BitSet(sendBuffer[5],2);
		if(mode==3) sendBuffer[5]=BitSet(sendBuffer[5],3);
		sendBuffer[6]=98; //Synch function
		sendBuffer[7]=(unsigned char)numWriteRead;
		sendBuffer[8]=(unsigned char)csLine;
		if(controlCS) sendBuffer[8]=BitSet(sendBuffer[8],7);
		if(csState) sendBuffer[8]=BitSet(sendBuffer[8],6);
		
		//Write & Read data to/from the LabJack
		errorcode = WriteRead(localID,READ_TIMEOUT_MS,sendBuffer,readBuffer);
		if(errorcode)
		{
			CloseAll(localID);
			return errorcode;
		}

		//Fill data array with 9999s
		for(i=0;i<18;i++)
		{
			data[i]=9999;
		}

		//Parse the response
		if(BitTst(readBuffer[5],3))
		{
			errorcode = SYNCH_CSSTATETRIS_ERROR_LJ;
		}
		if(BitTst(readBuffer[5],2))
		{
			errorcode = SYNCH_SCKTRIS_ERROR_LJ;
		}
		if(BitTst(readBuffer[5],1))
		{
			errorcode = SYNCH_MISOTRIS_ERROR_LJ;
		}
		if(BitTst(readBuffer[5],0))
		{
			errorcode = SYNCH_MOSITRIS_ERROR_LJ;
		}
		if (!((readBuffer[6]==98)&&(readBuffer[7]==(unsigned char)numWriteRead)))
		{
			errorcode = CloseAll(localID);
			return RESPONSE_ERROR_LJ;
		}

		data[0]=readBuffer[4];
		data[1]=readBuffer[3];
		data[2]=readBuffer[2];
		data[3]=readBuffer[1];

		for(i=0;i<4;i++)
		{
			if(i >= numWriteRead)
			{
				data[i]=9999;
			}
		}

		result = CloseAll(localID);
		if(result) return result;
	}
	else	//demo
	{
		Sleep(20);
	}

	//If we are reading more than 4 bytes, get them from the LabJack's NVRAM buffer.
	numPackets = 0;
	if(numWriteRead>4)
	{
		numPackets = (numWriteRead-1)/4;
		numFill = 4-(numWriteRead%4);
		for(i=0;i<numPackets;i++)
		{
			memAddress=196+(i*4);
			if(!demo)
			{
				result = ReadMem(idnum,memAddress,&data[4+(i*4)],&data[5+(i*4)],&data[6+(i*4)],&data[7+(i*4)]);
			}
			else
			{
				Sleep(20);
			}
			//fill unused locations with 9999
			if(numFill != 4)
			{
				for(j=0;j<numFill;j++)
				{
					data[7-j+(i*4)] = 9999;
				}
			}
			if(result) return result;
		}
	}

	return errorcode;
}


//======================================================================
// Watchdog:	Controls the LabJack watchdog function.
//
//	Returns:	LabJack errorcodes or 0 for no error (I32).
//	Inputs:		*idnum		-Local ID, Serial Number, or -1 for first
//							 found (I32).
//				demo		-Send 0 for normal operation, >0 for demo
//							 mode (I32).  Demo mode allows this function to
//							 be called without a LabJack, and does little but
//							 simulate execution time.
//				active		-Enables the LabJack watchdog function.  If
//							 enabled, the 32-bit counter is disabled.
//				timeout		-Timer reset value in seconds (I32).
//				reset		-If >0, the LabJack will reset on timeout (I32).
//				activeDn	-If >0, Dn will be set to stateDn upon
//							 timeout (I32).
//				stateDn		-Timeout state of Dn, 0=low, >0=high (I32).
//	Outputs:	*idnum		-Returns the Local ID or -1 if no LabJack is
//							 found (I32).
//
//	Time:		20 ms
//----------------------------------------------------------------------
long Watchdog(long *idnum,
			  long demo,
			  long active,
			  long timeout,
			  long reset,
			  long activeD0,
			  long activeD1,
			  long activeD8,
			  long stateD0,
			  long stateD1,
			  long stateD8)
{
	unsigned long dummy1=286331153;
	unsigned long dummy2=572662306;
	long errorcode;
	unsigned long dummy3=858993459;
	long localID;
	unsigned char sendBuffer[9]={0,0,0,0,0,0,0,0,0};
	unsigned char readBuffer[9]={0,0,0,0,0,0,0,0,0};
	long calData[20]={0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0};
	long serialnum=0;

	//Make sure inputs are valid
	if ((timeout<1) || (timeout>715))
	{
		errorcode=ILLEGAL_INPUT_ERROR_LJ;
		*idnum=-1;
		return errorcode;
	}

	//Do demo here
	if(demo)
	{
		Sleep(14+((long)(6.0F * (float)rand()/(float)RAND_MAX)));
		return NO_ERROR_LJ;
	}

	//Open the specified or first found LabJack
	localID = OpenLabJack(&errorcode,LABJACK_VENDOR_ID,LABJACK_U12_PRODUCT_ID,idnum,&serialnum,calData);
	if(errorcode)
	{
		*idnum=-1;
		return errorcode;
	}

	//Fill sendBuffer with the proper values.
	sendBuffer[5]=0;
	if(active)
	{
		//set bit
		sendBuffer[5] = BitSet(sendBuffer[5],0);
	}
	if(reset)
	{
		//set bit
		sendBuffer[5] = BitSet(sendBuffer[5],1);
	}
	if(activeD0)
	{
		//set bit
		sendBuffer[5] = BitSet(sendBuffer[5],7);
	}
	if(activeD1)
	{
		//set bit
		sendBuffer[5] = BitSet(sendBuffer[5],5);
	}
	if(activeD8)
	{
		//set bit
		sendBuffer[5] = BitSet(sendBuffer[5],3);
	}
	if(stateD0)
	{
		//set bit
		sendBuffer[5] = BitSet(sendBuffer[5],6);
	}
	if(stateD1)
	{
		//set bit
		sendBuffer[5] = BitSet(sendBuffer[5],4);
	}
	if(stateD8)
	{
		//set bit
		sendBuffer[5] = BitSet(sendBuffer[5],2);
	}

	sendBuffer[6]=83;
	timeout *= (6000000/65536);
	sendBuffer[7]=(unsigned char)(timeout/256);
	sendBuffer[8]=(unsigned char)(timeout%256);
	sendBuffer[1]=0;  //clear the "ignore commands" bit

	//Write & Read data to/from the LabJack
	errorcode = WriteRead(localID,READ_TIMEOUT_MS,sendBuffer,readBuffer);
	if(errorcode)
	{
		CloseAll(localID);
		return errorcode;
	}

	//Parse the response
	if(sendBuffer[5] != readBuffer[5])
	{
		errorcode=ECHO_ERROR_LJ;
		CloseAll(localID);
		return errorcode;
	}
	if(readBuffer[6] != 83)
	{
		errorcode=RESPONSE_ERROR_LJ;
		CloseAll(localID);
		return errorcode;
	}
	if(sendBuffer[7] != readBuffer[7])
	{
		errorcode=ECHO_ERROR_LJ;
		CloseAll(localID);
		return errorcode;
	}
	if(sendBuffer[8] != readBuffer[8])
	{
		errorcode=ECHO_ERROR_LJ;
		CloseAll(localID);
		return errorcode;
	}

	errorcode = CloseAll(localID);

	return errorcode;
}


//======================================================================
// Counter:	Controls and reads the counter.  The counter is disabled if
//			the watchdog timer is enabled.
//
//	Returns:	LabJack errorcodes or 0 for no error (I32).
//	Inputs:		*idnum		-Local ID, Serial Number, or -1 for first
//							 found (I32).
//				demo		-Send 0 for normal operation, >0 for demo
//							 mode (I32).  Demo mode allows this function to
//							 be called without a LabJack, and does little but
//							 simulate execution time.
//				resetCounter	-If >0, the counter is reset to zero after
//								 being read (I32).
//				enableSTB	-If >0, STB is enabled (I32).  Only works with
//							 firmware V1.02 or later.
//	Outputs:	*idnum		-Returns the Local ID or -1 if no LabJack is
//							 found (I32).
//				*stateD		-States of D0-D15 (I32).
//				*stateIO	-States of IO0-IO3 (I32).
//				*count		-Current count, before reset (U32).
//
//	Time:		20 ms
//----------------------------------------------------------------------
long Counter(long *idnum,
			 long demo,
			 long *stateD,
			 long *stateIO,
			 long resetCounter,
			 long enableSTB,
			 unsigned long *count)
{
	long errorcode;
	long localID;
	unsigned char sendBuffer[9]={0,0,0,0,0,0,0,0,0};
	unsigned char readBuffer[9]={0,0,0,0,0,0,0,0,0};
	long calData[20]={0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0};
	long serialnum=0;


	//Do demo here
	if(demo)
	{
		Sleep(14+((long)(6.0F * (float)rand()/(float)RAND_MAX)));
		*count=GetTickCount();
		return NO_ERROR_LJ;
	}

	//Open the specified or first found LabJack
	localID = OpenLabJack(&errorcode,LABJACK_VENDOR_ID,LABJACK_U12_PRODUCT_ID,idnum,&serialnum,calData);
	if(errorcode)
	{
		*idnum=-1;
		*stateD=0;
		*stateIO=0;
		*count=0;
		return errorcode;
	}

	//Fill sendBuffer with the proper values.
	sendBuffer[6]=82;
	sendBuffer[1]=0;
	if(resetCounter)
	{
		sendBuffer[1] = BitSet(sendBuffer[1],0);  //set bit
	}
	if(enableSTB)
	{
		sendBuffer[1] = BitSet(sendBuffer[1],1);  //set bit
	}

	//Write & Read data to/from the LabJack
	errorcode = WriteRead(localID,READ_TIMEOUT_MS,sendBuffer,readBuffer);
	if(errorcode)
	{
		*stateD=0;
		*stateIO=0;
		*count=0;
		CloseAll(localID);
		return errorcode;
	}

	//Parse the response
	errorcode = ParseAOResponse(readBuffer,stateD,stateIO,count);
	if(errorcode)
	{
		*stateD=0;
		*stateIO=0;
		*count=0;
		CloseAll(localID);
		return errorcode;
	}
	
	errorcode = CloseAll(localID);

	return errorcode;
}


//======================================================================
// DigitalIO:	Reads and writes to the digital I/O.
//
//	Returns:	LabJack errorcodes or 0 for no error (I32).
//	Inputs:		*idnum		-Local ID, Serial Number, or -1 for first
//							 found (I32).
//				demo		-Send 0 for normal operation, >0 for demo
//							 mode (I32).  Demo mode allows this function to
//							 be called without a LabJack, and does little but
//							 simulate execution time.
//				*trisD		-Directions for D0-D15.  0=Input, 1=Output (I32).
//				trisIO		-Directions for IO0-IO3.  0=Input, 1=Output (I32).
//				*stateD		-Output states for D0-D15 (I32).
//				*stateIO	-Output states for IO0-IO3 (I32).
//				updateDigital	-If >0, tris and state values will be written.
//								 Otherwise, just a read is performed (I32).
//	Outputs:	*idnum		-Returns the Local ID or -1 if no LabJack is
//							 found (I32).
//				*trisD		-Returns a read of the direction registers
//							 for D0-D15 (I32).
//				*stateD		-States of D0-D15 (I32).
//				*stateIO	-States of IO0-IO3 (I32).
//				*outputD	-Returns a read of the output registers
//							 for D0-D15 (I32).
//
//	Time:		20 ms
//----------------------------------------------------------------------
long DigitalIO(long *idnum,
			   long demo,
			   long *trisD,
			   long trisIO,
			   long *stateD,
			   long *stateIO,
			   long updateDigital,
			   long *outputD)
{
	long errorcode;
	int i;
	long localID;
	unsigned char sendBuffer[9]={0,0,0,0,0,0,0,0,0};
	unsigned char readBuffer[9]={0,0,0,0,0,0,0,0,0};
	long calData[20]={0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0};
	long serialnum=0;


	//Firmware expects 1=true=input and 0=false=output, but we want
	//input to be the more natural default, so flip all the bits here
	//in the LabJack driver so that 0=input and 1=output at
	//the application layer.
	for(i=0;i<16;i++)
	{
		*trisD=BitFlp(*trisD,i);
	}
	for(i=0;i<4;i++)
	{
		trisIO=BitFlp(trisIO,i);
	}

	//Make sure each DIO input is within the proper range
	if ((*trisD<0) || (*trisD>65535))
	{
		errorcode=ILLEGAL_INPUT_ERROR_LJ;
		*idnum=-1;
		return errorcode;
	}

	if ((trisIO<0) || (trisIO>15))
	{
		errorcode=ILLEGAL_INPUT_ERROR_LJ;
		*idnum=-1;
		return errorcode;
	}

	if ((*stateD<0) || (*stateD>65535))
	{
		errorcode=ILLEGAL_INPUT_ERROR_LJ;
		*idnum=-1;
		return errorcode;
	}

	if ((*stateIO<0) || (*stateIO>15))
	{
		errorcode=ILLEGAL_INPUT_ERROR_LJ;
		*idnum=-1;
		return errorcode;
	}

	//Do demo here
	if(demo)
	{
		Sleep(14+((long)(6.0F * (float)rand()/(float)RAND_MAX)));
		return NO_ERROR_LJ;
	}

	//Open the specified or first found LabJack
	localID = OpenLabJack(&errorcode,LABJACK_VENDOR_ID,LABJACK_U12_PRODUCT_ID,idnum,&serialnum,calData);
	if(errorcode)
	{
		*idnum=-1;
		*trisD=0;
		*stateD=0;
		*stateIO=0;
		*outputD=0;
		return errorcode;
	}

	//Fill sendBuffer with the proper values.
	sendBuffer[1]=(unsigned char)(*trisD/256);	//upper byte of trisD
	sendBuffer[2]=(unsigned char)(*trisD%256);	//lower byte of trisD
	sendBuffer[3]=(unsigned char)(*stateD/256);	//upper byte of stateD
	sendBuffer[4]=(unsigned char)(*stateD%256);	//lower byte of stateD
	sendBuffer[5]=((unsigned char)(trisIO*16)) + ((unsigned char)*stateIO);
	sendBuffer[6]=87;
	sendBuffer[7]=0;
	if(updateDigital)
	{
		sendBuffer[7] = BitSet(sendBuffer[7],0);  //set bit 0
	}

	//Write & Read data to/from the LabJack
	errorcode = WriteRead(localID,READ_TIMEOUT_MS,sendBuffer,readBuffer);
	if(errorcode)
	{
		*trisD=0;
		*stateD=0;
		*stateIO=0;
		*outputD=0;
		CloseAll(localID);
		return errorcode;
	}

	//Update tris and state globals with current output values
	if(updateDigital)
	{
		gTrisD[localID]=*trisD;
		gTrisIO[localID]=trisIO;
		gStateD[localID]=*stateD;
		gStateIO[localID]=*stateIO;
	}

	//Parse the response
	if (!((readBuffer[1]==87)||(readBuffer[1]==119)))
	{
		errorcode=RESPONSE_ERROR_LJ;
	}

	*stateD = ((long)readBuffer[2]) * 256;
	*stateD += ((long)readBuffer[3]);
	*stateIO = ((long)readBuffer[4]) / 16;
	*trisD = ((long)readBuffer[5]) * 256;
	*trisD += ((long)readBuffer[6]);
	for(i=0;i<16;i++)
	{
		*trisD=BitFlp(*trisD,i);
	}
	*outputD = ((long)readBuffer[7]) * 256;
	*outputD += ((long)readBuffer[8]);
	
	errorcode = CloseAll(localID);

	return errorcode;
}


//======================================================================
// BitsToVolts:	Converts a 12-bit (0-4095) binary value into a LabJack
//				voltage.  Volts=((2*Bits*Vmax/4096)-Vmax)/Gain where
//				Vmax=10 for SE, 20 for Diff.
//
//	Returns:	LabJack errorcodes or 0 for no error (I32).
//	Inputs:		chnum		-Channel index.  0-7=SE, 8-11=Diff (I32).
//				chgain		-Gain index.  0=1,1=2,...,7=20 (I32).
//				bits		-Binary value from 0-4095 (I32).
//	Outputs:	*volts		-Voltage.  SE=+/-10, Diff=+/-20 (SGL).
//----------------------------------------------------------------------
long BitsToVolts (long chnum,
				  long chgain,
				  long bits,
				  float *volts)
{
	long errorcode=NO_ERROR_LJ;
	float gain;

	if((chnum<0) || (chnum>15))
	{
		errorcode = ILLEGAL_CHANNEL_LJ;
		*volts = 9999.0;
		return errorcode;
	}

	if((chgain<0) || (chgain>7))
	{
		errorcode = ILLEGAL_GAIN_INDEX_LJ;
		*volts = 9999.0;
		return errorcode;
	}

	if((bits<0) || (bits>4095))
	{
		errorcode = BITS_OUT_OF_RANGE_LJ;
		*volts = 9999.0;
		return errorcode;
	}

	switch(chgain)
	{
		case 0:	  gain = 1.0F;
				  break;
		case 1:	  gain = 2.0F;
				  break;
		case 2:	  gain = 4.0F;
				  break;
		case 3:	  gain = 5.0F;
				  break;
		case 4:	  gain = 8.0F;
				  break;
		case 5:	  gain = 10.0F;
				  break;
		case 6:	  gain = 16.0F;
				  break;
		case 7:	  gain = 20.0F;
				  break;
		default:  errorcode=UNKNOWN_ERROR_LJ;
				  return errorcode;
	}

	if (chnum<8)
	{
		//single-ended
		*volts = ((float)bits * 20.0F / 4096.0F) - 10.0F;	
	}
	else
	{
		//differential
		*volts = (((float)bits * 40.0F / 4096.0F) - 20.0F) / gain;
	}

	return errorcode;
}



//======================================================================
//VoltsToBits:  Converts a voltage to it's 12-bit (0-4095) binary
//				representation.  Bits=(4096*((Volts*Gain)+Vmax))/(2*Vmax)
//				where Vmax=10 for SE, 20 for Diff.
//
//	Returns:	LabJack errorcodes or 0 for no error (I32).
//	Inputs:		chnum		-Channel index.  0-7=SE, 8-11=Diff (I32).
//				chgain		-Gain index.  0=1,1=2,...,7=20 (I32).
//				volts		-Voltage.  SE=+/-10, Diff=+/-20 (SGL).
//	Outputs:	*bits		-Binary value from 0-4095 (I32).
//----------------------------------------------------------------------
long VoltsToBits (long chnum,
				  long chgain,
				  float volts,
				  long *bits)
{
	long errorcode=NO_ERROR_LJ;
	float gain;

	if((chnum<0) || (chnum>15))
	{
		errorcode = ILLEGAL_CHANNEL_LJ;
		*bits = 9999;
		return errorcode;
	}

	if((chgain<0) || (chgain>7))
	{
		errorcode = ILLEGAL_GAIN_INDEX_LJ;
		*bits = 9999;
		return errorcode;
	}

	if(chnum<8)
	{
		if(volts<-10.0F) volts=-10.0F;
		if(volts>((4095.0F*20.0F/4096.0F)-10.0F)) volts=(4095.0F*20.0F/4096.0F)-10.0F;
	}
	else
	{
		if(volts<-20.0F) volts=-20.0F;
		if(volts>((4095.0F*40.0F/4096.0F)-20.0F)) volts=(4095.0F*40.0F/4096.0F)-20.0F;
	}

	switch(chgain)
	{
		case 0:	  gain = 1.0F;
				  break;
		case 1:	  gain = 2.0F;
				  break;
		case 2:	  gain = 4.0F;
				  break;
		case 3:	  gain = 5.0F;
				  break;
		case 4:	  gain = 8.0F;
				  break;
		case 5:	  gain = 10.0F;
				  break;
		case 6:	  gain = 16.0F;
				  break;
		case 7:	  gain = 20.0F;
				  break;
		default:  errorcode=UNKNOWN_ERROR_LJ;
				  return errorcode;
	}

	if (chnum<8)
	{
		//single-ended
		*bits = RoundFL((volts+10.0F)/(20.0F/4096.0F));
	}
	else
	{
		//differential
		*bits = RoundFL(((volts*gain)+20.0F)/(40.0F/4096.0F));
	}

	return errorcode;
}



//======================================================================
// ReadMem: Reads 4 bytes from a specified address in the LabJack's
//			nonvolatile memory.
//
//	Returns:	LabJack errorcodes or 0 for no error (I32).
//	Inputs:		*idnum		-Local ID, Serial Number, or -1 for first
//							 found (I32).
//				address		-Starting address of data to read
//							 from 0-8188 (I32).
//	Outputs:	*idnum		-Returns the Local ID or -1 if no LabJack is
//							 found (I32).
//				*data3		-Byte at address (I32).
//				*data2		-Byte at address+1 (I32).
//				*data1		-Byte at address+2 (I32).
//				*data0		-Byte at address+3 (I32).
//
//	Time:		20 ms
//----------------------------------------------------------------------
long ReadMem(long *idnum,
			 long address,
			 long *data3,
			 long *data2,
			 long *data1,
			 long *data0)
{
	long errorcode;
	long localID;
	unsigned char sendBuffer[9]={0,0,0,0,0,0,0,0,0};
	unsigned char readBuffer[9]={0,0,0,0,0,0,0,0,0};
	long calData[20]={0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0};
	long serialnum=0;

	//Make sure inputs are valid
	if ((address<0) || (address>8188))
	{
		errorcode=ILLEGAL_INPUT_ERROR_LJ;
		*idnum=-1;
		return errorcode;
	}

	//Open the specified or first found LabJack
	localID = OpenLabJack(&errorcode,LABJACK_VENDOR_ID,LABJACK_U12_PRODUCT_ID,idnum,&serialnum,calData);
	if(errorcode)
	{
		*idnum=-1;
		return errorcode;
	}

	//Fill sendBuffer with the proper values.
	sendBuffer[6]=80;
	sendBuffer[7]=(unsigned char)(address/256);
	sendBuffer[8]=(unsigned char)(address%256);

	//Write & Read data to/from the LabJack
	
	errorcode = WriteRead(localID,READ_TIMEOUT_MS,sendBuffer,readBuffer);
	if(errorcode)
	{
	CloseAll(localID);
	return errorcode;
	}

	//Parse the response
	if(readBuffer[1] != 80)
	{
		errorcode=RESPONSE_ERROR_LJ;
		CloseAll(localID);
		return errorcode;
	}
	if(sendBuffer[7] != readBuffer[7])
	{
		errorcode=ECHO_ERROR_LJ;
		CloseAll(localID);
		return errorcode;
	}
	if(sendBuffer[8] != readBuffer[8])
	{
		errorcode=ECHO_ERROR_LJ;
		CloseAll(localID);
		return errorcode;
	}

	*data3 = readBuffer[2];
	*data2 = readBuffer[3];
	*data1 = readBuffer[4];
	*data0 = readBuffer[5];
	
	errorcode = CloseAll(localID);

	return errorcode;
}


//======================================================================
// WriteMem: Writes 4 bytes to the LabJack's nonvolatile memory at a
//			 specified address.  The data is read back and verified
//			 after the write.  Memory 0-511 is used for configuration
//			 and calibration data.  Memory from 512-1023 is unused by the
//			 the LabJack and available for the user (this corresponds to
//			 starting addresses from 512-1020).  Memory 1024-8191 is
//			 used as a data buffer in hardware timed AI modes.
//
//	Returns:	LabJack errorcodes or 0 for no error (I32).
//	Inputs:		*idnum		-Local ID, Serial Number, or -1 for first
//							 found (I32).
//				unlocked	-If >0, addresses 0-511 are unlocked for
//							 writing (I32).
//				address		-Starting address for writing 0-8188 (I32).
//				data3		-Byte for address (I32).
//				data2		-Byte for address+1 (I32).
//				data1		-Byte for address+2 (I32).
//				data0		-Byte for address+3 (I32).
//	Outputs:	*idnum		-Returns the Local ID or -1 if no LabJack is
//							 found (I32).
//
//	Time:		20 ms
//----------------------------------------------------------------------
long WriteMem(long *idnum,
			  long unlocked,
			  long address,
			  long data3,
			  long data2,
			  long data1,
			  long data0)
{
	long errorcode;
	long localID;
	unsigned char sendBuffer[9]={0,0,0,0,0,0,0,0,0};
	unsigned char readBuffer[9]={0,0,0,0,0,0,0,0,0};
	long calData[20]={0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0};
	long serialnum=0;

	//Make sure inputs are valid
	if(unlocked)
	{
		if ((address<0) || (address>8188))
		{
			errorcode=ILLEGAL_INPUT_ERROR_LJ;
			*idnum=-1;
			return errorcode;
		}
	}
	else
	{
		if ((address<512) || (address>8188))
		{
			errorcode=ILLEGAL_INPUT_ERROR_LJ;
			*idnum=-1;
			return errorcode;
		}
	}
	if ((data3<0) || (data3>255))
	{
		errorcode=ILLEGAL_INPUT_ERROR_LJ;
		*idnum=-1;
		return errorcode;
	}
	if ((data2<0) || (data2>255))
	{
		errorcode=ILLEGAL_INPUT_ERROR_LJ;
		*idnum=-1;
		return errorcode;
	}
	if ((data1<0) || (data1>255))
	{
		errorcode=ILLEGAL_INPUT_ERROR_LJ;
		*idnum=-1;
		return errorcode;
	}
	if ((data0<0) || (data0>255))
	{
		errorcode=ILLEGAL_INPUT_ERROR_LJ;
		*idnum=-1;
		return errorcode;
	}

	//Open the specified or first found LabJack
	localID = OpenLabJack(&errorcode,LABJACK_VENDOR_ID,LABJACK_U12_PRODUCT_ID,idnum,&serialnum,calData);
	if(errorcode)
	{
		*idnum=-1;
		return errorcode;
	}

	//Fill sendBuffer with the proper values.
	sendBuffer[6]=81;
	sendBuffer[7]=(unsigned char)(address/256);
	sendBuffer[8]=(unsigned char)(address%256);
	sendBuffer[1]=((unsigned char)data3);
	sendBuffer[2]=((unsigned char)data2);
	sendBuffer[3]=((unsigned char)data1);
	sendBuffer[4]=((unsigned char)data0);

	//Write & Read data to/from the LabJack
	errorcode = WriteRead(localID,READ_TIMEOUT_MS,sendBuffer,readBuffer);
	if(errorcode)
	{
		CloseAll(localID);
		return errorcode;
	}

	//Parse the response
	if(readBuffer[1] != 81)
	{
		errorcode=RESPONSE_ERROR_LJ;
		CloseAll(localID);
		return errorcode;
	}
	if(sendBuffer[1] != readBuffer[2])
	{
		errorcode=DATA_ECHO_ERROR_LJ;
		CloseAll(localID);
		return errorcode;
	}
	if(sendBuffer[2] != readBuffer[3])
	{
		errorcode=DATA_ECHO_ERROR_LJ;
		CloseAll(localID);
		return errorcode;
	}
	if(sendBuffer[3] != readBuffer[4])
	{
		errorcode=DATA_ECHO_ERROR_LJ;
		CloseAll(localID);
		return errorcode;
	}
	if(sendBuffer[4] != readBuffer[5])
	{
		errorcode=DATA_ECHO_ERROR_LJ;
		CloseAll(localID);
		return errorcode;
	}
	if(sendBuffer[7] != readBuffer[7])
	{
		errorcode=ECHO_ERROR_LJ;
		CloseAll(localID);
		return errorcode;
	}
	if(sendBuffer[8] != readBuffer[8])
	{
		errorcode=ECHO_ERROR_LJ;
		CloseAll(localID);
		return errorcode;
	}
	
	errorcode = CloseAll(localID);

	return errorcode;
}


//======================================================================
// AOUpdate: Sets the voltages of the analog outputs.  Also
//			 controls/reads the digital IO and counter.
//
//	Returns:	LabJack errorcodes or 0 for no error (I32).
//	Inputs:		*idnum		-Local ID, Serial Number, or -1 for first
//							 found (I32).
//				demo		-Send 0 for normal operation, >0 for demo
//							 mode (I32).  Demo mode allows this function
//							 to be called without a LabJack, and does little
//							 but simulate execution time.
//				trisD		-Directions for D0-D16.  0=Input, 1=Output (I32).
//				trisIO		-Directions for IO0-IO3.  0=Input, 1=Output (I32).
//				*stateD		-Output states for D0-D16 (I32).
//				*stateIO	-Output states for IO0-IO3 (I32).
//				updateDigital	-If >0, tris and state values will be written.
//								 Otherwise, just a read is performed (I32).
//				resetCounter	-If >0, the counter is reset to zero after
//								 being read (I32).
//				analogOut0	-Voltage from 0 to 5 for AO0 (SGL).
//				analogOut1	-Voltage from 0 to 5 for AO1 (SGL).
//	Outputs:	*idnum		-Returns the Local ID or -1 if no LabJack is
//							 found (I32).
//				*stateD		-States of D0-D15 (I32).
//				*stateIO	-States of IO0-IO3 (I32).
//				*count		-Current count, before reset (U32).
//
//	Time:		20 ms
//----------------------------------------------------------------------
long AOUpdate(long *idnum,
			  long demo,
			  long trisD,
			  long trisIO,
			  long *stateD,
			  long *stateIO,
			  long updateDigital,
			  long resetCounter,
			  unsigned long *count,
			  float analogOut0,
			  float analogOut1)
{
	long errorcode,i;
	long localID;
	unsigned char sendBuffer[9]={0,0,0,0,0,0,0,0,0};
	unsigned char readBuffer[9]={0,0,0,0,0,0,0,0,0};
	long calData[20]={0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0};
	long serialnum=0;


	//Do demo here
	if(demo)
	{
		Sleep(14+((long)(6.0F * (float)rand()/(float)RAND_MAX)));
		*count=GetTickCount();
		return NO_ERROR_LJ;
	}

	//Open the specified or first found LabJack
	localID = OpenLabJack(&errorcode,LABJACK_VENDOR_ID,LABJACK_U12_PRODUCT_ID,idnum,&serialnum,calData);
	if(errorcode)
	{
		*idnum=-1;
		*stateD=0;
		*stateIO=0;
		*count=0;
		return errorcode;
	}

	if(analogOut0<0)
	{
		analogOut0=gAO0[localID];
	}

	if(analogOut1<0)
	{
		analogOut1=gAO1[localID];
	}

	//Fill sendBuffer with the proper values.
	errorcode = BuildAOCommand(trisD,trisIO,*stateD,*stateIO,updateDigital,resetCounter,analogOut0,analogOut1,sendBuffer);
	if(errorcode)
	{
		*stateD=0;
		*stateIO=0;
		*count=0;
		CloseAll(localID);
		return errorcode;
	}

	//Write & Read data to/from the LabJack
	errorcode = WriteRead(localID,READ_TIMEOUT_MS,sendBuffer,readBuffer);
	if(errorcode)
	{
		*stateD=0;
		*stateIO=0;
		*count=0;
		CloseAll(localID);
		return errorcode;
	}

	//Update tris and state globals with current output values
	if(updateDigital)
	{
		//Global tris variables are referenced to PIC, so bits must be flipped.
		for(i=0;i<16;i++)
		{
			trisD=BitFlp(trisD,i);
		}
		for(i=0;i<4;i++)
		{
			trisIO=BitFlp(trisIO,i);
		}
		gTrisD[localID]=trisD;
		gTrisIO[localID]=trisIO;
		gStateD[localID]=*stateD;
		gStateIO[localID]=*stateIO;
	}

	gAO0[localID]=analogOut0;
	gAO1[localID]=analogOut1;

	//Parse the response
	errorcode = ParseAOResponse(readBuffer,stateD,stateIO,count);
	if(errorcode)
	{
		*stateD=0;
		*stateIO=0;
		*count=0;
		CloseAll(localID);
		return errorcode;
	}
	
	errorcode = CloseAll(localID);

	return errorcode;
}


//======================================================================
// AISample: Reads the voltages from 1,2, or 4 analog inputs.  Also
//			 controls/reads the 4 IO ports.
//
//	Returns:	LabJack errorcodes or 0 for no error (I32).
//	Inputs:		*idnum		-Local ID, Serial Number, or -1 for first
//							 found (I32).
//				demo		-Send 0 for normal operation, >0 for demo
//							 mode (I32).  Demo mode allows this function
//							 to be called without a LabJack, and does
//							 little but simulate execution time.
//				*stateIO	-Output states for IO0-IO3 (I32).
//				updateIO	-If >0, state values will be written.  Otherwise,
//							 just a read is performed (I32).
//				ledOn		-If >0, the LabJack LED is turned on (I32).
//				numChannels -Number of channels.  1, 2, or 4 (I32).
//				*channels	-Pointer to an array of channel commands with
//							 at least numChannels elements (I32).  Each
//							 channel command is 0-7 for SE or 8-11 for Diff.
//				*gains		-Pointer to an array of gain commands with at
//							 least numChannels elements (I32).  Gain commands
//							 are 0=1,1=2,...,7=20.  Gain only available for
//							 differential channels.
//				disableCal	-If >0, voltages returned will be raw readings
//							 that are not corrected using calibration
//							 constants (I32).
//				*voltages	-Voltage readings buffer.  Send a 4 element
//							 array of zeros (SGL).
//	Outputs:	*idnum		-Returns the Local ID or -1 if no LabJack is
//							 found (I32).
//				*overVoltage	-If >0, an overvoltage has been detected
//								 on one of the analog inputs (I32).
//				*voltages	-Returns numChannels voltage readings (SGL).
//
//	Time:		20 ms
//----------------------------------------------------------------------
long AISample(long *idnum,
			  long demo,
			  long *stateIO,
			  long updateIO,
			  long ledOn,
			  long numChannels,
			  long *channels,
			  long *gains,
			  long disableCal,
			  long *overVoltage,
			  float *voltages)
{
	long errorcode;
	long localID=0;
	float avgVolts;
	long avgBits;
	unsigned char echoOut,echoIn;
	unsigned char sendBuff5=0;
	long i,junk=0;
	unsigned char sendBuffer[9]={0,0,0,0,0,0,0,0,0};
	unsigned char readBuffer[9]={0,0,0,0,0,0,0,0,0};
	long calData[20]={0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0};
	long ch1num,ch2num,ch3num,ch4num,ch1gain,ch2gain,ch3gain,ch4gain;
	long serialnum=0;

	//printf("inf AISample");
	//Make sure array is filled with zeros
	for(i=0;i<4;i++)
	{
		if(voltages[i] != 0)
		{
			return ARRAY_SIZE_OR_VALUE_ERROR_LJ;
		}
		voltages[i] = 9999.0F;
	}

	//Make sure inputs are valid
	if (!((numChannels==1)||(numChannels==2)||(numChannels==4)))
	{
		errorcode=ILLEGAL_NUMBER_OF_CHANNELS_LJ;
		*idnum=-1;
		*stateIO=0;
		*overVoltage=0;
		return errorcode;
	}

	if(!demo)
	{
		//Open the specified or first found LabJack
		localID = OpenLabJack(&errorcode,LABJACK_VENDOR_ID,LABJACK_U12_PRODUCT_ID,idnum,&serialnum,calData);
		if(errorcode)
		{
			*idnum=-1;
			*stateIO=0;
			*overVoltage=0;
			return errorcode;
		}
	}

	//The LabJack echos 1 byte so we can make sure we are getting the expected response
	echoOut = (unsigned char)GetTickCount();

	if(ledOn)
	{
		//set bit 0 to turn the LED on
		sendBuff5 = BitSet(sendBuff5,0);
	}
	if(updateIO)
	{
		//set bit 1 to indicate update IO
		sendBuff5 = BitSet(sendBuff5,1);
	}

	//Fill sendBuffer with the proper values.
	ch1num=channels[0];
	ch2num=channels[0];
	ch3num=channels[0];
	ch4num=channels[0];
	ch1gain=gains[0];
	ch2gain=gains[0];
	ch3gain=gains[0];
	ch4gain=gains[0];
	if(numChannels==2)
	{
		ch3num=channels[1];
		ch4num=channels[1];
		ch3gain=gains[1];
		ch4gain=gains[1];
	}
	if(numChannels==4)
	{
		ch2num=channels[1];
		ch3num=channels[2];
		ch4num=channels[3];
		ch2gain=gains[1];
		ch3gain=gains[2];
		ch4gain=gains[3];
	}
	errorcode = BuildAICommand(12,sendBuff5,0,echoOut,*stateIO,ch1num,ch2num,ch3num,ch4num,ch1gain,ch2gain,ch3gain,ch4gain,sendBuffer);
	if(errorcode)
	{
		*stateIO=0;
		*overVoltage=0;
		CloseAll(localID);
		return errorcode;
	}

	if(!demo)
	{
		//Write & Read data to/from the LabJack
		errorcode = WriteRead(localID,READ_TIMEOUT_MS,sendBuffer,readBuffer);
		if(errorcode)
		{
			*stateIO=0;
			*overVoltage=0;
			CloseAll(localID);
			return errorcode;
		}

		//Update state IO global with current output values
		if(updateIO)
		{
			gStateIO[localID]=*stateIO;
		}

		//Parse the response
		errorcode = ParseAIResponse(sendBuffer,readBuffer,disableCal,calData,stateIO,overVoltage,&voltages[0],&voltages[1],&voltages[2],&voltages[3],&echoIn,&junk,&junk,&junk,0);
		if(errorcode)
		{
			*stateIO=0;
			*overVoltage=0;
			for(i=0;i<4;i++)
			{
				voltages[i]=0;
			}
			CloseAll(localID);
			return errorcode;
		}

		if(echoOut != echoIn)
		{
			errorcode=ECHO_ERROR_LJ;
			*stateIO=0;
			*overVoltage=0;
			for(i=0;i<4;i++)
			{
				voltages[i]=0;
			}
			CloseAll(localID);
			return errorcode;
		}
	}
	else
	{
		//Demo Mode

		Sleep(14+((long)(6.0F * (float)rand()/(float)RAND_MAX)));

		voltages[0]=2.5F;
		voltages[1]=2.5F;
		voltages[2]=2.5F;
		voltages[3]=2.5F;
		if(numChannels == 2)
		{
			voltages[2] = (10.0F * ((float)rand())/((float)RAND_MAX)) - 5.0F;
			voltages[3] = (10.0F * ((float)rand())/((float)RAND_MAX)) - 5.0F;
		}
		if(numChannels == 4)
		{
			voltages[1]=-2.5F;
			voltages[2]=(10.0F * ((float)rand())/((float)RAND_MAX)) - 5.0F;
			voltages[3]=(10.0F * ((float)(GetTickCount()%2048))/2048) - 5.0F;
		}
	}
	
	if(numChannels == 1)
	{
		avgVolts = (voltages[0]+voltages[1]+voltages[2]+voltages[3])/4.0F;
		errorcode = VoltsToBits(ch1num,ch1gain,avgVolts,&avgBits);
		errorcode = BitsToVolts(ch1num,ch1gain,avgBits,&voltages[0]);
		voltages[1]=9999.0F;
		voltages[2]=9999.0F;
		voltages[3]=9999.0F;
	}

	if(numChannels == 2)
	{
		avgVolts = (voltages[0]+voltages[1])/2.0F;
		errorcode = VoltsToBits(ch1num,ch1gain,avgVolts,&avgBits);
		errorcode = BitsToVolts(ch1num,ch1gain,avgBits,&voltages[0]);
		avgVolts = (voltages[2]+voltages[3])/2.0F;
		errorcode = VoltsToBits(ch3num,ch3gain,avgVolts,&avgBits);
		errorcode = BitsToVolts(ch3num,ch3gain,avgBits,&voltages[1]);
		voltages[2]=9999.0F;
		voltages[3]=9999.0F;
	}

	if(!demo)
	{
		errorcode = CloseAll(localID);
	}

	return errorcode;
}


//======================================================================
// AIBurst: Reads a certain number of scans at a certain scan rate
//			from 1,2, or 4 analog inputs.  First, data is acquired and
//			stored in the LabJacks 4096 sample RAM buffer.  Then, the
//			data is transferred to the PC application.
//
//	Returns:	LabJack errorcodes or 0 for no error (I32).
//	Inputs:		*idnum		-Local ID, Serial Number, or -1 for first
//							 found (I32).
//				demo		-Send 0 for normal operation, >0 for demo
//							 mode (I32).  Demo mode allows this function
//							 to be called without a LabJack, and does little
//							 but simulate execution time.
//				stateIOin	-Output states for IO0-IO3 (I32).
//				updateIO	-If >0, state values will be written.  Otherwise,
//							 just reads are performed (I32).
//				ledOn		-If >0, the LabJack LED is turned on (I32).
//				numChannels -Number of channels.  1, 2, or 4 (I32).
//				*channels	-Pointer to an array of channel commands with at
//							 least numChannels elements (I32).  Each channel
//							 command is 0-7 for SE or 8-11 for Diff.
//				*gains		-Pointer to an array of gain commands with at
//							 least numChannels elements (I32).  Gain
//							 commands are 0=1,1=2,...,7=20.  Gain only
//							 available for differential channels.
//				*scanRate	-Scans acquired per second (SGL).  A scan is a
//							 reading from every channel (1,2, or 4).  The
//							 sample rate (scanRate*numChannels) must
//							 be 400-8192.
//				disableCal	-If >0, voltages returned will be raw readings
//							 that are not corrected using calibration
//							 constants (I32).
//				triggerIO	-Set the IO port to trigger on.  0=none,
//							 1=IO0,...,4=IO3 (I32).
//				triggerState	-If >0, the acquisition will be triggered
//								 when the selected IO port reads high (I32).
//				numScans	-Number of scans which will be collected (I32).
//							 Minimum is 1.  Maximum numSamples is 4096 where
//							 numSamples is numScans * numChannels.
//				timeout		-Function timeout value in seconds (I32).
//				*voltages	-Voltage readings buffer.  Send a 4096 by 4
//							 element array of zeros (SGL).
//				*stateIOout	-IO state readings buffer.  Send a 4096 element
//							 array of zeros (I32).
//				transferMode	-0=auto,1=normal,2=turbo (I32)
//	Outputs:	*idnum		-Returns the Local ID or -1 if no LabJack is
//							 found (I32).
//				*scanRate	-Returns the actual scan rate, which due to
//							 clock resolution is not always exactly the
//							 same as the desired scan rate (SGL).
//				*voltages	-Voltage readings are returned in this 4096 by
//							 4 array (SGL). Unused locations are filled
//							 with 9999s.
//				*stateIOout	-The states of all 4 IO are returned in this
//							 array (I32).  Unused locations are filled
//							 with 9999s.
//				*overVoltage	-If >0, an overvoltage has been detected on
//								 at least one sample of at least one of the
//								 analog inputs (I32).
//
//	Time:	The execution time of this function, in milliseconds, can be
//			estimated with the below formulas.  The actual number of scans
//			collected and transferred by the LabJack is the smallest power
//			of 2 from 64 to 4096 which is at least as big as numScans.  This
//			is represented below as numScansActual.
//			Normal => 30+(1000*numScansActual/scanRate)+(2.5*numScansActual)
//			Turbo  => 30+(1000*numScansActual/scanRate)+(0.4*numScansActual)
//----------------------------------------------------------------------
long AIBurst(long *idnum,
			 long demo,
			 long stateIOin,
			 long updateIO,
			 long ledOn,
			 long numChannels,
			 long *channels,
			 long *gains,
			 float *scanRate,
			 long disableCal,
			 long triggerIO,
			 long triggerState,
			 long numScans,
			 long timeout,
			 float (*voltages)[4],
			 long *stateIOout,
			 long *overVoltage,
			 long transferMode)
{
	long errorcode;
	int i,j,k,l;
	long junk=0;
	long ovtemp;
	long csError,iterationCount,previousCount;
	unsigned char junkuc=0;
	long localID=0;
	long turbo = FALSE;
	long sampleInt;
	long numScansLJ,numScansIndexLJ;
	unsigned char sendBuff5,sendBuff7,sendBuff8;
	unsigned char sendBuffer[9]={0,0,0,0,0,0,0,0,0};
	unsigned char readBuffer[9]={0,0,0,0,0,0,0,0,0};
	long calData[20]={0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0};
	unsigned char featureBuff[129]={0};
	long ch1num,ch2num,ch3num,ch4num,ch1gain,ch2gain,ch3gain,ch4gain;
	long serialnum=0;

	//junk variables for warm-up call to AISample
	long sio=0,chns[4]={0,0,0,0},gns[4]={0,0,0,0},ovlt=0;
	float vlts[4]={0,0,0,0};

	//Make sure arrays are filled with zeros
	for(i=0;i<4096;i++)
	{
		if(stateIOout[i] != 0)
		{
			return ARRAY_SIZE_OR_VALUE_ERROR_LJ;
		}
		stateIOout[i] = 9999;
	}
	for(i=0;i<4096;i++)
	{
		for(j=0;j<4;j++)
		{
			if(voltages[i][j] != 0)
			{
				return ARRAY_SIZE_OR_VALUE_ERROR_LJ;
			}
			voltages[i][j] = 9999.0F;
		}
	}

	//Make sure inputs are valid
	if (timeout<1)
	{
		errorcode=ILLEGAL_INPUT_ERROR_LJ;
		*idnum=-1;
		return errorcode;
	}
	if (!((numChannels==1)||(numChannels==2)||(numChannels==4)))
	{
		errorcode=ILLEGAL_NUMBER_OF_CHANNELS_LJ;
		return errorcode;
	}
	if ((numScans<1) || ((numScans*numChannels)>4096))
	{
		errorcode=ILLEGAL_NUM_SCANS_LJ;
		return errorcode;
	}
	switch(transferMode)
	{
		case 0:		if(timeout>=4) //Turbo mode does not work with a timeout over 4.
					{
						turbo = FALSE;
					}
					else
					{
						if((((float)numScans)/(*scanRate)) >=4.0)
						{
							turbo = FALSE;
						}
						else
						{
							turbo = TRUE;
						}
					}
					break;
		case 1:		turbo = FALSE;
					break;
		case 2:		turbo = TRUE;
					break;
		default:	return ILLEGAL_INPUT_ERROR_LJ;
	}

	//Determine how many LabJack 4-channel scans are required (1024,512,256,128,64,32,16).
	numScansIndexLJ=0;
	numScansLJ=1024;
	if((numScans*numChannels)<=2048)
	{
		numScansIndexLJ=1;
		numScansLJ=512;
		if((numScans*numChannels)<=1024)
		{
			numScansIndexLJ=2;
			numScansLJ=256;
			if((numScans*numChannels)<=512)
			{
				numScansIndexLJ=3;
				numScansLJ=128;
				if((numScans*numChannels)<=256)
				{
					numScansIndexLJ=4;
					numScansLJ=64;
					if((numScans*numChannels)<=128)
					{
						numScansIndexLJ=5;
						numScansLJ=32;
						if((numScans*numChannels)<=64)
						{
							numScansIndexLJ=6;
							numScansLJ=16;
						}
					}
				}
			}
		}
	}

	sampleInt = RoundFL(6000000.0F/(*scanRate * (float)numChannels));
	if(sampleInt == 732) sampleInt = 733;
	if ((sampleInt<733) || (sampleInt>16383))
	{
		errorcode=ILLEGAL_SCAN_RATE_LJ;
		return errorcode;
	}
	*scanRate = 6000000.0F/((float)(sampleInt * numChannels));

	if(!demo)
	{
		//Make a warm-up call to AISample to flush and init the host read buffer.
		errorcode = AISample(idnum,0,&sio,0,ledOn,4,chns,gns,0,&ovlt,vlts);
		if(errorcode) return errorcode;

		//Open the specified or first found LabJack
		localID = OpenLabJack(&errorcode,LABJACK_VENDOR_ID,LABJACK_U12_PRODUCT_ID,idnum,&serialnum,calData);
		if(errorcode)
		{
			*idnum=-1;
			return errorcode;
		}
	}

	//Build sendBuff5
	switch(triggerIO)
	{
		case 0:	  sendBuff5=0;
				  sendBuff7=0;
				  break;
		case 1:	  sendBuff5=0;
				  sendBuff7=64;
				  break;
		case 2:	  sendBuff5=8;
				  sendBuff7=64;
				  break;
				  /*
		case 3:	  sendBuff5=16;
				  sendBuff7=64;
				  break;
		case 4:	  sendBuff5=24;
				  sendBuff7=64;
				  break;
				  */
		default:  errorcode=ILLEGAL_AI_COMMAND_LJ;
				  CloseAll(localID);
				  return errorcode;
	}
	if(triggerState)
	{
		//set bit 2
		sendBuff5 = BitSet(sendBuff5,2);
	}
	if(ledOn)
	{
		//set bit 0 to turn the LED on
		sendBuff5 = BitSet(sendBuff5,0);
	}
	if(updateIO)
	{
		//set bit 1 to indicate update IO
		sendBuff5 = BitSet(sendBuff5,1);
	}
	sendBuff5 += (unsigned char)(numScansIndexLJ*32);	//sendBuff5 is ready
	if(turbo)
	{
		//set bit 7 to indicate turbo mode (feature reports)
		sendBuff7 = BitSet(sendBuff7,7);
	}

	sendBuff7 += sampleInt/256;	//sendBuff7 is ready
	sendBuff8 = sampleInt%256;	//sendBuff8 is ready

	//Fill sendBuffer with the proper values.
	ch1num=channels[0];
	ch2num=channels[0];
	ch3num=channels[0];
	ch4num=channels[0];
	ch1gain=gains[0];
	ch2gain=gains[0];
	ch3gain=gains[0];
	ch4gain=gains[0];
	if(numChannels==2)
	{
		ch2num=channels[1];
		ch4num=channels[1];
		ch2gain=gains[1];
		ch4gain=gains[1];
	}
	if(numChannels==4)
	{
		ch2num=channels[1];
		ch3num=channels[2];
		ch4num=channels[3];
		ch2gain=gains[1];
		ch3gain=gains[2];
		ch4gain=gains[3];
	}
	errorcode = BuildAICommand(10,sendBuff5,sendBuff7,sendBuff8,stateIOin,ch1num,ch2num,ch3num,ch4num,ch1gain,ch2gain,ch3gain,ch4gain,sendBuffer);
	if(errorcode)
	{
		CloseAll(localID);
		return errorcode;
	}

	//Write command to LabJack to start burst mode
	if(!demo)
	{
		errorcode=WriteLabJack(localID,sendBuffer);
		if(errorcode)
		{
			CloseAll(localID);
			return errorcode;
		}
	}

	if(!demo)
	{
		//Don't issue a read command until after data is aquired
		Sleep(2+((unsigned long)(1000*((float)numScansLJ)/(*scanRate * numChannels))));

		previousCount = 6;
		*overVoltage = 0;

		if(turbo)
		{
			//use feature reports
			//read 16 scans at a time
			for(i=0;i<(numScansLJ/16);i++)
			{
				//Read the feature report
				Sleep(1);	//delay 1ms between feature report requests
				errorcode = ReadLabJack(localID,(((unsigned long)timeout)*1000),1,featureBuff);
				if(errorcode)
				{
					//read error
					CloseAll(localID);
					return errorcode;
				}
				for(k=0;k<16;k++)
				{
					//Put each scan in readBuffer
					readBuffer[0]=0;
					for(l=0;l<8;l++)
					{
						readBuffer[l+1]=featureBuff[(k*8)+l+1];
					}
					//Parse each scan
					errorcode = ParseAIResponse(sendBuffer,readBuffer,disableCal,calData,&stateIOout[(i*16)+k],&ovtemp,&voltages[(i*16)+k][0],&voltages[(i*16)+k][1],&voltages[(i*16)+k][2],&voltages[(i*16)+k][3],&junkuc,&csError,&junk,&iterationCount,0);
					if(ovtemp) *overVoltage += 1;
					if(errorcode)
					{
						CloseAll(localID);
						return errorcode;
					}
					if(csError)
					{
						CloseAll(localID);
						return RAM_CS_ERROR_LJ;
					}
					if(iterationCount==0)
					{
						if(previousCount != 6)
						{
							CloseAll(localID);
							return AI_SEQUENCE_ERROR_LJ;
						}
					}
					else
					{
						if(iterationCount != (previousCount+1))
						{
							CloseAll(localID);
							return AI_SEQUENCE_ERROR_LJ;
						}
					}
					previousCount = iterationCount;
				}
			}
		}
		else
		{
			//use interrupt transfers
			for(i=0;i<numScansLJ;i++)
			{
				//Try to read a scan
				errorcode=ReadLabJack(localID,(((unsigned long)timeout)*1000),0,readBuffer);
				if(errorcode)
				{
					//There was a read error, so send any command to stop the LabJack
					sendBuffer[6]=80;	//ReadMem
					sendBuffer[7]=0;
					sendBuffer[8]=16;	//read address 16
					//Write & Read data to/from the LabJack
					WriteRead(localID,READ_TIMEOUT_MS,sendBuffer,readBuffer);
					CloseAll(localID);
					return errorcode;
				}	
				//Parse the response
				errorcode = ParseAIResponse(sendBuffer,readBuffer,disableCal,calData,&stateIOout[i],&ovtemp,&voltages[i][0],&voltages[i][1],&voltages[i][2],&voltages[i][3],&junkuc,&csError,&junk,&iterationCount,0);
				if(ovtemp) *overVoltage += 1;
				if(errorcode)
				{
					CloseAll(localID);
					return errorcode;
				}
				if(csError)
				{
					CloseAll(localID);
					return RAM_CS_ERROR_LJ;
				}
				if(iterationCount==0)
				{
					if(previousCount != 6)
					{
						CloseAll(localID);
						return AI_SEQUENCE_ERROR_LJ;
					}
				}
				else
				{
					if(iterationCount != (previousCount+1))
					{
						CloseAll(localID);
						return AI_SEQUENCE_ERROR_LJ;
					}
				}
				previousCount = iterationCount;
			}
		}	//end else turbo
	}
	else
	{
		//Demo Mode

		//simulate time
		Sleep(24+((long)(6.0F * (float)rand()/(float)RAND_MAX)));  //overhead time
		Sleep((long)(((float)numScansLJ * 4.0F) / (*scanRate * (float)numChannels)));  //acquisition time
		if(turbo)
		{
			Sleep((long)(((float)numScansLJ * 4.0F) * 0.4F));  //turbo transfer time
		}
		else
		{
			Sleep((long)(((float)numScansLJ * 4.0F) * 2.5F));  //normal transfer time
		}

		for(i=0;i<numScansLJ;i++)
		{
			voltages[i][0]=2.5F;
			voltages[i][1]=2.5F;
			voltages[i][2]=2.5F;
			voltages[i][3]=2.5F;
			if(numChannels == 2)
			{
				voltages[i][2] = (10.0F * ((float)rand())/((float)RAND_MAX)) - 5.0F;
				voltages[i][3] = (10.0F * ((float)rand())/((float)RAND_MAX)) - 5.0F;
			}
			if(numChannels == 4)
			{
				voltages[i][1]=-2.5F;
				voltages[i][2]=(10.0F * ((float)rand())/((float)RAND_MAX)) - 5.0F;
				voltages[i][3]=(10.0F * ((float)(GetTickCount()%2048))/2048) - 5.0F;
			}
		}
	}

	//interleave data as needed
	if(numChannels == 1)
	{
		for(i=1023;i>=0;i--)
		{
			voltages[i*4][0]=voltages[i][0];
			stateIOout[i*4]=stateIOout[i];
			stateIOout[(i*4)+1]=stateIOout[i];
			stateIOout[(i*4)+2]=stateIOout[i];
			stateIOout[(i*4)+3]=stateIOout[i];
		}
		for(i=0;i<1024;i++)
		{
			voltages[(i*4)+1][0]=voltages[i][1];
			voltages[(i*4)+2][0]=voltages[i][2];
			voltages[(i*4)+3][0]=voltages[i][3];
			voltages[i][1]=9999.0F;
			voltages[i][2]=9999.0F;
			voltages[i][3]=9999.0F;
		}
	}
	if(numChannels == 2)
	{
		for(i=1023;i>=0;i--)
		{
			voltages[i*2][0]=voltages[i][0];
			voltages[i*2][1]=voltages[i][1];
			stateIOout[i*2]=stateIOout[i];
			stateIOout[(i*2)+1]=stateIOout[i];
		}
		for(i=0;i<1024;i++)
		{
			voltages[(i*2)+1][0]=voltages[i][2];
			voltages[(i*2)+1][1]=voltages[i][3];
			voltages[i][2]=9999.0F;
			voltages[i][3]=9999.0F;
		}
	}

	//delete extra data
	i=((numScansLJ*4)/numChannels) - numScans;
	for(i;i>0;i--)
	{
		if(numChannels == 1)
		{
			voltages[(numScansLJ*4)-i][0]=9999.0F;
			stateIOout[(numScansLJ*4)-i]=9999;
		}
		if(numChannels == 2)
		{
			voltages[(numScansLJ*2)-i][0]=9999.0F;
			voltages[(numScansLJ*2)-i][1]=9999.0F;
			stateIOout[(numScansLJ*2)-i]=9999;
		}
		if(numChannels == 4)
		{
			voltages[numScansLJ-i][0]=9999.0F;
			voltages[numScansLJ-i][1]=9999.0F;
			voltages[numScansLJ-i][2]=9999.0F;
			voltages[numScansLJ-i][3]=9999.0F;
			stateIOout[numScansLJ-i]=9999;
		}
	}

	if(!demo)
	{
		errorcode = CloseAll(localID);
	}

	return errorcode;
}



//======================================================================
// AIStreamStart: Starts a hardware timed continuous acquisition where data
//				  is sampled and stored in the LabJack RAM buffer, and
//				  simultaneously transferred out of the RAM buffer to the
//				  PC application.  A call to this function should be
//				  followed by periodic calls to AIStreamRead, and eventually
//				  a call to AIStreamClear.
//
//	Returns:	LabJack errorcodes or 0 for no error (I32).
//	Inputs:		*idnum		-Local ID, Serial Number, or -1 for first
//							 found (I32).
//				demo		-Send 0 for normal operation, >0 for demo
//							 mode (I32).  Demo mode allows this function
//							 to be called without a LabJack, and does little
//							 but simulate execution time.
//				stateIOin	-Output states for IO0-IO3 (I32).
//				updateIO	-If >0, state values will be written.  Otherwise,
//							 just reads are performed (I32).
//				ledOn		-If >0, the LabJack LED is turned on (I32).
//				numChannels -Number of channels.  1, 2, or 4 (I32).  If
//							 readCount is >0, numChannels should be 4.
//				*channels	-Pointer to an array of channel commands with at
//							 least numChannels elements (I32).  Each channel
//							 command is 0-7 for SE or 8-11 for Diff.
//				*gains		-Pointer to an array of gain commands with at
//							 least numChannels elements (I32).  Gain commands
//							 are 0=1,1=2,...,7=20.  Gain only available for
//							 differential channels.
//				*scanRate	-Scans acquired per second (SGL).  A scan is a
//							 reading from every channel (1,2, or 4).  The
//							 sample rate (scanRate*numChannels) must
//							 be 200-1200.
//				disableCal	-If >0, voltages returned will be raw readings
//							 that are not corrected using calibration
//							 constants (I32).
//				transferMode	-0=auto,1=normal,2=turbo (I32)
//				readCount	-If >0, the counter read is returned instead of
//							 the 2nd, 3rd, and 4th channel (I32).  2nd
//							 channel is bits 0-11, 3rd channel is bits
//							 12-23, and 4th channel is bits 24-31.
//							 Only works with firmware V1.03 or higher.
//	Outputs:	*idnum		-Returns the Local ID or -1 if no LabJack is
//							 found (I32).
//				*scanRate	-Returns the actual scan rate, which due to clock
//							 resolution is not always exactly the same as the
//							 desired scan rate (SGL).
//----------------------------------------------------------------------
long AIStreamStart(long *idnum,
				   long demo,
				   long stateIOin,
				   long updateIO,
				   long ledOn,
				   long numChannels,
				   long *channels,
				   long *gains,
				   float *scanRate,
				   long disableCal,
				   long reserved1,
				   long readCount)
{
	long errorcode=NO_ERROR_LJ;
//	long i;
	long sampleInt;
	long scanMult=1;
	long localID;
	long result;
	long turbo = FALSE;
	long junk1=0,junk2=0,junk3=0,junk4=0;
	unsigned char sendBuff5;
	unsigned char sendBuffer[9]={0,0,0,0,0,0,0,0,0};
	long calData[20]={0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0};
	long ch1num,ch2num,ch3num,ch4num,ch1gain,ch2gain,ch3gain,ch4gain;
	float firmwareVersion;
	HANDLE hMutex;
	long serialnum=0;

	//junk variables for warm-up call to AISample
	long sio=0,chns[4]={0,0,0,0},gns[4]={0,0,0,0},ovlt=0;
	float vlts[4]={0,0,0,0};

	//Make sure inputs are valid
	if (!((numChannels==1)||(numChannels==2)||(numChannels==4)))
	{
		errorcode=ILLEGAL_NUMBER_OF_CHANNELS_LJ;
		return errorcode;
	}
	if ((readCount>0)&&(numChannels!=4))
	{
		errorcode=ILLEGAL_NUMBER_OF_CHANNELS_LJ;
		return errorcode;
	}
	if (((*scanRate * numChannels)<200) || ((*scanRate * numChannels)>1200))
	{
		errorcode=ILLEGAL_SCAN_RATE_LJ;
		return errorcode;
	}
	switch(reserved1)
	{
		case 0:		turbo = TRUE;		
					break;
		case 1:		//turbo = FALSE;
					return ILLEGAL_INPUT_ERROR_LJ;
					break;
		case 2:		turbo = TRUE;
					break;
		default:	return ILLEGAL_INPUT_ERROR_LJ;
	}


	//Claim device code removed here.

	sampleInt = RoundFL(6000000.0F/(*scanRate * (float)numChannels * (float)scanMult));
	*scanRate = 6000000.0F/((float)(sampleInt * numChannels * scanMult));

	if(!demo)
	{

		if(readCount)
		{
			//Check that firmware is V1.03 or newer
			firmwareVersion = GetFirmwareVersion(idnum);
			if(firmwareVersion > 0.1)
			{
				if(GetFirmwareVersion(idnum) < 1.0290)
				{
					errorcode=WRONG_FIRMWARE_VERSION_LJ;
					return errorcode;
				}
			}
			else
			{
				//GetFirmwareVersion returned an error
				errorcode = *idnum - GETFIRMWAREVERSION_ERROR_OFFSET_LJ;
				return errorcode;
			}
		}
		else
		{
			//Make a warm-up call to AISample to flush and init the readBuffer.
			errorcode = AISample(idnum,0,&sio,0,ledOn,4,chns,gns,0,&ovlt,vlts);
			if(errorcode)
			{
				return errorcode;
			}
		}

		Sleep(1);

		//Open the specified or first found LabJack
		localID = OpenLabJack(&errorcode,LABJACK_VENDOR_ID,LABJACK_U12_PRODUCT_ID,idnum,&serialnum,calData);
		if(errorcode)
		{
			*idnum=-1;
			return errorcode;
		}
	}
	else
	{
		if((*idnum>=0)&&(*idnum<=255))
		{
			localID = *idnum;
		}
		else
		{
			localID = (long)(255.0F * (((float)rand())/((float)RAND_MAX)));
			*idnum = localID;
		}
	}

	//Build sendBuff5
	sendBuff5 = 0;
	if(turbo)
	{
		//set bit 7
		sendBuff5 = BitSet(sendBuff5,7);
	}
	if(readCount)
	{
		//set bit 6
		sendBuff5 = BitSet(sendBuff5,6);
	}
	if(ledOn)
	{
		//set bit 0 to turn the LED on
		sendBuff5 = BitSet(sendBuff5,0);
	}
	if(updateIO)
	{
		//set bit 1 to indicate update IO
		sendBuff5 = BitSet(sendBuff5,1);
	}

	//Fill sendBuffer with the proper values.
	ch1num=channels[0];
	ch2num=channels[0];
	ch3num=channels[0];
	ch4num=channels[0];
	ch1gain=gains[0];
	ch2gain=gains[0];
	ch3gain=gains[0];
	ch4gain=gains[0];
	if(numChannels==2)
	{
		ch2num=channels[1];
		ch4num=channels[1];
		ch2gain=gains[1];
		ch4gain=gains[1];
	}
	if((numChannels==4)&&(readCount<1))
	{
		ch2num=channels[1];
		ch3num=channels[2];
		ch4num=channels[3];
		ch2gain=gains[1];
		ch3gain=gains[2];
		ch4gain=gains[3];
	}
	errorcode = BuildAICommand(9,sendBuff5,(unsigned char)(sampleInt/256),(unsigned char)(sampleInt%256),stateIOin,ch1num,ch2num,ch3num,ch4num,ch1gain,ch2gain,ch3gain,ch4gain,sendBuffer);
	if(errorcode)
	{
		if(!demo)
		{
			CloseAll(localID);
		}
		return errorcode;
	}

	//Write command to LabJack to start continuous acquisition
	if(!demo)
	{
		errorcode=WriteLabJack(localID,sendBuffer);
		if(errorcode)
		{
			CloseAll(localID);
			return errorcode;
		}
	}

	//Load the super-global streamInfo structure
	streamInfo.localID = localID;
	streamInfo.errorcode = 0;
	streamInfo.ch1num = ch1num;
	streamInfo.ch2num = ch2num;
	streamInfo.ch3num = ch3num;
	streamInfo.ch4num = ch4num;
	streamInfo.ch1gain = ch1gain;
	streamInfo.ch2gain = ch2gain;
	streamInfo.ch3gain = ch3gain;
	streamInfo.ch4gain = ch4gain;
	streamInfo.demo = demo;
	streamInfo.demoTick = GetTickCount();
	streamInfo.scanCount = 0;
	streamInfo.disableCal = disableCal;
	streamInfo.numChannels = numChannels;
	streamInfo.scanMult = scanMult;
	streamInfo.scanRate = *scanRate;
	streamInfo.turbo = turbo;
	streamInfo.numScansBuff=0;
	streamInfo.previousCount=6;
	streamInfo.readCount=readCount;
	
	//Release device code removed here
	

	if(!demo)
	{
		errorcode = CloseAll(localID);
	}
	
	
	return errorcode;
}


//======================================================================
// AIStreamRead: Waits for a specified number of scans to be available and
//				 reads them.  AIStreamStart should be called before this
//				 function and AIStreamClear should be called when finished.
//
//	Returns:	LabJack errorcodes or 0 for no error (I32).
//	Inputs:		localID		-Send the local ID from AIStreamStart (I32).
//				numScans	-Function will wait until this number of scans is
//							 available (I32).  Minimum is 1.  Maximum
//							 numSamples is 4096 where numSamples is
//							 equal to numScans * numChannels.  Internally,
//							 this function gets data from the LabJack in
//							 blocks of 64 samples, so it is recommended that
//							 numSamples be at least 64.
//				timeout		-Function timeout value in seconds (I32).
//				*voltages	-Voltage readings buffer.  Send a 4096 by 4
//							 element array of zeros (SGL).
//				*stateIOout	-IO state readings buffer.  Send a 4096 element
//							 array of zeros (I32).
//	Outputs:	*voltages	-Voltage readings are returned in this 4096 by 4
//							 array (SGL).  Unused locations are filled
//							 with 9999s.
//				*stateIOout	-The states of all 4 IO are returned in this
//							 array (I32).  Unused locations are filled
//							 with 9999s.
//				*pcScanBacklog	-Reserved for future use (I32).
//				*ljScanBacklog	-Returns the scan backlog of the LabJack RAM
//								 buffer (I32).
//				*overVoltage	-If >0, an overvoltage has been detected on
//								 at least one sample of at least one of the
//								 analog inputs (I32).
//----------------------------------------------------------------------
long AIStreamRead(long localID,
				  long numScans,
				  long timeout,
				  float (*voltages)[4],
				  long *stateIOout,
				  long *reserved,
				  long *ljScanBacklog,
				  long *overVoltage)
{
	long errorcode = NO_ERROR_LJ;
	long i,j,k,l;
	long result;
	unsigned long currentTime;
	long numScansLJ;
	unsigned long initialTick;
	float v1=0,v2=0,v3=0,v4=0;
	long sio=0,ov=0;
	long bocsError=0,backlog=0;
	long currentCount=6;
	unsigned char junk=0;
	unsigned char sendBuffer[9]={0,0,0,0,0,0,0,0,0};
	unsigned char readBuffer[9]={0,0,0,0,0,0,0,0,0};
	unsigned char featureBuff[129]={0};
	long calData[20]={0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0};
	float tempBuff[4096][7]={0}; //V1,(V2),(V3),(V4),stateIO,overvoltage,ljScanBacklog
	HANDLE hMutex;
	long junkid;
	long serialnum=0;

	initialTick = GetTickCount();

	if(timeout<1)
	{
		errorcode=ILLEGAL_INPUT_ERROR_LJ;
		return errorcode;
	}

	if((localID<0) || (localID>255))
	{
		errorcode=INVALID_ID_LJ;
		return errorcode;
	}

	//Make sure arrays are filled with zeros
	for(i=0;i<4096;i++)
	{
		if(stateIOout[i] != 0)
		{
			return ARRAY_SIZE_OR_VALUE_ERROR_LJ;
		}
		stateIOout[i] = 9999;
	}
	for(i=0;i<4096;i++)
	{
		for(j=0;j<4;j++)
		{
			if(voltages[i][j] != 0)
			{
				return ARRAY_SIZE_OR_VALUE_ERROR_LJ;
			}
			voltages[i][j] = 9999.0F;
			tempBuff[i][j] = 9999.0F;
		}
	}

	//Claim device code removed here.
		
	//If we get here we successfully claimed streamInfo and localID matched

	//Make sure numScans is valid.
	if ((numScans<1) || ((numScans*streamInfo.numChannels)>4096))
	{
		errorcode=ILLEGAL_NUM_SCANS_LJ;
		return errorcode;
	}

	//Determine if and how many scans we need from the LabJack
	if((numScans - streamInfo.numScansBuff) <= 0)
	{
		//There are enough scans already in the buffer
		*overVoltage=0;
		//Read data from streamBuff
		for(i=0;i<numScans;i++)
		{
			voltages[i][0]=streamInfo.streamBuff[i][0];
			voltages[i][1]=streamInfo.streamBuff[i][1];
			voltages[i][2]=streamInfo.streamBuff[i][2];
			voltages[i][3]=streamInfo.streamBuff[i][3];
			stateIOout[i]=(long)streamInfo.streamBuff[i][4];
			if(streamInfo.streamBuff[i][5]) *overVoltage += 1;
			*ljScanBacklog=(long)streamInfo.streamBuff[i][6];
		}
		//Shift any leftover data to the beginning of streamBuff
		streamInfo.numScansBuff = streamInfo.numScansBuff - numScans;
		for(i=0;i<streamInfo.numScansBuff;i++)
		{
			streamInfo.streamBuff[i][0]=streamInfo.streamBuff[numScans+i][0];
			streamInfo.streamBuff[i][1]=streamInfo.streamBuff[numScans+i][1];
			streamInfo.streamBuff[i][2]=streamInfo.streamBuff[numScans+i][2];
			streamInfo.streamBuff[i][3]=streamInfo.streamBuff[numScans+i][3];
			streamInfo.streamBuff[i][4]=streamInfo.streamBuff[numScans+i][4];
			streamInfo.streamBuff[i][5]=streamInfo.streamBuff[numScans+i][5];
			streamInfo.streamBuff[i][6]=streamInfo.streamBuff[numScans+i][6];
		}
	}
	else
	{
		//We need to retrieve scans from the LabJack

		//Determine how many LabJack 4-channel scans are required
		numScansLJ = ((numScans-streamInfo.numScansBuff)*streamInfo.numChannels)/4;
		if((((numScans-streamInfo.numScansBuff)*streamInfo.numChannels)%4) != 0)
		{
			numScansLJ += 1;
		}
		//Force numScansLJ to be a multiple of 16
		if((numScansLJ % 16) != 0)
		{
			numScansLJ += (16 - (numScansLJ % 16));
		}

		//Need to build sendBuffer for ParseAIResponse
		BuildAICommand (9,0,0,0,0,streamInfo.ch1num,streamInfo.ch2num,streamInfo.ch3num,streamInfo.ch4num,streamInfo.ch1gain,streamInfo.ch2gain,streamInfo.ch3gain,streamInfo.ch4gain,sendBuffer);

		if(streamInfo.demo)
		{
			for(i=0;i<numScansLJ;i++)
			{
				if(streamInfo.numChannels == 1)
				{
					tempBuff[(i*4)][0] = (float)((unsigned int)(streamInfo.scanCount+0));
					tempBuff[(i*4)+1][0] = (float)((unsigned int)(streamInfo.scanCount+1));
					tempBuff[(i*4)+2][0] = (float)((unsigned int)(streamInfo.scanCount+2));
					tempBuff[(i*4)+3][0] = (float)((unsigned int)(streamInfo.scanCount+3));
				}
				if(streamInfo.numChannels == 2)
				{
					tempBuff[(i*2)][0] = (float)((unsigned int)(streamInfo.scanCount+0));
					tempBuff[(i*2)+1][0] = (float)((unsigned int)(streamInfo.scanCount+1));
					tempBuff[(i*2)][1] = (10.0F * ((float)rand())/((float)RAND_MAX)) - 5.0F;
					tempBuff[(i*2)+1][1] = (10.0F * ((float)rand())/((float)RAND_MAX)) - 5.0F;
				}
				if(streamInfo.numChannels == 4)
				{
					tempBuff[i][0] = (float)((unsigned int)(streamInfo.scanCount));
					if(streamInfo.readCount)
					{
						currentTime = GetTickCount();
						tempBuff[i][1] = (float)(currentTime%4096);
						tempBuff[i][2] = (float)((currentTime%16777216)/4096);
						tempBuff[i][3] = (float)(currentTime/16777216);
					}
					else
					{
						tempBuff[i][1] = -2.5F;
						tempBuff[i][2] = (10.0F * ((float)rand())/((float)RAND_MAX)) - 5.0F;
						tempBuff[i][3] = (10.0F * ((float)(GetTickCount()%2048))/2048) - 5.0F;
					}
				}
				streamInfo.scanCount += 4;
			}  //end for numScansLJ

			//Let timer roll-over if within 2 seconds
			if(GetTickCount() > 4294965295U) Sleep(2050);
			//Check for timer roll-over.
			if(GetTickCount() < initialTick) initialTick = GetTickCount();
			//Check for timer roll-over.
			if(GetTickCount() < streamInfo.demoTick) streamInfo.demoTick = GetTickCount();

			//Wait for timeout or the proper time delay for this number of scans
			while(((GetTickCount()-initialTick)<((unsigned long)(timeout*1000))) && ((GetTickCount()-streamInfo.demoTick)<((unsigned long)(1000*4*((float)numScansLJ)/(streamInfo.scanRate*streamInfo.numChannels)))));
			if((GetTickCount()-initialTick) >= ((unsigned long)(timeout*1000)))
			{
				//timeout error
				AIStreamClear(localID);
				return STREAM_READ_TIMEOUT_LJ;
			}
			else  //proper time has elapsed without timeout
			{
				//maximum data transfer is 4x the scan rate
				while((GetTickCount()-initialTick)<((unsigned long)(250*4*((float)numScansLJ)/(streamInfo.scanRate*streamInfo.numChannels))));
				streamInfo.demoTick += ((long)(1000*4*((float)numScansLJ)/(streamInfo.scanRate*streamInfo.numChannels)));
				*ljScanBacklog = numScansLJ * ((GetTickCount()-streamInfo.demoTick)/((long)(1000*4*((float)numScans)/(streamInfo.scanRate*streamInfo.numChannels))));
				if(((*ljScanBacklog * streamInfo.numChannels)/4) >= 1024)
				{
					//LabJack buffer overflow
					AIStreamClear(localID);
					return LJ_BUFF_OVERFLOW_LJ;
				}
			}
		}
		else  //not demo
		{
			//Open the LabJack
			junkid = localID;
			OpenLabJack(&errorcode,LABJACK_VENDOR_ID,LABJACK_U12_PRODUCT_ID,&junkid,&serialnum,calData);
			if(errorcode)
			{
				return errorcode;
			}

			//Read the data
			for(i=0;i<numScansLJ/16;i++)
			{
				//Turbo: Use control transfers (feature reports).
				//Read the feature report (reads 16 scans per call)
				errorcode = ReadLabJack(localID,READ_TIMEOUT_MS,1,featureBuff);
				if(!errorcode)
				{
					for(k=0;k<16;k++)
					{
						//Put each scan in readBuffer
						readBuffer[0]=0;
						for(l=0;l<8;l++)
						{
							readBuffer[l+1]=featureBuff[(k*8)+l+1];
						}
						//Parse each scan
						errorcode = ParseAIResponse  (	sendBuffer,
														readBuffer,
														streamInfo.disableCal,
														calData,
														&sio,
														&ov,
														&v1,
														&v2,
														&v3,
														&v4,
														&junk,
														&bocsError,
														&backlog,
														&currentCount,
														streamInfo.readCount);


						if(streamInfo.numChannels == 1)
						{
							tempBuff[((i*16)+k)*4][0] = v1;
							tempBuff[(((i*16)+k)*4)+1][0] = v2;
							tempBuff[(((i*16)+k)*4)+2][0] = v3;
							tempBuff[(((i*16)+k)*4)+3][0] = v4;
							for(j=0;j<4;j++)
							{
								tempBuff[(((i*16)+k)*4)+j][4]= (float)sio;
								tempBuff[(((i*16)+k)*4)+j][5]= (float)ov;
								tempBuff[(((i*16)+k)*4)+j][6]= (float)((backlog * 4)/streamInfo.numChannels);
							}
						}
						if(streamInfo.numChannels == 2)
						{
							tempBuff[((i*16)+k)*2][0] = v1;
							tempBuff[(((i*16)+k)*2)+1][0] = v3;
							tempBuff[((i*16)+k)*2][1] = v2;
							tempBuff[(((i*16)+k)*2)+1][1] = v4;
							for(j=0;j<2;j++)
							{
								tempBuff[(((i*16)+k)*2)+j][4]= (float)sio;
								tempBuff[(((i*16)+k)*2)+j][5]= (float)ov;
								tempBuff[(((i*16)+k)*2)+j][6]= (float)((backlog * 4)/streamInfo.numChannels);
							}
						}
						if(streamInfo.numChannels == 4)
						{
							tempBuff[(i*16)+k][0] = v1;
							tempBuff[(i*16)+k][1] = v2;
							tempBuff[(i*16)+k][2] = v3;
							tempBuff[(i*16)+k][3] = v4;
							tempBuff[(i*16)+k][4] = (float)sio;
							tempBuff[(i*16)+k][5] = (float)ov;
							tempBuff[(i*16)+k][6] = (float)((backlog * 4)/streamInfo.numChannels);
						}

						if(currentCount==0)
						{
							if(streamInfo.previousCount != 6)
							{
								errorcode = AI_SEQUENCE_ERROR_LJ;
							}
						}
						else
						{
							if(currentCount != (streamInfo.previousCount+1))
							{
								errorcode = AI_SEQUENCE_ERROR_LJ;
							}
						}					

						if(bocsError)
						{
							if(backlog == 0)
							{
								errorcode = RAM_CS_ERROR_LJ;
							}
							else
							{
								//LabJack buffer overflow.
								errorcode = LJ_BUFF_OVERFLOW_LJ;
							}
						}

						if(errorcode)
						{
							CloseAll(localID);
							AIStreamClear(localID);
							return errorcode;
						}
						streamInfo.previousCount = currentCount;
						streamInfo.scanCount += 4;
					}  //for 16 scans (1 feature report)
				}  //end if not errorcode
				else
				{
					CloseAll(localID);
					return errorcode;
				}

				Sleep(1);
				//Check for timer roll-over.
				if(GetTickCount() > 4294967245U) Sleep(60);
				if(GetTickCount() < initialTick) initialTick = GetTickCount();
				//Check for timeout
				if((GetTickCount()-initialTick)>((unsigned long)(timeout*1000)))
				{
					CloseAll(localID);
					AIStreamClear(localID);
					return STREAM_READ_TIMEOUT_LJ;
				}
			}  //end for each 16-scan feature report

			//Close the LabJack
			errorcode = CloseAll(localID);
			if(errorcode)
			{
				return errorcode;
			}

		}  //end else not demo

		//We now have the required scans in tempBuff.  Take what we
		//need and put the rest in streamBuff for next time.

		*overVoltage=0;
		//Read data from streamBuff first
		for(i=0;i<streamInfo.numScansBuff;i++)
		{
			voltages[i][0]=streamInfo.streamBuff[i][0];
			voltages[i][1]=streamInfo.streamBuff[i][1];
			voltages[i][2]=streamInfo.streamBuff[i][2];
			voltages[i][3]=streamInfo.streamBuff[i][3];
			stateIOout[i]=(long)streamInfo.streamBuff[i][4];
			if(streamInfo.streamBuff[i][5]) *overVoltage += 1;
			*ljScanBacklog=(long)streamInfo.streamBuff[i][6];
		}
		//Take the amount of data we need from tempBuff
		j = numScans-streamInfo.numScansBuff;
		for(i=0;i<j;i++)
		{
			voltages[i+streamInfo.numScansBuff][0]=tempBuff[i][0];
			voltages[i+streamInfo.numScansBuff][1]=tempBuff[i][1];
			voltages[i+streamInfo.numScansBuff][2]=tempBuff[i][2];
			voltages[i+streamInfo.numScansBuff][3]=tempBuff[i][3];
			stateIOout[i+streamInfo.numScansBuff]=(long)tempBuff[i][4];
			if(tempBuff[i][5]) *overVoltage += 1;
			*ljScanBacklog=(long)tempBuff[i][6];
		}
		//Put any leftover data in streamBuff
		streamInfo.numScansBuff = ((numScansLJ*4)/streamInfo.numChannels) - j;
		for(i=0;i<streamInfo.numScansBuff;i++)
		{
			streamInfo.streamBuff[i][0]=tempBuff[j+i][0];
			streamInfo.streamBuff[i][1]=tempBuff[j+i][1];
			streamInfo.streamBuff[i][2]=tempBuff[j+i][2];
			streamInfo.streamBuff[i][3]=tempBuff[j+i][3];
			streamInfo.streamBuff[i][4]=tempBuff[j+i][4];
			streamInfo.streamBuff[i][5]=tempBuff[j+i][5];
			streamInfo.streamBuff[i][6]=tempBuff[j+i][6];
		}
	}  //end else retrieve scans from LabJack

	//Release device code removed here

	return errorcode;

}


//======================================================================
// AIStreamClear:  This function stops the continuous acquisition.  It
//				   should be called after AIStreamStart and after any
//				   calls to AIStreamRead.
//
//	Returns:	LabJack errorcodes or 0 for no error (I32).
//	Inputs:		localID		-Send the local ID from AIStreamStart/Read (I32).
//	Outputs:	none
//----------------------------------------------------------------------
long AIStreamClear(long localID)
{
	long errorcode=NO_ERROR_LJ;
	long result;
	long numberOfBytesRead=0;
	unsigned char sendBuffer[9]={0,0,0,0,0,0,80,0,16};  //ReadMem address 16
	unsigned char readBuffer[9]={0,0,0,0,0,0,0,0,0};
	HANDLE hMutex;
	long junk0=0,junk1=0,junk2=0,junk3=0;


	if((localID<0) || (localID>255))
	{
		errorcode=INVALID_ID_LJ;
		return errorcode;
	}
	
	//TODO
	//Claim device code removed here.  Following is the code that is executed
	//if the device is claimed.
			streamInfo.localID = -1; //release streamInfo
			//Send any command to stop the stream on the LabJack.
			if(!streamInfo.demo)
			{
				errorcode = ReadMem(&localID,16,&junk3,&junk2,&junk1,&junk0);
				if(errorcode)
				{
					return errorcode;
				}
			}	
	
	return errorcode;
}



//======================================================================
// ListAll: Searches the USB for all LabJacks.
//
//	Returns:	LabJack errorcodes or 0 for no error (I32).
//	Inputs:		*productIDList	-Send a 127 element array of zeros (I32).
//				*serialnumList	-Send a 127 element array of zeros (I32).
//				*localIDList	-Send a 127 element array of zeros (I32).
//				*powerList		-Send a 127 element array of zeros (I32).
//				*calMatrix		-Send a 127 by 20 element array of
//								 zeros (I32).
//	Outputs:	*productIDList	-Returns the product ID for each LabJack on
//								 the USB (I32).  Unused elements filled
//								 with 9999s.
//				*serialnumList	-Returns the serial number for each LabJack
//								 on the USB (I32).  Unused elements filled
//								 with 9999s.
//				*localIDList	-Returns the local ID for each LabJack on
//								 the USB (I32).  Unused elements filled
//								 with 9999s.
//				*powerList		-Returns the power allowance for each LabJack
//								 on the USB (I32).  Unused elements filled
//								 with 9999s.
//				*calMatrix		-Returns the cal constants for each LabJack
//								 on the USB (I32).  Unused elements filled
//								 with 9999s.
//				*numberFound	-Number of LabJacks found on the USB (I32).
//				*fcddMaxSize	-Max size of fcdd (I32).
//				*hvcMaxSize		-Max size of hvc (I32).
//----------------------------------------------------------------------
long ListAll(long *productIDList,
			 long *serialnumList,
			 long *localIDList,
			 long *powerList,
			 long (*calMatrix)[20],
			 long *numberFound,
			 long *fcddMaxSize,
			 long *hvcMaxSize)
{
	//double		temp;
	long		idnum = 0;
	long		serialnum = 0;
	long		calData[20] = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0};
	long		productID = 0;
	long		power = 0;
	long		errorcode = 0; 
	long		data[4];
	long		result = 0;
	long		fd;
    
	unsigned char sendBuffer[9] = {0, 1, 0, 0, 0, 0, 83, 0, 0};
    	*numberFound = 0;
	long i;
    	long j;
    	long k;
    	long l;
        
    //Make sure all arrays have 127 zeros.
	for(i=0;i<127;i++)
	{
		if(productIDList[i] != 0)
		{
			return ARRAY_SIZE_OR_VALUE_ERROR_LJ;
		}
		productIDList[i] = 9999;
		if(serialnumList[i] != 0)
		{
			return ARRAY_SIZE_OR_VALUE_ERROR_LJ;
		}
		serialnumList[i] = 9999;
		if(localIDList[i] != 0)
		{
			return ARRAY_SIZE_OR_VALUE_ERROR_LJ;
		}
		localIDList[i] = 9999;
		if(powerList[i] != 0)
		{
			return ARRAY_SIZE_OR_VALUE_ERROR_LJ;
		}
		powerList[i] = 9999;
		for(j=0;j<20;j++)
		{
			if(calMatrix[i][j] != 0)
			{
				return ARRAY_SIZE_OR_VALUE_ERROR_LJ;
			}
			calMatrix[i][j] = 9999;
		}
	}

    	for(i=0;i<MAX_LABJACKS;i++)
    	{
	        idnum = i;
        
        	fd = open(labjack[i], O_RDWR);
		
		if(fd != -1)
		{
			//WriteLabJack(fd, sendBuffer);
            		write(fd, sendBuffer + 1, 8);
			read(fd, sendBuffer + 1, 8);
			Sleep(2);
			
			result = ReadMemNoOpen(&fd,0x000,&data[0], &data[1], &data[2], &data[3]);
            		if(result != 0) 
			{
            			errorcode = result;
                		close(fd);
                		return errorcode;
            		}                
			serialnum=data[3]+data[2]*256+data[1]*65536+data[0]*16777216;
			
			result = ReadMemNoOpen(&fd,0x008,&data[0], &data[1], &data[2], &data[3]);
        	
			if(result != 0) {
        			errorcode = result;
                		close(fd);
                		return errorcode;
        		}
			idnum=data[3];
			
			if((labjackTrack[i].found == TRUE) && (labjackTrack[i].locid == idnum) && 
                    (labjackInfo[idnum].serialnum == serialnum))
            		{}
            		else
            		{   
				for(j=0;j<8;j++)
				{
					result = ReadMemNoOpen(&fd,0x100+(0x010*j),&data[0], &data[1], &data[2], &data[3]);
					if(result != 0) {
                    				errorcode = result;
                    				close(fd);
                    				return errorcode;
                    			}
					data[1]=twoscomplement(data[1]);
					data[3]=twoscomplement(data[3]);
					labjackInfo[idnum].caliData[j]=data[1];
					labjackInfo[idnum].caliData[j+8]=data[3];
				}	
				
				for(k=0;k<4;k++)
				{
					result = ReadMemNoOpen(&fd,0x180+(0x010*k),&data[0], &data[1], &data[2], &data[3]);
                    			if(result != 0) {
                    				errorcode = result;
                    				close(fd);
                    				return errorcode;
                    			}
                    
					data[1]=twoscomplement(data[1]);
					labjackInfo[idnum].caliData[16+k]=data[1];
				}
			}
			close(fd);
	        	
			productIDList[*numberFound] = LABJACK_U12_PRODUCT_ID;			                                                                                                        
            		localIDList[*numberFound] = idnum;
            		labjackTrack[i].locid = idnum;            
            		serialnumList[*numberFound] = serialnum;
            		labjackInfo[idnum].serialnum = serialnum;
            		labjackTrack[i].found = TRUE;
            		for(l = 0; l < 20; l++)
            		{
            			calMatrix[*numberFound][l] = labjackInfo[idnum].caliData[l];
        		}		
			*numberFound = *numberFound + 1;
			idnum = 0;
			serialnum = 0;
        	}
        	else
        	{
	        	labjackTrack[i].found = FALSE;
        	}
    	}

  	return errorcode;
	
}



//======================================================================
//OpenLabJack:	Returns an index (localID 0-255) to a LABJACK_INFO structure
//				in the labjackInfo array containing the mutex,
//				device handle, read handle, and read event handle.
//				If idnum is <0, it opens the first LabJack found, otherwise
//				it opens the first LabJack it finds with a matching localID
//				or serial #.  Local ID is also returned by *idnum.
//				Errors returned in the errorcode parameter (0 for no error).
//----------------------------------------------------------------------
long OpenLabJack (long *errorcode,
		  unsigned int vendorID,
		  unsigned int productID,
		  long *idnum,
		  long *serialnum,
		  long *calData)
{
	long		fd;
	unsigned char	sendBuffer[9] = {0, 1, 0, 0, 0, 0, 83, 0, 0};
	long		localID = -1;
	long		serial = 0;
	long		data[4] = {0, 0, 0, 0};
	long		result = 0;
	
	*errorcode = 0;
	long i;
    	long j;
    	long k;

	for(i = 0; i < MAX_LABJACKS; i++)
	{
		fd = open(labjack[i], O_RDWR);
        
		if(fd != -1)
		{
			/*
			if((streamInfo.localID != -1) && (labjackTrack[i].found == TRUE) && (labjackTrack[i].locid == *idnum) && (streamInfo.localID == *idnum))
			{
			 
				*serialnum = labjackInfo[*idnum].serialnum;
				for(j=0; j<20; j++)
                    			calData[j]=labjackInfo[*idnum].caliData[j];
				
				return *idnum;
			}
			*/
				
			write(fd, sendBuffer + 1, 8);
			read(fd, sendBuffer + 1, 8);
			Sleep(2);
            
            		if(*idnum < MAX_DEVICES_LJ)
            		{
                		//getting local id
			    	result = ReadMemNoOpen(&fd,0x008,&data[0], &data[1], &data[2], &data[3]);
			    	if(result != 0)
			    	{
        				*errorcode = result;
                			close(fd);
				    	localID = -1;
				    	return localID;
			    	}
			    	localID=data[3];
            		}
            		else
            		{
                		//getting serial number
			    	result = ReadMemNoOpen(&fd,0x000,&data[0], &data[1], &data[2], &data[3]);
			    	if(result != 0)
			    	{
                			*errorcode = result;
                			close(fd);
				    	localID = -1;
				    	return localID;
			    	}                
			    	serial=data[3]+data[2]*256+data[1]*65536+data[0]*16777216;
            		}
            
			if((localID == *idnum) || ((serial == *idnum)&&(*idnum >= MAX_DEVICES_LJ)) || (*idnum == -1))
			{

                		if(*idnum >= MAX_DEVICES_LJ) 
		        	{
					//getting local id
		    	    		result = ReadMemNoOpen(&fd,0x008,&data[0], &data[1], &data[2], &data[3]);
			        	if(result != 0)
			        	{
        			    		*errorcode = result;
                	    			close(fd);
				        	localID = -1;
				        	return localID;
			        	}
			        	localID=data[3];
                		}
                		else
                		{
                			//getting serial number
			   		result = ReadMemNoOpen(&fd,0x000,&data[0], &data[1], &data[2], &data[3]);
			    		if(result != 0)
			    		{
                				*errorcode = result;
                				close(fd);
				    		localID = -1;
				    		return localID;
			    		}
                            
				    	serial=data[3]+data[2]*256+data[1]*65536+data[0]*16777216;
            			}
                        
            			if((labjackTrack[i].found == TRUE) && (labjackTrack[i].locid == localID) && 
                    			(labjackInfo[localID].serialnum == serial))
            			{
                			for(j=0; j<20; j++)
                    				calData[j]=labjackInfo[localID].caliData[j];              
            			}
            			else
            			{
                			//Getting calibration data
                			for(j=0;j<8;j++)
                			{
						result = ReadMemNoOpen(&fd,0x100+(0x010*j),&data[0], &data[1], &data[2], &data[3]);
                    
						if(result != 0)
						{
                       					*errorcode = result;
                        				close(fd);
							localID = -1;
							return localID;
						}
                    
						data[1]=twoscomplement(data[1]);
						data[3]=twoscomplement(data[3]);
						calData[j]=data[1];
						calData[j+8]=data[3];
                    				labjackInfo[localID].caliData[j] = data[1];
                    				labjackInfo[localID].caliData[j+8] = data[3];
					}
				
					for(k=0;k<4;k++)
					{
						result = ReadMemNoOpen(&fd,0x180+(0x010*k),&data[0], &data[1], &data[2], &data[3]);
						if(result != 0)
						{
                					*errorcode = result;
                					close(fd);
							localID = -1;
							return localID;
						}
                    
						data[1]=twoscomplement(data[1]);
						calData[16+k]=data[1];
                    				labjackInfo[localID].caliData[16+k] = data[1];
					}
            			}
                		labjackTrack[i].locid = localID;
				*idnum = localID;
				*serialnum = serial;
                		labjackInfo[localID].serialnum = serial;
				labjackInfo[localID].hDevice = fd;
                		labjackTrack[i].found = TRUE;
               			return localID;
			}
			else
			{
				close(fd);
			}
		}
		else
		{
            		labjackTrack[i].found = FALSE;
		}
	}
	
	*errorcode = DEVICE_N_NOT_FOUND_LJ;
	localID = -1;
	return  localID;
}



//======================================================================
//WriteRead:	Writes & reads 1+8 bytes to the labjack specified
//				by localID.  Returns 0 for no error.
//----------------------------------------------------------------------
long WriteRead (long localID,
				long timeoutms,
				unsigned char *sendBuffer,
				unsigned char *readBuffer)
{

	long result=0;

	result=WriteLabJack(localID,sendBuffer);
	if(!result)
	{
		//write was good so try to read the response
		result=ReadLabJack(localID,timeoutms,0,readBuffer);
		if(result)
		{
			//error, try to write&read one more time
			Sleep(20);
			result=WriteLabJack(localID,sendBuffer);
			if(!result)
			{
				//write was good so try to read the response
				result=ReadLabJack(localID,timeoutms,0,readBuffer);
			}
			//else 2nd write failed, quit and return the result of WriteHID as errorcode
		}
		//else write & read succeeded, quit and return the result=0 as errorcode
	}
	//else write failed, quit and return the result of WriteHID as errorcode

	return result;
}




//======================================================================
//WriteLabJack:	Writes 1+8 bytes in sendBuffer to the labjack specified
//				by localID.  Returns 0 for
//				no error.
//----------------------------------------------------------------------
long WriteLabJack (long localID,
				   unsigned char *sendBuffer)
{
	long result = 0;
	long errorcode = 0;
	
	result = write(labjackInfo[localID].hDevice, sendBuffer + 1, 8);

	if(result == 8) 
	{
		errorcode=NO_ERROR_LJ;
	}
	else
	{
		errorcode=WRITE_ERROR_LJ;
	}

	return errorcode;
}


//======================================================================
//ReadLabJack:	Reads an "IN" or feature report from a LabJack.
//----------------------------------------------------------------------
long ReadLabJack (long localID,
				  long timeout,	//ms
				  long feature,
				  unsigned char *buffer)	//9 or 129 bytes
{

	long errorcode = 0;
	long rtn;

	if (feature) {	
		if ((rtn = read(labjackInfo[localID].hDevice, buffer + 1, 128)) == -1) {
			errorcode = FEATURE_ERROR_LJ;
		} 
		else 
		{
			errorcode = NO_ERROR_LJ;
		}
	} else {
				
		if ((rtn = read(labjackInfo[localID].hDevice, buffer + 1, 8)) == -1) {
			errorcode = READ_ERROR_LJ;
		} 
		else 
		{
			errorcode = NO_ERROR_LJ;
		}
		
		buffer[0] = 0;
	}

	return errorcode;
	
}


//======================================================================
//ReadInputThread:	Reads 1+8 bytes from the labjack specified
//						by localID.  Should only be started as a thread.
//----------------------------------------------------------------------
DWORD WINAPI ReadInputThread (long *localID)
{
	DWORD numberOfBytesRead;
	long result;
	long errorcode;

	result = 0;//Read 1+8 bytes

	if((result) && (numberOfBytesRead==9))
	{
		errorcode = NO_ERROR_LJ;
	}
	else
	{
		//Unknown error
		errorcode = READ_ERROR_LJ;
	}
	
	return errorcode;
}



//======================================================================
//ReadFeatureThread:	Reads 1+128 bytes from the labjack specified
//						by localID.  Should only be started as a thread.
//----------------------------------------------------------------------
DWORD WINAPI ReadFeatureThread (long *localID)
{
	long result;
	long errorcode;

	result = 0;//Read 1+128 bytes.

	if(result)
	{
		errorcode=NO_ERROR_LJ;
	}
	else
	{
		errorcode=FEATURE_ERROR_LJ;
	}

	return errorcode;
}

	
//======================================================================
//CloseAll:	Closes all handles for the HID specified
//			by refnum.  Returns 0 for
//			no error.
//----------------------------------------------------------------------
long CloseAll (long localID)
{
	long result1,result3,result4,result2;
	long errorcode = 0;
	
	result2 = close(labjackInfo[localID].hDevice);
	
	if(result2 == 0)
	{
		errorcode=NO_ERROR_LJ;
	}
	else
	{
		errorcode=CLOSE_HANDLE_ERROR_LJ;
	}

	return errorcode;
}


//======================================================================
//BuildAICommand:  Builds the 1+8 byte analog input command to send to
//				   a LabJack.  Returns 0 for no error.
//----------------------------------------------------------------------
long BuildAICommand (long command,	//4-bit command, 1CCC, 12=C/R,10=burst,9=stream
					unsigned char sendBuff5,	//buffer+4
					unsigned char sendBuff7,	//buffer+6
					unsigned char sendBuff8,	//buffer+7
					long stateIO,
					long ch1num,
					long ch2num,
					long ch3num,
					long ch4num,
					long ch1gain,
					long ch2gain,
					long ch3gain,
					long ch4gain,
					unsigned char *sendBuffer)
{
	long errorcode=NO_ERROR_LJ;

    long i,j,k,l;
	//Make sure inputs are within the proper range
	if ((stateIO<0) || (stateIO>15))
	{
		errorcode=ILLEGAL_AI_COMMAND_LJ;
		return errorcode;
	}
/* pointless impossible comparisons removed: cnd - 051025
	if ((sendBuff5<0) || (sendBuff5>255))
	{
		errorcode=ILLEGAL_AI_COMMAND_LJ;
		return errorcode;
	}
	if ((sendBuff7<0) || (sendBuff7>255))
	{
		errorcode=ILLEGAL_AI_COMMAND_LJ;
		return errorcode;
	}
	if ((sendBuff8<0) || (sendBuff8>255))
	{
		errorcode=ILLEGAL_AI_COMMAND_LJ;
		return errorcode;
	}
*/

	sendBuffer[5]=sendBuff5;

	sendBuffer[6]=(((unsigned char)command)*16) + ((unsigned char)stateIO);

	sendBuffer[7]=sendBuff7;
	sendBuffer[8]=sendBuff8;

	errorcode=BuildGainMuxCommand(ch1num,ch1gain,&sendBuffer[1]);
	if(errorcode)
	{
		return errorcode;
	}

	errorcode=BuildGainMuxCommand(ch2num,ch2gain,&sendBuffer[2]);
	if(errorcode)
	{
		return errorcode;
	}

	errorcode=BuildGainMuxCommand(ch3num,ch3gain,&sendBuffer[3]);
	if(errorcode)
	{
		return errorcode;
	}

	errorcode=BuildGainMuxCommand(ch4num,ch4gain,&sendBuffer[4]);
	if(errorcode)
	{
		return errorcode;
	}

	return errorcode;
}



//======================================================================
//BuildGainMuxCommand:  Builds the 8-bit gain/mux command to send to
//				        a LabJack.  Returns 0 for no error.
//----------------------------------------------------------------------
long BuildGainMuxCommand (long chnum,
						 long chgain,
						 unsigned char *gainmux)
{
	long errorcode=NO_ERROR_LJ;

	*gainmux=0;

	//gain is bits 6, 5, and 4
	if ((chgain<0) || (chgain>7))
	{
		errorcode=ILLEGAL_GAIN_INDEX_LJ;
		return errorcode;
	}

	//PGA only works with differential channels
	if ((chnum<8) && (chgain!=0))
	{
		errorcode=ILLEGAL_GAIN_INDEX_LJ;
		return errorcode;
	}

	*gainmux=(unsigned char)(chgain*16);

	//mux is bits 3, 2, 1, and 0
	switch(chnum)
	{
		case 0:	  *gainmux += 8;
				  break;
				  
		case 1:	  *gainmux += 9;
				  break;

		case 2:	  *gainmux += 10;
				  break;

		case 3:	  *gainmux += 11;
				  break;

		case 4:	  *gainmux += 12;
				  break;

		case 5:	  *gainmux += 13;
				  break;

		case 6:	  *gainmux += 14;
				  break;

		case 7:	  *gainmux += 15;
				  break;

		case 8:	  *gainmux += 0;
				  break;

		case 9:	  *gainmux += 1;
				  break;

		case 10:  *gainmux += 2;
				  break;

		case 11:  *gainmux += 3;
				  break;

		case 12:  *gainmux += 4;
				  break;

		case 13:  *gainmux += 5;
				  break;

		case 14: *gainmux += 6;
				  break;

		case 15: *gainmux += 7;
				  break;


		default:  errorcode=ILLEGAL_CHANNEL_LJ;
	}

	//set bit 7 to indicate analog command
	*gainmux = BitSet(*gainmux,7);  //set high bit

	return errorcode;
}



//======================================================================
//ParseAIResponse:  Returns 0 for no error.
//----------------------------------------------------------------------
long ParseAIResponse (unsigned char *sendBuffer,
					 unsigned char *readBuffer,
					 long disableCal,
					 long *calData,	//20 element array
					 long *stateIO,
				 	 long *overVoltage,
					 float *voltage1,
					 float *voltage2,
					 float *voltage3,
					 float *voltage4,
					 unsigned char *echoIn,
					 long *ofchecksumError,
					 long *backlog,
					 long *iterationCount,
					 long readCount)

{
	long errorcode=NO_ERROR_LJ;
	long bits;
	long chnum,chgain;

	//Bit 7 of first byte should be a 1
	if (!(BitTst(readBuffer[1],7)))
	{
		errorcode=AI_RESPONSE_ERROR_LJ;
		return errorcode;
	}

	*overVoltage=0;
	if (BitTst(readBuffer[1],4)) *overVoltage=1;

	*stateIO = readBuffer[1] % 16;

	*echoIn = readBuffer[2];	//command/response

	*ofchecksumError=0;
	if (BitTst(readBuffer[1],5)) *ofchecksumError=1;

	*backlog = ((long)(readBuffer[2] % 32)) * 256 / 7;

	*iterationCount = readBuffer[2] / 32;


	//Calculate voltage reading from 1st channel
	bits = (readBuffer[3] / 16) * 256;
	bits += readBuffer[4];
	if(!disableCal)
	{
		ApplyCal(sendBuffer[1],calData,&bits);
	}
	chgain = sendBuffer[1];	//make a copy of XGGGMMMM command byte for this channel
	chgain = BitClr(chgain,7);  //clear high bit
	chgain /= 16;		//get value of GGG (0 to 7)
	chnum = sendBuffer[1];	//make a copy of XGGGMMMM command byte for this channel
	chnum %= 16;	//MMMM
	chnum = BitFlp(chnum,3); //now it is channel index
	errorcode = BitsToVolts (chnum,chgain,bits,voltage1);
	if (errorcode!=0) return errorcode;


	if (readCount)
	{
		*voltage2 = (float)(((((long)readBuffer[7])%16) * 256) + ((long)readBuffer[8]));  //bits 0-11 of counter
		*voltage3 = (float)((((long)readBuffer[7])/16) + (((long)readBuffer[6])*16));  //bits 12-23 of counter
		*voltage4 = (float)readBuffer[5];  //bits 24-31 of counter
	}
	else
	{
		//Calculate voltage reading from 2nd channel
		bits = (readBuffer[3] % 16) * 256;
		bits += readBuffer[5];
		if(!disableCal)
		{
			ApplyCal(sendBuffer[2],calData,&bits);
		}
		chgain = sendBuffer[2];	//make a copy of XGGGMMMM command byte for this channel
		chgain = BitClr(chgain,7);  //clear high bit
		chgain /= 16;		//get value of GGG (0 to 7)
		chnum = sendBuffer[2];	//make a copy of XGGGMMMM command byte for this channel
		chnum %= 16;	//MMMM
		chnum = BitFlp(chnum,3); //now it is channel index
		errorcode = BitsToVolts (chnum,chgain,bits,voltage2);
		if (errorcode!=0) return errorcode;

		//Calculate voltage reading from 3rd channel
		bits = (readBuffer[6] / 16) * 256;
		bits += readBuffer[7];
		if(!disableCal)
		{
			ApplyCal(sendBuffer[3],calData,&bits);
		}
		chgain = sendBuffer[3];	//make a copy of XGGGMMMM command byte for this channel
		chgain = BitClr(chgain,7);  //clear high bit
		chgain /= 16;		//get value of GGG (0 to 7)
		chnum = sendBuffer[3];	//make a copy of XGGGMMMM command byte for this channel
		chnum %= 16;	//MMMM
		chnum = BitFlp(chnum,3); //now it is channel index
		errorcode = BitsToVolts (chnum,chgain,bits,voltage3);
		if (errorcode!=0) return errorcode;

		//Calculate voltage reading from 4th channel
		bits = (readBuffer[6] % 16) * 256;
		bits += readBuffer[8];
		if(!disableCal)
		{
			ApplyCal(sendBuffer[4],calData,&bits);
		}
		chgain = sendBuffer[4];	//make a copy of XGGGMMMM command byte for this channel
		chgain = BitClr(chgain,7);  //clear high bit
		chgain /= 16;		//get value of GGG (0 to 7)
		chnum = sendBuffer[4];	//make a copy of XGGGMMMM command byte for this channel
		chnum %= 16;	//MMMM
		chnum = BitFlp(chnum,3); //now it is channel index
		errorcode = BitsToVolts (chnum,chgain,bits,voltage4);
		if (errorcode!=0) return errorcode;
	}

	return errorcode;
}




//======================================================================
//ApplyCal:  Returns 0 for no error.
//----------------------------------------------------------------------
long ApplyCal (unsigned char gainmux,
			   long *calData,
			   long *bits)
{
	long errorcode=NO_ERROR_LJ;
	float gain;
	float czse;
	long ccdiff;
	
	switch((BitClr(gainmux,7)/16))
	{
		case 0:	  gain = 1.0F;
				  break;
		case 1:	  gain = 2.0F;
				  break;
		case 2:	  gain = 4.0F;
				  break;
		case 3:	  gain = 5.0F;
				  break;
		case 4:	  gain = 8.0F;
				  break;
		case 5:	  gain = 10.0F;
				  break;
		case 6:	  gain = 16.0F;
				  break;
		case 7:	  gain = 20.0F;
				  break;
		default:  errorcode=UNKNOWN_ERROR_LJ;
				  return errorcode;
	}

  
	if (BitTst(gainmux,3))
	{
		//single-ended
		gainmux = gainmux % 8;	//gainmux now equals channel # (0-7)
		*bits -= calData[gainmux];	//subtract offset
		*bits += RoundFL( (((float)(*bits-2048)) / ((float)512)) * ((float)(calData[gainmux]-calData[gainmux+8])) );  //span correction
	}
	else
	{
		//differential
		gainmux = gainmux % 4;	//gainmux now equals channel # (0-3)
		//Offset Correction
		czse = (float)(calData[2*gainmux]-calData[(2*gainmux)+1]);
		*bits -= (long)((gain*czse/2.0F) + (((float)calData[gainmux+16])-(czse/2.0F)));
		//Span Correction
		ccdiff = (calData[(2*gainmux)+8]-calData[2*gainmux]) - (calData[(2*gainmux)+9]-calData[(2*gainmux)+1]);
		if(ccdiff >= 2)
		{
			*bits -= RoundFL(((float)(*bits-2048))/256.0F);
		}
		if(ccdiff <= -2)
		{
			*bits += RoundFL(((float)(*bits-2048))/256.0F);
		}
	}

	if((*bits)>4095) *bits=4095;
	if((*bits)<0) *bits=0;

	return errorcode;
}




//======================================================================
//BuildAOCommand:  Builds the 1+8 byte counter/pwm command to send to
//				   a LabJack.  Returns 0 for no error.
//----------------------------------------------------------------------
long BuildAOCommand (long trisD,
					 long trisIO,
					 long stateD,
					 long stateIO,
					 long updateDigital,
					 long resetCounter,
					 float analogOut0,
					 float analogOut1,
					 unsigned char *sendBuffer)
{
	long errorcode=NO_ERROR_LJ;
	int binAO;
	int i;

	//Firmware expects 1=true=input and 0=false=output, but I want
	//input to be the more natural default, so I flip all the bits here
	//in the LabJack driver so that 0=input and 1=output at
	//the application layer.
	for(i=0;i<16;i++)
	{
		trisD=BitFlp(trisD,i);
	}
	for(i=0;i<4;i++)
	{
		trisIO=BitFlp(trisIO,i);
	}

	//Make sure each DIO input is within the proper range
	if ((trisD<0) || (trisD>65535))
	{
		errorcode=ILLEGAL_AO_COMMAND_LJ;
		return errorcode;
	}

	if ((trisIO<0) || (trisIO>15))
	{
		errorcode=ILLEGAL_AO_COMMAND_LJ;
		return errorcode;
	}

	if ((stateD<0) || (stateD>65535))
	{
		errorcode=ILLEGAL_AO_COMMAND_LJ;
		return errorcode;
	}

	if ((stateIO<0) || (stateIO>15))
	{
		errorcode=ILLEGAL_AO_COMMAND_LJ;
		return errorcode;
	}

		//Make sure each of the voltages are within the proper range
	if ((analogOut0<0) || (analogOut0>5.0))
	{
		errorcode=ILLEGAL_AO_COMMAND_LJ;
		return errorcode;
	}

	if ((analogOut1<0) || (analogOut1>5.0))
	{
		errorcode=ILLEGAL_AO_COMMAND_LJ;
		return errorcode;
	}


	sendBuffer[1]=(unsigned char)(trisD/256);	//upper byte of trisD
	sendBuffer[2]=(unsigned char)(trisD%256);	//lower byte of trisD
	sendBuffer[3]=(unsigned char)(stateD/256);	//upper byte of stateD
	sendBuffer[4]=(unsigned char)(stateD%256);	//lower byte of stateD
	sendBuffer[5]=((unsigned char)(trisIO*16)) + ((unsigned char)stateIO);


	sendBuffer[6]=0;

	if(updateDigital)
	{
		sendBuffer[6] = BitSet(sendBuffer[6],4);  //set bit 4
	}
	
	if(resetCounter)
	{
		sendBuffer[6] = BitSet(sendBuffer[6],5);  //set bit 5
	}

	binAO = (int)(RoundFL((1023.0F * (analogOut0 / 5.0F))));
	if (BitTst(binAO,1)) sendBuffer[6]=BitSet(sendBuffer[6],3);
	if (BitTst(binAO,0)) sendBuffer[6]=BitSet(sendBuffer[6],2);
	sendBuffer[7] = (unsigned char)(binAO/4);  //upper 8 bits of pwm command

	binAO = (int)(RoundFL((1023.0F * (analogOut1 / 5.0F))));
	if (BitTst(binAO,1)) sendBuffer[6]=BitSet(sendBuffer[6],1);
	if (BitTst(binAO,0)) sendBuffer[6]=BitSet(sendBuffer[6],0);
	sendBuffer[8] = (unsigned char)(binAO/4);  //upper 8 bits of pwm command
	
	return errorcode;
}



//======================================================================
//ParseAOResponse:  Returns 0 for no error.
//----------------------------------------------------------------------
long ParseAOResponse (unsigned char *readBuffer,
					  long *stateD,
					  long *stateIO,
				 	  unsigned long *count)
{
	long errorcode=NO_ERROR_LJ;

	//Bit 7 of first byte should be a 0
	if ((BitTst(readBuffer[1],7)))
	{
		errorcode=RESPONSE_ERROR_LJ;
		return errorcode;
	}

	*stateD = ((long)readBuffer[2]) * 256;
	*stateD += ((long)readBuffer[3]);
	*stateIO = ((long)readBuffer[4]) / 16;

	*count = (unsigned long)readBuffer[8];
	*count += ((unsigned long)readBuffer[7]) * 256;
	*count += ((unsigned long)readBuffer[6]) * 65536;
	*count += ((unsigned long)readBuffer[5]) * 16777216;

	return errorcode;
}



//======================================================================
//RoundFL:  Send a float and it is rounded to a long.
//----------------------------------------------------------------------
long RoundFL (float fp)
{
	if((fmod((double)fp,1.0)) >= 0.50)
	{
		fp += 0.50F;
	}

	return (long)fp; //fp gets truncated here
}


//======================================================================
//ReadMemNoOpen: Same as ReadMem, except a open and close are not performed
//----------------------------------------------------------------------
long ReadMemNoOpen(long *fd,		//file descriptor
			 long address,
			 long *data3,
			 long *data2,
			 long *data1,
			 long *data0)

{	
	long result = 0; 
	long errorcode = 0;
	unsigned char sendBuffer[9]={0,0,0,0,0,0,0,0,0};
	unsigned char readBuffer[9]={0,0,0,0,0,0,0,0,0};
	
	if ((address<0) || (address>8188))
	{
		errorcode=ILLEGAL_INPUT_ERROR_LJ;
		return errorcode;
	}

	//Fill sendBuffer with the proper values.
	sendBuffer[6] = 80;
	sendBuffer[7] = (unsigned char)(address/256);
	sendBuffer[8] = (unsigned char)(address%256);
	
	result = write(*fd, sendBuffer + 1, 8);

	if(result == 8)
	{
		//write was good so try to read the response
		result = read(*fd, readBuffer + 1, 8);
		if(result == -1)
		{
			//error, try to write&read one more time
			Sleep(20);
			result = write(*fd, sendBuffer + 1, 8);
			if(result == 8)
			{
				//write was good so try to read the response
				result = read(*fd, readBuffer + 1, 8);
				if(result == -1)
				{
					errorcode = READ_ERROR_LJ;
					return errorcode;
				}
			}
			else
			{
				errorcode = WRITE_ERROR_LJ;
				return errorcode;
			}
		}
		readBuffer[0] = 0;
	}
	else
	{
		errorcode = WRITE_ERROR_LJ;
		return errorcode;
	}
	//Parse the response
	if(readBuffer[1] != 80)
	{
		errorcode = RESPONSE_ERROR_LJ;
		return errorcode;
	}
	if(sendBuffer[7] != readBuffer[7])
	{
		errorcode = ECHO_ERROR_LJ;
		return errorcode;
	}
	if(sendBuffer[8] != readBuffer[8])
	{
		errorcode = ECHO_ERROR_LJ;
		return errorcode;
	}
	
	*data3 = readBuffer[2];
	*data2 = readBuffer[3];
	*data1 = readBuffer[4];
	*data0 = readBuffer[5];

	return errorcode;
}

//======================================================================
//twoscomplement:  Returns the twos compliment of the given val     
//----------------------------------------------------------------------
long twoscomplement(long val)
{
	if(val > 128)
		return (val - 256);
	return val;
}

