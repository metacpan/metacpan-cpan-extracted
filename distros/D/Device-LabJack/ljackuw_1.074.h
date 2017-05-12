//----------------------------------------------------------------------
//
//  ljackuw.h
//  
//  Header file for ljackuw DLL.         
//
//  support@labjack.com
//  10/2002
//
// Version 1.03:  Added "enableSTB" to Counter function.
//				  Added counter read option to stream functions.
//
// Version 1.05:  Changed errorcode 52 to a warning.  Just means
//				    a search of the USB turned up an HID that
//				    returned an unexpected response (not a LabJack).
//				  Changed calling convention to stdcall (WINAPI).
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
//----------------------------------------------------------------------
//


//Exported Functions:
//		EAnalogIn
//		EAnalogOut
//		ECount
//		EDigitalIn
//		EDigitalOut
//		AISample
//		AIBurst
//		AIStreamStart
//		AIStreamRead
//		AIStreamClear
//		AOUpdate
//		BitsToVolts
//		VoltsToBits
//		Counter
//		DigitalIO
//		GetDriverVersion
//		GetErrorString
//		GetFirmwareVersion
//		GetWinVersion
//		ListAll
//		LocalID
//		NoThread
//		ReEnum
//		Reset
//		ResetLJ
//		Watchdog
//		ReadMem
//		WriteMem


#if defined(__cplusplus)
extern "C"
{
#endif


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
long WINAPI EAnalogIn(long *idnum,
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
long WINAPI EAnalogOut(long *idnum,
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
long WINAPI ECount	(long *idnum,
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
long WINAPI EDigitalIn(long *idnum,
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
long WINAPI EDigitalOut(long *idnum,
						long demo,
						long channel,
						long writeD,
						long state);


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
long WINAPI AISample(long *idnum,
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
long WINAPI AIBurst(long *idnum,
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
long WINAPI AIStreamStart(long *idnum,
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
long WINAPI AIStreamRead(long localID,
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
long WINAPI AIStreamClear(long localID);


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
long WINAPI AOUpdate(long *idnum,
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
long WINAPI BitsToVolts (long chnum,
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
long WINAPI VoltsToBits (long chnum,
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
long WINAPI Counter(long *idnum,
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
long WINAPI DigitalIO(long *idnum,
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
float WINAPI GetDriverVersion(void);


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
void WINAPI GetErrorString	(long errorcode,
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
float WINAPI GetFirmwareVersion (long *idnum);


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
//	Whistler				2		  5		  1		   -
//----------------------------------------------------------------------
long WINAPI GetWinVersion(unsigned long *majorVersion,
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
long WINAPI ListAll(long *productIDList,
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
long WINAPI LocalID(long *idnum,
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
long WINAPI NoThread(long *idnum, long noThread);


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
long WINAPI ReEnum(long *idnum);


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
long WINAPI Reset(long *idnum);


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
long WINAPI ResetLJ(long *idnum);


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
long WINAPI Watchdog(long *idnum,
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
long WINAPI ReadMem(long *idnum,
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
long WINAPI WriteMem(long *idnum,
			  long unlocked,
			  long address,
			  long data3,
			  long data2,
			  long data1,
			  long data0);


#if defined(__cplusplus)
}
#endif 

