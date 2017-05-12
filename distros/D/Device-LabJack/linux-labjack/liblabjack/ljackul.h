//----------------------------------------------------------------------
//
//  ljackul.h
//  
//  Header file for ljackul driver template code.         
//
//  support@labjack.com
//  8/2003
//
// This program is free software; you can redistribute it and/or modify it
// under the terms of the GNU General Public License as published by the Free
// Software Foundation; either version 2 of the License, or (at your option)
// any later version.
//----------------------------------------------------------------------
//
// Version 1.03:  Added "enableSTB" to Counter function.
//				  Added counter read option to stream functions.
//
// Version 1.05:  Changed errorcode 52 to a warning.  Just means
//				    a search of the USB turned up an HID that
//				    returned an unexpected response (not a LabJack).
//				  Changed calling convention to stdcall (_stdcall).
//				  Added NoThread function for TestPoint and VC debug.
//				  Fixed problem where timeout during feature stream or
//					or burst caused a fatal fault in Win98SE.
//
// Version 1.051: Fixed a problem on Win 2000/XP where the LabJack did
//				  not work if there were certain other HID devices on
//				  on the bus.
//
// Version 1.06:  Renamed function Reset to ResetLJ to avoid
//				  the reserved word.  Changed DLL to allow
//				  multiple processes to attach at the same time.
//
// Version 1.061: Added back Reset (in addition to ResetLJ).
//
// Version 1.07:  Added E (easy) functions.
//
// Version 1.073: Fixed problem where AIStreamStart returned error if
//				  demo was selected.  Fixed problem where one particular
//				  in-house USB device (in UK) interfered with LabJack U12.
//
// Version 1.074: Fixed problem where 2-channel burst/stream data was not
//				  always scanned in the proper channel order, resulting
//				  in occasional time-sequence flip-flops.
//
// Version 1.09:  Added pulse output functions.
//
// Version 1.096: Fixed timeout for PulseOut.
//
// Version 1.097: Added asynchronous comm functions.
//
// Version 1.098: Fixed AsynchConfig bug concerning DIO configuration.
//
// Version 1.100: Added synchronous and sht1x functions.
//
// Version 1.11:  Changed digital I/O tris and state globals to arrays,
//				  so that information is stored for each LabJack in
//				  multiple LabJack applications.  Each LabJack must have
//				  a unique LocalID for this to work.  Also fixed a related
//				  issue in AOUpdate which could have caused the direction
//				  of all D lines to be toggled.
//
// Version 1.12:  Added globals to attempt to keep track of AO states.  If
//				  a value <0 is passed for an analog output, the global
//				  value is used instead.  This allows 1 AO to be updated
//				  without changing the other, but is not foolproof as
//				  the globals are initialized to 0.0 volts when the DLL is
//				  first loaded, and if the LabJack is reset the AO are set
//				  to 0.0 but the DLL might not know the LabJack has reset.
//
// Version 1.13:  Added most functions (i.e. WriteRead) to export list to
//				  make it easier for users to call functions at a lower
//				  lever (i.e. open, writeread, ... , writeread, close).
//
// Version 1.14:  Added logic to AIBurst that forces normal transfer mode
//				  if timeout is set to 4 seconds or longer.  It seems
//				  that Windows has it's own timeout on turbo mode at
//				  5 seconds.
//
// Version 1.15:  Firmware only allows IO0 or IO1 for AIBurst trigger.
//
// Version 1.16:  Changed AIBurst transfer mode logic so that auto mode
//				  selects turbo unless timeout>=4 or numScans/scanRate>=4.
//
// Version 1.17:  Changed timeouts from 1s to 2s.
//
// Version 1.18:  Modified Static Array TempBuff in the StreamRead Function
//                This fixes a Stack overflow error in TestPoints Windows 98 SE
//                distrobution.
//
// Linux revisions:
//
// Version 1.181:  Fixed problem in OpenLabjack when *idnum is 0.
//
//----------------------------------------------------------------------
//


//Exported Functions:
//		AISample
//		AIBurst
//		AIStreamStart
//		AIStreamRead
//		AIStreamClear
//		AOUpdate
//		AsynchConfig
//		Asynch
//		BitsToVolts
//		VoltsToBits
//		Counter
//		DigitalIO
//		EAnalogIn
//		EAnalogOut
//		ECount
//		EDigitalIn
//		EDigitalOut
//		GetDriverVersion
//		GetErrorString
//		GetFirmwareVersion
//		GetWinVersion
//		ListAll
//		LocalID
//		NoThread
//		PulseOut
//		PulseOutStart
//		PulseOutFinish
//		PulseOutCalc
//		ReEnum
//		Reset
//		ResetLJ
//		SHT1X
//		SHTCRC
//		SHTComm
//		Synch
//		Watchdog
//		ReadMem
//		WriteMem
//
//Low Level Exported Functions:
//		OpenLabJack
//		WriteRead
//		WriteLabJack
//		ReadLabJack
//		CloseAll
//		BuildAICommand
//		ParseAIResponse
//		BuildAOCommand
//		ParseAOResponse
//		RoundFL
//		SHTWriteRead
//		ReadMemNoOpen
//		twoscomplement


#if defined(__cplusplus)
extern "C"
{
#endif

#define _stdcall

//======================================================================
// InitLabjack(): (efs) for now force the user to call the initialization
// 			routine manually. Again, not ideal, but it lets us
//			make progress.
//----------------------------------------------------------------------
void InitLabjack();

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
//				*voltage	-Returns the voltage reading (SGL).
//
//	Time:		20 ms
//----------------------------------------------------------------------
long _stdcall EAnalogIn(long *idnum,
					  long demo,
					  long channel,
					  long gain,
					  long *overVoltage,
					  float *voltage);


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
long _stdcall EAnalogOut(long *idnum,
					   long demo,
					   float analogOut0,
					   float analogOut1);


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
long _stdcall ECount	(long *idnum,
					 long demo,
					 long resetCounter,
					 double *count,
					 double *ms);


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
long _stdcall EDigitalIn(long *idnum,
					   long demo,
					   long channel,
					   long readD,
					   long *state);


//======================================================================
// EDigitalOut:	Easy function writes 1 digital output.  Also configures
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
long _stdcall EDigitalOut(long *idnum,
						long demo,
						long channel,
						long writeD,
						long state);


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
//				 which occurs near the middle of bit 8.
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
long _stdcall AsynchConfig(	long *idnum,
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
					long halfC);


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
//				portB		-If >0, asynch PortB is used instead of PortA.
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
//	Time:		20 ms to read & write up to 4 bytes, plus 40 ms for each
//				additional 4 bytes to read or write.  Possibly extra
//				time for slow baud rates.
//----------------------------------------------------------------------
long _stdcall Asynch(	long *idnum,
				long demo,
				long portB,
				long enableTE,
				long enableTO,
				long enableDel,
				long baudrate,
				long numWrite,
				long numRead,
				long *data);


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
//				*stateIO	-Returns input states for IO0-IO3 (I32).
//				*overVoltage	-If >0, an overvoltage has been detected
//								 on one of the analog inputs (I32).
//				*voltages	-Returns numChannels voltage readings (SGL).
//
//	Time:		20 ms
//----------------------------------------------------------------------
long _stdcall AISample(long *idnum,
			  long demo,
			  long *stateIO,
			  long updateIO,
			  long ledOn,
			  long numChannels,
			  long *channels,
			  long *gains,
			  long disableCal,
			  long *overVoltage,
			  float *voltages);


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
//							 1=IO0, or 2=IO1 (I32).
//				triggerState	-If >0, the acquisition will be triggered
//								 when the selected IO port reads high (I32).
//				numScans	-Number of scans which will be collected (I32).
//							 Minimum is 1.  Maximum numSamples is 4096 where
//							 numSamples is numScans * numChannels.
//				timeout		-Function timeout value in seconds (I32).  Note
//							 that if timeout is >= 4, the transferMode
//							 is automatically set to normal.
//				*voltages	-Voltage readings buffer.  Send a 4096 by 4
//							 element array of zeros (SGL).
//				*stateIOout	-IO state readings buffer.  Send a 4096 element
//							 array of zeros (I32).
//				transferMode	-0=auto,1=normal,2=turbo (I32).  If auto,
//								 turbo mode is used unless timeout is >= 4,
//								 or numScans/scanRate >=4.
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
//			estimated with the below formulas.  The actual number of samples
//			collected and transferred by the LabJack is the smallest power
//			of 2 from 64 to 4096 which is at least as big as numScans*numChannels.
//			This is represented below as numSamplesActual.
//			Normal => 30+(1000*numSamplesActual/sampleRate)+(2.5*numSamplesActual)
//			Turbo  => 30+(1000*numSamplesActual/sampleRate)+(0.4*numSamplesActual)
//----------------------------------------------------------------------
long _stdcall AIBurst(long *idnum,
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
			 long transferMode);


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
//				reserved1	-Reserved for future use.  Send 0 (I32).
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
long _stdcall AIStreamStart(long *idnum,
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
				   long readCount);


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
//				*reserved	-Reserved for future use (I32).
//				*ljScanBacklog	-Returns the scan backlog of the LabJack RAM
//								 buffer (I32).
//				*overVoltage	-If >0, an overvoltage has been detected on
//								 at least one sample of at least one of the
//								 analog inputs (I32).
//----------------------------------------------------------------------
long _stdcall AIStreamRead(long localID,
				  long numScans,
				  long timeout,
				  float (*voltages)[4],
				  long *stateIOout,
				  long *reserved,
				  long *ljScanBacklog,
				  long *overVoltage);


//======================================================================
// AIStreamClear:  This function stops the continuous acquisition.  It
//				   should be called after AIStreamStart and after any
//				   calls to AIStreamRead.
//
//	Returns:	LabJack errorcodes or 0 for no error (I32).
//	Inputs:		localID		-Send the local ID from AIStreamStart/Read (I32).
//	Outputs:	none
//----------------------------------------------------------------------
long _stdcall AIStreamClear(long localID);


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
long _stdcall AOUpdate(long *idnum,
			  long demo,
			  long trisD,
			  long trisIO,
			  long *stateD,
			  long *stateIO,
			  long updateDigital,
			  long resetCounter,
			  unsigned long *count,
			  float analogOut0,
			  float analogOut1);


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
long _stdcall BitsToVolts (long chnum,
				  long chgain,
				  long bits,
				  float *volts);


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
long _stdcall VoltsToBits (long chnum,
				  long chgain,
				  float volts,
				  long *bits);


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
long _stdcall Counter(long *idnum,
			 long demo,
			 long *stateD,
			 long *stateIO,
			 long resetCounter,
			 long enableSTB,
			 unsigned long *count);


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
long _stdcall DigitalIO(long *idnum,
			   long demo,
			   long *trisD,
			   long trisIO,
			   long *stateD,
			   long *stateIO,
			   long updateDigital,
			   long *outputD);


//======================================================================
//GetDriverVersion
//
//	Returns:	Version number of this DLL (SGL).
//	Inputs:		none
//	Outputs:	none
//----------------------------------------------------------------------
float _stdcall GetDriverVersion(void);


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
void _stdcall GetErrorString	(long errorcode,
					 char *errorString);


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
float _stdcall GetFirmwareVersion (long *idnum);


//======================================================================
//GetWinVersion:  Uses a Windows API function to get the OS version.
//
//	Returns:	LabJack errorcodes or 0 for no error (I32).
//	Inputs:		none
//
//	Outputs: (U32)
//						Platform	Major	Minor	Build
//	Windows 3.1				0		  -		  -		   -
//	Windows 95				1		  4		  0		  950
//	Windows 95 OSR2			1		  4		  0		 1111
//	Windows 98				1		  4		 10		 1998
//	Windows 98SE			1		  4		 10		 2222
//	Windows Me				1		  4		 90		 3000
//	Windows NT 3.51			2		  3		 51		   -
//	Windows NT 4.0			2		  4		  0		 1381
//	Windows 2000			2		  5		  0		 2195
//	Windows XP				2		  5		  1		   -
//----------------------------------------------------------------------
long _stdcall GetWinVersion(unsigned long *majorVersion,
				   unsigned long *minorVersion,
				   unsigned long *buildNumber,
				   unsigned long *platformID,
				   unsigned long *servicePackMajor,
				   unsigned long *servicePackMinor);


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
long _stdcall ListAll(long *productIDList,
			 long *serialnumList,
			 long *localIDList,
			 long *powerList,
			 long (*calMatrix)[20],
			 long *numberFound,
			 long *fcddMaxSize,
			 long *hvcMaxSize);


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
long _stdcall LocalID(long *idnum,
			 long localID);


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
//			  a given time.  When the LabJack resets, the read
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
long _stdcall NoThread(long *idnum, long noThread);


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
long _stdcall PulseOut(long *idnum,
			  long demo,
			  long lowFirst,
			  long bitSelect,
			  long numPulses,
			  long timeB1,
			  long timeC1,
			  long timeB2,
			  long timeC2);


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
long _stdcall PulseOutStart	(long *idnum,
					 long demo,
					 long lowFirst,
					 long bitSelect,
					 long numPulses,
					 long timeB1,
					 long timeC1,
					 long timeB2,
					 long timeC2);


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
long _stdcall PulseOutFinish	(long *idnum,
					 long demo,
					 long timeoutMS);


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
long _stdcall PulseOutCalc(	float *frequency,
					long *timeB,
					long *timeC);


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
long _stdcall ReEnum(long *idnum);


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
long _stdcall Reset(long *idnum);


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
long _stdcall ResetLJ(long *idnum);


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
long _stdcall SHT1X(	long *idnum,
			long demo,
			long softComm,
			long mode,
			long statusReg,
			float *tempC,
			float *tempF,
			float *rh);


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
long _stdcall SHTComm(	long *idnum,
				long softComm,
				long waitMeas,
				long serialReset,
				long dataRate,
				long numWrite,
				long numRead,
				unsigned char *datatx,
				unsigned char *datarx);


//======================================================================
// SHTCRC:		Checks the CRC on a SHT1X communication.  Last byte of
//				datarx is the CRC.  Returns 0 if CRC is good, or
//				SHT1X_CRC_ERROR_LJ if CRC is bad.
//----------------------------------------------------------------------
long _stdcall SHTCRC(	long statusReg,
				long numWrite,		// 0-4
				long numRead,		// 0-4
				unsigned char *datatx,  //4 byte write array
				unsigned char *datarx);	//4 byte read array


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
//				additional 4 bytes to read or write.  Extra 20 ms if configIO
//				is true.  Extra time if delays are enabled.
//----------------------------------------------------------------------
long _stdcall Synch(	long *idnum,
			long demo,
			long mode,
			long msDelay,
			long husDelay,
			long controlCS,
			long csLine,
			long csState,
			long configD,
			long numWriteRead,
			long *data);


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
long _stdcall Watchdog(long *idnum,
			  long demo,
			  long active,
			  long timeout,
			  long reset,
			  long activeD0,
			  long activeD1,
			  long activeD8,
			  long stateD0,
			  long stateD1,
			  long stateD8);


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
long _stdcall ReadMem(long *idnum,
			 long address,
			 long *data3,
			 long *data2,
			 long *data1,
			 long *data0);


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
long _stdcall WriteMem(long *idnum,
			  long unlocked,
			  long address,
			  long data3,
			  long data2,
			  long data1,
			  long data0);


#if defined(__cplusplus)
}
#endif 

