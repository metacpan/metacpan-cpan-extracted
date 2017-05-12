#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#if defined LJWIN
#include "ljackuw.h"
#else
#include <ljackul.h>
#endif

MODULE = Device::LabJack		PACKAGE = Device::LabJack		

PROTOTYPES: DISABLE

##############################################################################################	

=head1 NAME

Device::LabJack v0.02 - a perl interface to the LabJack U12 (USB measurement/automation device - A/D, D/A converter and digital I/O)

=head1 DESCRIPTION

You can read and write digital and analog data to and from your LabJack U12 device with this module.

=head2 What is a LabJack?

LabJacks are USB/Ethernet based measurement and automation devices which provide analog inputs/outputs, digital inputs/outputs, and more. They serve as an inexpensive and easy to use interface between computers and the physical world.


=cut


##############################################################################################	




=head GetFirmwareVersion
  
//======================================================================
//GetFirmwareVersion:  Used to retrieve the firmware version from
//                                              the LabJack's processor.
//                              
//      Returns:        Version number of the LabJack firmware or 0 for error (SGL).
//      Inputs:         *idnum          -Local ID, Serial Number, or -1 for first
//                                                       found (I32).
//      Outputs:        *idnum          -Returns the Local ID or -1 if no LabJack is
//                                                       found (I32).  If error, returns 512 plus
//                                                       a normal LabJack errorcode.
//                                
//      Time:           20 ms
//----------------------------------------------------------------------
float _stdcall GetFirmwareVersion (long *idnum);
  



SYNOPSIS

# Example perl program which calls this module -

use Device::LabJack;

$idnum = -1;

my (@results) = Device::LabJack::GetFirmwareVersion($idnum);
 
print "Firware version: " . join("\n",@results) . "\n";

INFO

GetFirmwareVersion:  Used to retrieve the firmware version from
                     the LabJack''s processor.

     Returns:        Version number of the LabJack firmware or 0 for error (SGL).
     Inputs:         *idnum          -Local ID, Serial Number, or -1 for first
                                      found (I32).
     Outputs:        *idnum          -Returns the Local ID or -1 if no LabJack is
                                      found (I32).  If error, returns 512 plus
                                      a normal LabJack errorcode.

     Time:           20 ms


=cut
#// ###########################################################################

  
float 
GetFirmwareVersion(idnum)
        long idnum

    CODE:
        RETVAL = GetFirmwareVersion(&idnum);
    OUTPUT:
        RETVAL




=head AISample

################################################################################

SYNOPSIS


# Example perl program which calls this module:-

use Device::LabJack;

$idnum=-1;
$demo=0;
$stateIO=0;
$updateIO=0;
$ledOn=1;
@channels=(0,1,2,3);
@gains=(0,0,0,0);
$disableCal=0;

my(@results)=Device::LabJack::AISample($idnum,$demo,$stateIO,$updateIO,$ledOn,\@channels,\@gains,$disableCal);
print join("\n",@results);

INFO

Reads the voltages from 1,2, or 4 analog inputs.  Also
controls/reads the 4 IO ports.  Execution time for this
function is 20 milliseconds or less.

Declaration:
long __cdecl AISample ( long *idnum,
                long demo,
                long *stateIO,
                long updateIO,
                long ledOn,
                long numChannels,
                long *channels,
                long *gains,
                long disableCal,
                long *overVoltage,
                float *voltages )

Parameter Description:
Returns:    LabJack errorcodes or 0 for no error.
Inputs:
�   *idnum - Local ID, serial number, or -1 for first found.
�   demo - Send 0 for normal operation, >0 for demo mode.  Demo mode allows this function to be called without a LabJack.
�   *stateIO - Output states for IO0-IO3.
�   updateIO - If >0, state values will be written.  Otherwise, just a read is performed.
�   ledOn - If >0, the LabJack LED is turned on.
�   numChannels - Number of analog input channels to read (1,2, or 4).
�   *channels - Pointer to an array of channel commands with at least numChannels elements.  Each channel command is 0-7 for single-ended, or 8-11 for differential.
�   *gains - Pointer to an array of gain commands with at least numChannels elements.  Gain commands are 0=1, 1=2, ..., 7=20.  This amplification is only available for differential channels.
�   disableCal - If >0, voltages returned will be raw readings that are not corrected using calibration constants.
�   *voltages - Pointer to an array where voltage readings are returned.  Send a 4-element array of zeros.
Outputs:
�   *idnum - Returns the local ID or -1 if no LabJack is found.
�   *overVoltage - If >0, an overvoltage has been detected on one of the selected analog inputs.

=cut

void
AISample(idnum,demo,stateIO,updateIO,ledOn,channels,gains,disableCal)
        int idnum
        int demo
        int stateIO
        int updateIO
        int ledOn
//        int numCh
        SV * channels
        SV * gains
        int disableCal
    INIT:
        int i,n,numchannels,numgains,numCh;
        long errorcode;
        long lchannels[14]; // ={0,1,2,3};
        long lgains[14];     // ={0,0,0,0};
        long ov;
        float voltages[4]={0,0,0,0};

        // Check that they passed an array of channels, and count the elements
        if ((!SvROK(channels))
            || (SvTYPE(SvRV(channels)) != SVt_PVAV)
            || ((numchannels = av_len((AV *)SvRV(channels))) < 0))
        {
            XSRETURN_UNDEF;
        }

        // Check that they passed an array of gains, and count the elements
        if ((!SvROK(gains))
            || (SvTYPE(SvRV(gains)) != SVt_PVAV)
            || ((numgains = av_len((AV *)SvRV(gains))) < 0))
        {
            XSRETURN_UNDEF;
        }

        // Make sure there's a gain for every channel
        if(numgains<numchannels) {
            XSRETURN_UNDEF;
        }

    PPCODE:

        // Extract the channels we got from perl...
        for (n = 0; n <= numchannels; n++) {
                lchannels[n]= SvNV(*av_fetch((AV *)SvRV(channels), n, 0));
        }
        // Extract the gains we got from perl...
        for (n = 0; n <= numgains; n++) {
                lgains[n]= SvNV(*av_fetch((AV *)SvRV(gains), n, 0));
        }
        numCh=numchannels+1;

        // Run the command
        errorcode = AISample (&idnum,demo,&stateIO,updateIO,ledOn,numCh,lchannels,lgains,disableCal,&ov,voltages);

        // Return the results to perl in a big array
        if(errorcode) {
          char errorString[51];
          GetErrorString ( errorcode, errorString );
          XPUSHs(sv_2mortal(newSVpv(errorString,0)));
        } else {
          XPUSHs(sv_2mortal(newSVnv(errorcode)));
        }

        XPUSHs(sv_2mortal(newSVnv(idnum)));
        XPUSHs(sv_2mortal(newSVnv(ov)));
        XPUSHs(sv_2mortal(newSVnv(stateIO)));
        for(i=0;i<numCh;i++)XPUSHs(sv_2mortal(newSVnv(voltages[i])));
        












=head AOUpdate

################################################################################


INFO

Sets the voltages of the analog outputs. Also controls/reads all 20 digital 
I/O and the counter. Execution time for this function is 20 milliseconds or 
less. 

Declaration:
long AOUpdate ( long *idnum,
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


Parameter Description:
Returns: LabJack errorcodes or 0 for no error.
Inputs:
  - *idnum - Local ID, serial number, or -1 for first found.
  - demo - Send 0 for normal operation, >0 for demo mode. Demo mode allows this function to be called without a LabJack.
  - trisD - Directions for D0-D15. 0=Input, 1=Output.
  - trisIO - Directions for IO0-IO3. 0=Input, 1=Output.
  - *stateD - Output states for D0-D15.
  - *stateIO - Output states for IO0-IO3.
  - updateDigital - If >0, tris and state values will be written. Otherwise, just a read is performed.
  - resetCounter - If >0, the counter is reset to zero after being read.
  - analogOut0 - Voltage from 0.0 to 5.0 for AO0.
  - analogOut1 - Voltage from 0.0 to 5.0 for AO1.
Outputs:
  - *idnum - Returns the local ID or -1 if no LabJack is found.
  - *stateD - States of D0-D15.
  - *stateIO - States of IO0-IO3.
  - *count - Current value of the 32-bit counter (CNT). This value is read before the counter is reset.

=cut

void
AOUpdate (idnum,demo,trisD,trisIO,stateD,stateIO,updateDigital,resetCounter,analogOut0,analogOut1)
        int idnum
        int demo
        int trisD
        int trisIO
        int stateD
        int stateIO
        int updateDigital
        int resetCounter
        float analogOut0
        float analogOut1

    INIT:
        unsigned count=0;
        long errorcode=0;
//        int lstateD=0;
//        int lstateIO=0;


    PPCODE:

        // Run the command
        // errorcode = AISample (&idnum,demo,&stateIO,updateIO,ledOn,numCh,lchannels,lgains,disableCal,&ov,voltages);

        errorcode = AOUpdate (&idnum,demo,trisD,trisIO,&stateD,&stateIO,updateDigital,resetCounter,&count,analogOut0,analogOut1);

        // Return the results to perl in a big array
        if(errorcode) {
          char errorString[51];
          GetErrorString ( errorcode, errorString );
          XPUSHs(sv_2mortal(newSVpv(errorString,0)));
        } else {
          XPUSHs(sv_2mortal(newSVnv(errorcode)));
        }

        XPUSHs(sv_2mortal(newSVnv(idnum)));
        XPUSHs(sv_2mortal(newSVnv(stateD)));
        XPUSHs(sv_2mortal(newSVnv(stateIO)));
        XPUSHs(sv_2mortal(newSVnv(count)));
        









=head AIBurst

################################################################################


INFO

Reads a specified number of scans (up to 4096) at a specified scan rate (up to 8192 Hz) from
1,2, or 4 analog inputs. First, data is acquired and stored in the LabJack's 4096 sample RAM
buffer. Then, the data is transferred to the PC.

Declaration:
long AIBurst ( long *idnum,
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
               long transferMode )


Parameter Description:
Returns: LabJack errorcodes or 0 for no error.
Inputs:
  - *idnum   -   Local ID, serial number, or -1 for first found.
  - demo   -   Send 0 for normal operation, >0 for demo mode. Demo mode allows this function to be called without a LabJack.
  - *stateIOin   -   Output states for IO0-IO3.
  - updateIO   -   If >0, state values will be written. Otherwise, just a read is performed.
  - ledOn   -   If >0, the LabJack LED is turned on.
  - numChannels   -   Number of analog input channels to read (1,2, or 4).
  - *channels   -   Pointer to an array of channel commands with at least numChannels elements. Each channel command is 0-7 for single-ended, or 8-11 for differential.
  - *gains   -   Pointer to an array of gain commands with at least numChannels elements. Gain commands are 0=1, 1=2, ..., 7=20. This amplification is only available for differential channels.
  - *scanRate   -   Scans acquired per second. A scan is a reading from every channel (1,2, or 4). The sample rate (scanRate * numChannels) must be between 400 and 8192.
  - disableCal   -   If >0, voltages returned will be raw readings that are not corrected using calibration constants.
  - triggerIO   -   The IO port to trigger on (0=none, 1=IO0, ...,4=IO3).
  - triggerState   -   If >0, the acquisition will be triggered when the selected IO port reads high.
  - numScans   -   Number of scans which will be returned. Minimum is 1. Maximum numSamples is 4096, where numSamples is numScans * numChannels.
  - timeout   -   This function will return immediately with a timeout error if it does not receive a scan within this number of seconds.
  - *voltages   -   Pointer to a 4096 by 4 array where voltage readings are returned. Send filled with zeros.
  - *stateIOout   -   Pointer to a 4096 element array where IO states are returned. Send filled with zeros.
  - transferMode   -  Always send 0.

Outputs:
  - *idnum   -   Returns the local ID or -1 if no LabJack is found.
  - *scanRate   -   Returns the actual scan rate, which due to clock resolution is not always exactly the same as the desired scan rate.
  - *voltages   -   Pointer to a 4096 by 4 array where voltage readings are returned. Unused locations are filled with 9999.0.
  - *stateIOout   -   Pointer to a 4096 element array where IO states are returned. Unused locations are filled with 9999.0.
  - *overVoltage   -   If >0, an overvoltage has been detected on at least one sample of one of the selected analog inputs.

=cut



void 
AIBurst(idnum,demo,stateIOin,updateIO,ledOn,channels,gains,scanRate,disableCal,triggerIO,triggerState,numScans,timeout,transferMode)
        long idnum
        long demo
        long stateIOin
        long updateIO
        long ledOn
//        int numCh             we can work this out from the size of the perl array
        SV * channels
        SV * gains
        float scanRate
        long disableCal
        long triggerIO
        long triggerState
        long numScans
        long timeout
//        SV * voltages         These are output vectors
//        SV * stateIOout
        long transferMode
    INIT:
        int i,n,j,numchannels,numgains,numCh; // ,numvoltages,numstateIOout
        long errorcode;
        long lchannels[14]; // ={0,1,2,3};
        long lgains[14];     // ={0,0,0,0};
        long ov;
        // float voltages[4]={0,0,0,0};
        float voltages[4096][4];
        long stateIOout[4096];

        // Check that they passed an array of channels, and count the elements
        if ((!SvROK(channels))
            || (SvTYPE(SvRV(channels)) != SVt_PVAV)
            || ((numchannels = av_len((AV *)SvRV(channels))) < 0))
        {
            XSRETURN_UNDEF;
        }

        // Check that they passed an array of gains, and count the elements
        if ((!SvROK(gains))
            || (SvTYPE(SvRV(gains)) != SVt_PVAV)
            || ((numgains = av_len((AV *)SvRV(gains))) < 0))
        {
            XSRETURN_UNDEF;
        }

        // Make sure there's a gain for every channel
        if(numgains<numchannels) {
            XSRETURN_UNDEF;
        }


    PPCODE:

        // Extract the channels we got from perl...
        for (n = 0; n <= numchannels; n++) {
                lchannels[n]= SvNV(*av_fetch((AV *)SvRV(channels), n, 0));
        }
        // Extract the gains we got from perl...
        for (n = 0; n <= numgains; n++) {
                lgains[n]= SvNV(*av_fetch((AV *)SvRV(gains), n, 0));
        }
        numCh=numchannels+1;

        // clear the output area
        memset(stateIOout,0,4096*sizeof(long));
        memset(voltages,0,4*4096*sizeof(float));

        // Run the command
        errorcode = AIBurst (&idnum,
                             demo,
                             stateIOin,
                             updateIO,
                             ledOn,
                             numCh,
                             lchannels,
                             lgains,
                             &scanRate,
                             disableCal,
                             triggerIO,
                             triggerState,
                             numScans,
                             timeout,
                             voltages,
                             stateIOout,
                             &ov,
                             transferMode);

        // Return the results to perl in a big array
        if(errorcode) {
          char errorString[51];
          GetErrorString ( errorcode, errorString );
          XPUSHs(sv_2mortal(newSVpv(errorString,0)));
        } else {
          XPUSHs(sv_2mortal(newSVnv(errorcode)));
        }

        XPUSHs(sv_2mortal(newSVnv(idnum)));
        XPUSHs(sv_2mortal(newSVnv(scanRate)));
        XPUSHs(sv_2mortal(newSVnv(ov)));
        for(i=0;i<numScans;i++)
          for(j=0;j<numCh;j++)
            XPUSHs(sv_2mortal(newSVnv(voltages[i][j])));
        for(i=0;i<numScans;i++)
          XPUSHs(sv_2mortal(newSVnv(stateIOout[i])));
        





#// ###########################################################################
#// NOTE:  The rest of this file from here downwards contributed by Neil, with
#// some small adjustments by Chris (see file "Changes")
#// ###########################################################################






#// ###########################################################################
#// ###########################################################################
=head
//======================================================================
// EAnalogIn: Easy function reads the voltage from 1 analog input.  Calling
//            this function turns/leaves the status LED on.
//
//      Returns:        LabJack errorcodes or 0 for no error (I32).
//      Inputs:         *idnum          -Local ID, Serial Number, or -1 for first
//                                       found (I32).
//                      demo            -Send 0 for normal operation, >0 for demo
//                                       mode (I32).  Demo mode allows this function
//                                       to be called without a LabJack, and does
//                                       little but simulate execution time.
//                      channel         -Channel command is 0-7 for SE or 8-11 for Diff.
//                      gain            -Gain command is 0=1,1=2,...,7=20.  Gain only
//                                       available for differential channels.
//      Outputs:        *idnum          -Returns the Local ID or -1 if no LabJack is
//                                       found (I32).
//                      *overVoltage    -If >0, an overvoltage has been detected
//                                       on the analog input (I32).
//                      *voltage        -Returns the voltage reading (SGL).
//
//----------------------------------------------------------------------
=cut
#// ###########################################################################
long
EAnalogIn(idnum, demo, channel, gain)
        long  idnum
        long  demo
        long  channel
        long  gain
  INIT:
        long  overVoltage;
        float voltage;
        long  errcode;

  PPCODE:
        errcode = EAnalogIn(&idnum, demo, channel, gain, &overVoltage, &voltage);

        // Return the results to perl in a big array
        if(errcode) {                                   // RETVAL
          char errorString[51];
          GetErrorString ( errcode, errorString );
          XPUSHs(sv_2mortal(newSVpv(errorString,0)));
        } else {
          XPUSHs(sv_2mortal(newSVnv(errcode)));
        }

        XPUSHs(sv_2mortal(newSVnv(idnum)));             // idnum
        XPUSHs(sv_2mortal(newSVnv(overVoltage)));       // overVoltage
        XPUSHs(sv_2mortal(newSVnv(voltage)));           // voltage








#// ###########################################################################
=head
//======================================================================
// EAnalogOut: Easy function sets the voltages of both analog outputs.
//
//      Returns:        LabJack errorcodes or 0 for no error (I32).
//      Inputs:         *idnum          -Local ID, Serial Number, or -1 for first
//                                       found (I32).
//                      demo            -Send 0 for normal operation, >0 for demo
//                                       mode (I32).  Demo mode allows this function
//                                       to be called without a LabJack, and does little
//                                       but simulate execution time.
//                      analogOut0      -Voltage from 0 to 5 for AO0 (SGL).
//                      analogOut1      -Voltage from 0 to 5 for AO1 (SGL).
//      Outputs:        *idnum          -Returns the Local ID or -1 if no LabJack is
//                                       found (I32).
//
//      Time:           20 ms
//----------------------------------------------------------------------
long _stdcall EAnalogOut(long *idnum,
                         long demo,
                         float analogOut0,
                         float analogOut1);
=cut
#// ###########################################################################
long
EAnalogOut(idnum, demo, analogOut0, analogOut1)
        long   idnum
        long   demo
        float  analogOut0
        float  analogOut1
  INIT:
        long errcode;

  PPCODE:
        errcode = EAnalogOut(&idnum, demo, analogOut0, analogOut1);

        // Return the results to perl in a big array
        if(errcode) {                                   // RETVAL
          char errorString[51];
          GetErrorString ( errcode, errorString );
          XPUSHs(sv_2mortal(newSVpv(errorString,0)));
        } else {
          XPUSHs(sv_2mortal(newSVnv(errcode)));
        }

        XPUSHs(sv_2mortal(newSVnv(idnum)));            // idnum















#// ###########################################################################
=head
//======================================================================
// ECount:      Easy function to read & reset the counter.  Calling this
//              function disables STB (which is the default anyway).
//
//      Returns:        LabJack errorcodes or 0 for no error (I32).
//      Inputs:         *idnum          -Local ID, Serial Number, or -1 for first
//                                       found (I32).
//                      demo            -Send 0 for normal operation, >0 for demo
//                                       mode (I32).  Demo mode allows this function to
//                                       be called without a LabJack, and does little but
//                                       simulate execution time.
//                      resetCounter    -If >0, the counter is reset to zero after
//                                       being read (I32).
//      Outputs:        *idnum          -Returns the Local ID or -1 if no LabJack is
//                                       found (I32).
//                      *count          -Current count, before reset.
//                      *ms             -Value of Windows millisecond timer at the
//                                       time of the counter read (within a few ms).
//                                       Note that the millisecond timer rolls over
//                                       about every 50 days.  In general, the
//                                       millisecond timer starts counting from zero
//                                       whenever the computer reboots.
//
//      Time:           20 ms
//----------------------------------------------------------------------
=cut
#// ###########################################################################

long
ECount(idnum, demo, resetCounter)
        long   idnum
        long   demo
        long   resetCounter

  INIT:
        long   errcode;
        double count;
        double ms;
  PPCODE:
        errcode = ECount(&idnum, demo, resetCounter, &count, &ms);


        // Return the results to perl in a big array
        if(errcode) {                                   // RETVAL
          char errorString[51];
          GetErrorString ( errcode, errorString );
          XPUSHs(sv_2mortal(newSVpv(errorString,0)));
        } else {
          XPUSHs(sv_2mortal(newSVnv(errcode)));
        }

        XPUSHs(sv_2mortal(newSVnv(idnum)));             // idnum
        XPUSHs(sv_2mortal(newSVnv(count)));             // count
        XPUSHs(sv_2mortal(newSVnv(ms)));                // ms

















#// ###########################################################################
=head 

SYNOPSIS

----------------------------------------------------------------------

 EDigitalIn:    Easy function reads 1 digital input.  Also configures
                the requested pin to input and leaves it that way.

                Note that this is a simplified version of the lower
                level function DigitalIO, which operates on all 20
                digital lines.  The DLL keeps track of the current
                direction and output state of all lines, so that this
                easy function can operate on a single line without
                changing the others.  When the DLL is first loaded,
                though, it does not know the direction and state of
                the lines and assumes all directions are input and
                output states are low.

----------------------------------------------------------------------
# Example perl program which calls this module -

use Device::LabJack;

$idnum = -1;

my (@results) = Device::LabJack::EDigitalIn(...)
 
print "Firware version: " . join("\n",@results) . "\n";

----------------------------------------------------------------------
INFO

        Returns:        LabJack errorcodes or 0 for no error (I32).
        Inputs:         *idnum          -Local ID, Serial Number, or -1 for first
                                         found (I32).
                        demo            -Send 0 for normal operation, >0 for demo
                                         mode (I32).  Demo mode allows this function to
                                         be called without a LabJack, and does little but
                                         simulate execution time.
                        channel         -Line to read.  0-3 for IO or 0-15 for D.
                        readD           -If >0, a D line is read instead of an IO line.
        Outputs:        *idnum          -Returns the Local ID or -1 if no LabJack is
                                         found (I32).
                        *state          -TRUE/Set if >0.  FALSE/Clear if 0.

        Time:           20 ms
----------------------------------------------------------------------
=cut
#// ###########################################################################


long
EDigitalIn(idnum, channel, readD)
        long  idnum
        long  channel
        long  readD
  INIT:
        long *i, *j, *k;
        long  errcode;
        long  state;

  PPCODE:
        errcode = EDigitalIn(&idnum, 0, channel, readD, &state);

        // Return the results to perl in a big array
        if(errcode) {
          char errorString[51];
          GetErrorString ( errcode, errorString );
          XPUSHs(sv_2mortal(newSVpv(errorString,0)));
        } else {
          XPUSHs(sv_2mortal(newSVnv(errcode)));
        }

        XPUSHs(sv_2mortal(newSVnv(idnum)));             // idnum
        XPUSHs(sv_2mortal(newSVnv(state)));             // state









#// ###########################################################################

=head
//======================================================================
// EDigitalOut: Easy function writes 1 digital output.  Also configures
//              the requested pin to output and leaves it that way.
//
//              Note that this is a simplified version of the lower
//              level function DigitalIO, which operates on all 20
//              digital lines.  The DLL keeps track of the current
//              direction and output state of all lines, so that this
//              easy function can operate on a single line without
//              changing the others.  When the DLL is first loaded,
//              though, it does not know the direction and state of
//              the lines and assumes all directions are input and
//              output states are low.
//
//      Returns:        LabJack errorcodes or 0 for no error (I32).
//      Inputs:         *idnum          -Local ID, Serial Number, or -1 for first
//                                       found (I32).
//                      demo            -Send 0 for normal operation, >0 for demo
//                                       mode (I32).  Demo mode allows this function to
//                                       be called without a LabJack, and does little but
//                                       simulate execution time.
//                      channel         -Line to write.  0-3 for IO or 0-15 for D.
//                      writeD          -If >0, a D line is written instead of an IO line.
//                      state           -TRUE/Set if >0.  FALSE/Clear if 0.
//      Outputs:        *idnum          -Returns the Local ID or -1 if no LabJack is
//                                       found (I32).
//
//      Time:           20 ms
//----------------------------------------------------------------------

long _stdcall EDigitalOut(long *idnum,
                          long demo,
                          long channel,
                          long writeD,
                          long state);

=cut
long
EDigitalOut(idnum, demo, channel, writeD, state)
        long  idnum
        long   demo
        long   channel
        long   writeD
        long   state
  CODE:
        RETVAL = EDigitalOut(&idnum, demo, channel, writeD, state);
  OUTPUT:
        RETVAL
        idnum



















#// ###########################################################################
=head
//======================================================================
// AsynchConfig:Requires firmware V1.08 or higher.
//
//		This function writes to the asynch registers and sets the
//		direction of the D lines (input/output) as needed.
//
//		The actual 1-bit time is about 1.833 plus a "full" delay (us).
//		The actual 1/2-bit time is about 1.0 plus a "half" delay (us).
//
//		full/half delay = 0.833 + 0.833C + 0.667BC + 0.5ABC
//
//		Common baud rates (full A,B,C; half A,B,C):
//			1	55,153,232	;  114,255,34
//			10	63,111,28	;  34,123,23
//			100	51,191,2  	;  33,97,3
//			300	71,23,4  	;  84,39,1
//			600	183,3,6  	;  236,7,1
//			1000	33,29,2  	;  123,8,1
//			1200	23,17,4  	;  14,54,1
//			2400	21,37,1  	;  44,3,3
//			4800	10,18,2  	;  1,87,1
//			7200	134,2,1  	;  6,9,2
//			9600	200,1,1  	;  48,2,1
//			10000	63,3,1  	;  46,2,1
//			19200	96,1,1  	;  22,2,1
//			38400	3,5,2  		;  9,2,1
//			57600	3,3,2  		;  11,1,1
//			100000	3,3,1  		;  1,2,1
//			115200	9,1,1  		;  2,1,1 or 1,1,1
//
//				
//		When using data rates over 38.4 kbps, the following conditions
//		need to be considered:
//		-When reading the first byte, the start bit is first tested
//		 about 11.5 us after the start of the tx stop bit.
//		-When reading bytes after the first, the start bit is first
//		 tested about "full" + 11 us after the previous bit 8 read,
//		 which occurs near the middle of bit 8.
//
//		When enabled, STB does the following to aid in debugging
//		asynchronous reads:
//		-STB is set about 6 us after the start of the last tx stop bit, or
//		 about "full" + 6 us after the previous bit 8 read.
//		-STB is cleared about 0-2 us after the rx start bit is detected.
//		-STB is set after about "half".
//		-STB is cleared after about "full".
//		-Bit 0 is read about 1 us later.
//		-STB is set about 1 us after the bit 0 read.
//		-STB is cleared after about "full".
//		-Bit 1 is read about 1 us later.
//		-STB is set about 1 us after the bit 1 read.
//		-STB is cleared after about "full".
//		-This continues for all 8 data bits and the stop bit, after
//		 which STB remains low.
//
//
//	Returns:	LabJack errorcodes or 0 for no error (I32).
//	Inputs:		*idnum		-Local ID, Serial Number, or -1 for first
//					 found (I32).
//			demo		-Send 0 for normal operation, >0 for demo
//					 mode (I32).  Demo mode allows this function to
//					 be called without a LabJack, and does little but
//					 simulate execution time.
//			timeoutMult	-If enabled, read timeout is about 100
//					 milliseconds times this value (I32, 0-255).
//			configA		-If >0, D8 is set to output-high and D9 is set to
//					 input (I32).
//			configB		-If >0, D10 is set to output-high and D11 is set to
//					 input (I32).
//			configTE	-If >0, D12 is set to output-low (I32).
//			fullA		-A time value for a full bit (I32, 1-255).
//			fullB		-B time value for a full bit (I32, 1-255).
//			fullC		-C time value for a full bit (I32, 1-255).
//			halfA		-A time value for a half bit (I32, 1-255).
//			halfB		-B time value for a half bit (I32, 1-255).
//			halfC		-C time value for a half bit (I32, 1-255).
//	Outputs:	*idnum		-Returns the Local ID or -1 if no LabJack is
//					 found (I32).
//
//	Time:		60 ms
//----------------------------------------------------------------------
=cut
#// ###########################################################################
long
AsynchConfig(idnum, demo, timeoutMult,configA,configB,configTE,fullA,fullB,fullC,halfA,halfB,halfC)
	long idnum
	long demo
	long timeoutMult
	long configA
	long configB
	long configTE
	long fullA
	long fullB
	long fullC
	long halfA
	long halfB
	long halfC
  CODE:
	RETVAL = AsynchConfig(&idnum, demo, timeoutMult,configA,configB,configTE,fullA,fullB,fullC,halfA,halfB,halfC);
  OUTPUT:
	idnum
        RETVAL

#// ###########################################################################
=head
//======================================================================
// Asynch:	Requires firmware V1.05 or higher.
//
//		This function writes and then reads half-duplex asynchronous
//		data on 1 of two pairs of D lines (8,n,1).  Call AsynchConfig
//		to set the baud rate.  Similar to RS232, except that logic is
//		normal CMOS/TTL (0=low=GND, 1=high=+5V, idle state of
//		transmit line is high).  Connection to a normal RS232 device
//		will probably require a converter chip such as the MAX233.
//
//		PortA =>  TX is D8 and RX is D9
//		PortB =>  TX is D10 and RX is D11
//		Transmit Enable is D12
//
//		Up to 18 bytes can be written and read.  If more than 4 bytes
//		are written or read, this function uses calls to
//		WriteMem/ReadMem to load/read the LabJack's data buffer.
//
//	Returns:	LabJack errorcodes or 0 for no error (I32).
//	Inputs:		*idnum		-Local ID, Serial Number, or -1 for first
//					 found (I32).
//			demo		-Send 0 for normal operation, >0 for demo
//					 mode (I32).  Demo mode allows this function to
//					 be called without a LabJack, and does little but
//					 simulate execution time.
//			portB		-If >0, asynch PortB is used instead of PortA.
//			enableTE	-If >0, D12 (Transmit Enable) is set high during
//					 transmit and low during receive (I32).
//			enableTO	-If >0, timeout is enabled for the receive phase (per byte).
//			enableDel	-If >0, a 1 bit delay is inserted between each
//					 transmit byte.
//			baudrate	-This is the bps as set by AsynchConfig.  Asynch needs this
//					 so it has an idea how long the transfer should take.
//			numWrite	-Number of bytes to write (I32, 0-18).
//			numRead		-Number of bytes to read (I32, 0-18).
//			*data		-Serial data buffer.  Send an 18 element
//					 array.  Fill unused locations with zeros (I32).
//	Outputs:	*idnum		-Returns the Local ID or -1 if no LabJack is
//					 found (I32).
//			*data		-Serial data buffer.  Returns any serial read
//					 data.  Unused locations are filled
//					 with 9999s. (I32).
//
//	Time:		20 ms to read & write up to 4 bytes, plus 40 ms for each
//			additional 4 bytes to read or write.  Possibly extra
//			time for slow baud rates.
//----------------------------------------------------------------------

	#// cnd: WARNING: The &data below is NOT TESTED //
	#// cnd: WARNING: this probably does not return stuff? //

=cut
#// ###########################################################################
long
Asynch(idnum,demo,portB,enableTE,enableTO,enableDel,baudrate,numWrite,numRead,data)
	long idnum
	long demo
	long portB
	long enableTE
	long enableTO
	long enableDel
	long baudrate
	long numWrite
	long numRead
	long data
  INPUT:
  CODE:
	RETVAL = Asynch(&idnum,demo,portB,enableTE,enableTO,enableDel,baudrate,numWrite,numRead,&data);
  OUTPUT:
	idnum
	data
	RETVAL









=head
//======================================================================
// AIBurst: Reads a certain number of scans at a certain scan rate
//	    from 1,2, or 4 analog inputs.  First, data is acquired and
//	    stored in the LabJacks 4096 sample RAM buffer.  Then, the
//	    data is transferred to the PC application.
//
//	Returns:	LabJack errorcodes or 0 for no error (I32).
//	Inputs:		*idnum		-Local ID, Serial Number, or -1 for first
//					 found (I32).
//			demo		-Send 0 for normal operation, >0 for demo
//					 mode (I32).  Demo mode allows this function
//					 to be called without a LabJack, and does little
//					 but simulate execution time.
//			stateIOin	-Output states for IO0-IO3 (I32).
//			updateIO	-If >0, state values will be written.  Otherwise,
//					 just reads are performed (I32).
//			ledOn		-If >0, the LabJack LED is turned on (I32).
//			numChannels	-Number of channels.  1, 2, or 4 (I32).
//			*channels	-Pointer to an array of channel commands with at
//					 least numChannels elements (I32).  Each channel
//					 command is 0-7 for SE or 8-11 for Diff.
//			*gains		-Pointer to an array of gain commands with at
//					 least numChannels elements (I32).  Gain
//					 commands are 0=1,1=2,...,7=20.  Gain only
//					 available for differential channels.
//			*scanRate	-Scans acquired per second (SGL).  A scan is a
//					 reading from every channel (1,2, or 4).  The
//					 sample rate (scanRate*numChannels) must
//					 be 400-8192.
//			disableCal	-If >0, voltages returned will be raw readings
//					 that are not corrected using calibration
//					 constants (I32).
//			triggerIO	-Set the IO port to trigger on.  0=none,
//					 1=IO0,...,4=IO3 (I32).
//			triggerState	-If >0, the acquisition will be triggered
//					 when the selected IO port reads high (I32).
//			numScans	-Number of scans which will be collected (I32).
//					 Minimum is 1.  Maximum numSamples is 4096 where
//					 numSamples is numScans * numChannels.
//			timeout		-Function timeout value in seconds (I32).
//			*voltages	-Voltage readings buffer.  Send a 4096 by 4
//					 element array of zeros (SGL).
//			*stateIOout	-IO state readings buffer.  Send a 4096 element
//					 array of zeros (I32).
//			transferMode	-0=auto,1=normal,2=turbo (I32)
//	Outputs:	*idnum		-Returns the Local ID or -1 if no LabJack is
//					 found (I32).
//			*scanRate	-Returns the actual scan rate, which due to
//					 clock resolution is not always exactly the
//					 same as the desired scan rate (SGL).
//			*voltages	-Voltage readings are returned in this 4096 by
//					 4 array (SGL). Unused locations are filled
//					 with 9999s.
//			*stateIOout	-The states of all 4 IO are returned in this
//					 array (I32).  Unused locations are filled
//					 with 9999s.
//			*overVoltage	-If >0, an overvoltage has been detected on
//					 at least one sample of at least one of the
//					 analog inputs (I32).
//
//	Time:	The execution time of this function, in milliseconds, can be
//		estimated with the below formulas.  The actual number of scans
//		collected and transferred by the LabJack is the smallest power
//		of 2 from 64 to 4096 which is at least as big as numScans.  This
//		is represented below as numScansActual.
//		Normal => 30+(1000*numScansActual/scanRate)+(2.5*numScansActual)
//		Turbo  => 30+(1000*numScansActual/scanRate)+(0.4*numScansActual)
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
=cut
#// ###########################################################################

#// ###########################################################################
=head
//======================================================================
// AIStreamStart: Starts a hardware timed continuous acquisition where data
//		  is sampled and stored in the LabJack RAM buffer, and
//		  simultaneously transferred out of the RAM buffer to the
//		  PC application.  A call to this function should be
//		  followed by periodic calls to AIStreamRead, and eventually
//		  a call to AIStreamClear.
//
//	Returns:	LabJack errorcodes or 0 for no error (I32).
//	Inputs:		*idnum		-Local ID, Serial Number, or -1 for first
//					 found (I32).
//			demo		-Send 0 for normal operation, >0 for demo
//					 mode (I32).  Demo mode allows this function
//					 to be called without a LabJack, and does little
//					 but simulate execution time.
//			stateIOin	-Output states for IO0-IO3 (I32).
//			updateIO	-If >0, state values will be written.  Otherwise,
//					 just reads are performed (I32).
//			ledOn		-If >0, the LabJack LED is turned on (I32).
//			numChannels     -Number of channels.  1, 2, or 4 (I32).  If
//					 readCount is >0, numChannels should be 4.
//			*channels	-Pointer to an array of channel commands with at
//					 least numChannels elements (I32).  Each channel
//					 command is 0-7 for SE or 8-11 for Diff.
//			*gains		-Pointer to an array of gain commands with at
//					 least numChannels elements (I32).  Gain commands
//					 are 0=1,1=2,...,7=20.  Gain only available for
//					 differential channels.
//			*scanRate	-Scans acquired per second (SGL).  A scan is a
//					 reading from every channel (1,2, or 4).  The
//					 sample rate (scanRate*numChannels) must
//					 be 200-1200.
//			disableCal	-If >0, voltages returned will be raw readings
//					 that are not corrected using calibration
//					 constants (I32).
//			reserved1	-Reserved for future use.  Send 0 (I32).
//			readCount	-If >0, the counter read is returned instead of
//					 the 2nd, 3rd, and 4th channel (I32).  2nd
//					 channel is bits 0-11, 3rd channel is bits
//					 12-23, and 4th channel is bits 24-31.
//					 Only works with firmware V1.03 or higher.
//	Outputs:	*idnum		-Returns the Local ID or -1 if no LabJack is
//					 found (I32).
//			*scanRate	-Returns the actual scan rate, which due to clock
//					 resolution is not always exactly the same as the
//					 desired scan rate (SGL).
//----------------------------------------------------------------------
long _stdcall AIStreamStart(	long *idnum,
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
=cut
#// ###########################################################################

#// ###########################################################################
=head
//======================================================================
// AIStreamRead: Waits for a specified number of scans to be available and
//		 reads them.  AIStreamStart should be called before this
//		 function and AIStreamClear should be called when finished.
//
//	Returns:	LabJack errorcodes or 0 for no error (I32).
//	Inputs:		localID		-Send the local ID from AIStreamStart (I32).
//			numScans	-Function will wait until this number of scans is
//					 available (I32).  Minimum is 1.  Maximum
//					 numSamples is 4096 where numSamples is
//					 equal to numScans * numChannels.  Internally,
//					 this function gets data from the LabJack in
//					 blocks of 64 samples, so it is recommended that
//					 numSamples be at least 64.
//			timeout		-Function timeout value in seconds (I32).
//			*voltages	-Voltage readings buffer.  Send a 4096 by 4
//					 element array of zeros (SGL).
//			*stateIOout	-IO state readings buffer.  Send a 4096 element
//					 array of zeros (I32).
//	Outputs:	*voltages	-Voltage readings are returned in this 4096 by 4
//					 array (SGL).  Unused locations are filled
//					 with 9999s.
//			*stateIOout	-The states of all 4 IO are returned in this
//					 array (I32).  Unused locations are filled
//					 with 9999s.
//			*reserved	-Reserved for future use (I32).
//			*ljScanBacklog	-Returns the scan backlog of the LabJack RAM
//					 buffer (I32).
//			*overVoltage	-If >0, an overvoltage has been detected on
//					 at least one sample of at least one of the
//					 analog inputs (I32).
//----------------------------------------------------------------------
long _stdcall AIStreamRead(	long localID,
				long numScans,
				long timeout,
				float (*voltages)[4],
				long *stateIOout,
				long *reserved,
				long *ljScanBacklog,
				long *overVoltage);
=cut
#// ###########################################################################

#// ###########################################################################
=head
//======================================================================
// AIStreamClear:  This function stops the continuous acquisition.  It
//		   should be called after AIStreamStart and after any
//		   calls to AIStreamRead.
//
//	Returns:	LabJack errorcodes or 0 for no error (I32).
//	Inputs:		localID		-Send the local ID from AIStreamStart/Read (I32).
//	Outputs:	none
//----------------------------------------------------------------------
long _stdcall AIStreamClear(long localID);
=cut
#// ###########################################################################







#// ###########################################################################
#//		BitsToVolts
=head BitsToVolts

SYNOPSIS

INFO

 BitsToVolts:	Converts a 12-bit (0-4095) binary value into a LabJack
		voltage.  Volts=((2*Bits*Vmax/4096)-Vmax)/Gain where
		Vmax=10 for SE, 20 for Diff.

Declaration:

long _stdcall BitsToVolts (long chnum,
			   long chgain,
			   long bits,
			   float *volts);

Paramter description
	Returns:	LabJack errorcodes or 0 for no error (I32).

	Inputs:		chnum		-Channel index.  0-7=SE, 8-11=Diff (I32).
			chgain		-Gain index.  0=1,1=2,...,7=20 (I32).
			bits		-Binary value from 0-4095 (I32).
	Outputs:	*volts		-Voltage.  SE=+/-10, Diff=+/-20 (SGL).

=cut
#// ###########################################################################

float
BitsToVolts(chnum, chgain, bits)
    long    chnum
    long    chgain
    long    bits

  INIT:
    long errcode;
    float volts;

  PPCODE:
    errcode = BitsToVolts(chnum, chgain, bits, &volts);

    // Return the results to perl in a big array
    if(errcode) {
        char errorString[51];
        GetErrorString ( errcode, errorString );
        XPUSHs(sv_2mortal(newSVpv(errorString,0)));
    } else {
        XPUSHs(sv_2mortal(newSVnv(errcode)));
    }

    XPUSHs(sv_2mortal(newSVnv(volts)));

#// ###########################################################################
#//		VoltsToBits
=head VoltsToBits

SYNOPSIS

INFO

Declaration:

Paramter description

=cut

#// ###########################################################################

int
VoltsToBits(chnum, chgain, volts)
    long   chnum
    long   chgain
    float  volts

 INIT:
    long errcode;

    long   bits;
  PPCODE:
    errcode = VoltsToBits(chnum, chgain, volts, &bits);

    // Return the results to perl in a big array
    if(errcode) {
        char errorString[51];
        GetErrorString ( errcode, errorString );
        XPUSHs(sv_2mortal(newSVpv(errorString,0)));
    } else {
        XPUSHs(sv_2mortal(newSVnv(errcode)));
    }

    XPUSHs(sv_2mortal(newSVnv(bits)));

#// ###########################################################################
#//		Counter
=head Counter

SYNOPSIS

INFO

 Counter:	Controls and reads the counter.  The counter is disabled if
		the watchdog timer is enabled.

Declaration:
long _stdcall Counter(long *idnum,
		      long demo,
		      long *stateD,
		      long *stateIO,
		      long resetCounter,
		      long enableSTB,
		      unsigned long *count);

Paramter description

	Returns:LabJack errorcodes or 0 for no error (I32).

	Inputs:	*idnum		-Local ID, Serial Number, or -1 for first
				 found (I32).
		demo		-Send 0 for normal operation, >0 for demo
				 mode (I32).  Demo mode allows this function to
				 be called without a LabJack, and does little but
				 simulate execution time.
		resetCounter	-If >0, the counter is reset to zero after
				 being read (I32).
		enableSTB	-If >0, STB is enabled (I32).  Only works with
				 firmware V1.02 or later.
	Outputs:*idnum		-Returns the Local ID or -1 if no LabJack is
				 found (I32).
		*stateD		-States of D0-D15 (I32).
		*stateIO	-States of IO0-IO3 (I32).
		*count		-Current count, before reset (U32).

=cut
#


int
Counter(idnum, demo, stateD, stateIO, resetCounter, enableSTB, count)
    long   idnum
    long    demo
    long   stateD
    long   stateIO
    long    resetCounter
    long    enableSTB

    unsigned long  count

   INIT:
//    long *j, *k, x;
    long errcode;
//    int  nstateD;
//    unsigned long *mycount;

    // Check that they passed an array of channels, and count the elements

    PPCODE:
        // Run the command
        errcode = Counter(&idnum, demo, &stateD, &stateIO, resetCounter, enableSTB, &enableSTB);

        // Return the results to perl in a big array
        if(errcode) {
          char errorString[51];
          GetErrorString ( errcode, errorString );
          XPUSHs(sv_2mortal(newSVpv(errorString,0)));
        } else {
          XPUSHs(sv_2mortal(newSVnv(errcode)));
        }

        XPUSHs(sv_2mortal(newSVnv(idnum)));
        XPUSHs(sv_2mortal(newSVnv(stateD)));
        XPUSHs(sv_2mortal(newSVnv(stateIO)));
        XPUSHs(sv_2mortal(newSVnv(count)));

#// ###########################################################################
=head
//======================================================================
// DigitalIO:	Reads and writes to the digital I/O.
//
//	Returns:	LabJack errorcodes or 0 for no error (I32).
//	Inputs:		*idnum		-Local ID, Serial Number, or -1 for first
//					 found (I32).
//			demo		-Send 0 for normal operation, >0 for demo
//					 mode (I32).  Demo mode allows this function to
//					 be called without a LabJack, and does little but
//					 simulate execution time.
//			*trisD		-Directions for D0-D15.  0=Input, 1=Output (I32).
//			trisIO		-Directions for IO0-IO3.  0=Input, 1=Output (I32).
//			*stateD		-Output states for D0-D15 (I32).
//			*stateIO	-Output states for IO0-IO3 (I32).
//			updateDigital	-If >0, tris and state values will be written.
//					 Otherwise, just a read is performed (I32).
//	Outputs:	*idnum		-Returns the Local ID or -1 if no LabJack is
//					 found (I32).
//			*trisD		-Returns a read of the direction registers
//					 for D0-D15 (I32).
//			*stateD		-States of D0-D15 (I32).
//			*stateIO	-States of IO0-IO3 (I32).
//			*outputD	-Returns a read of the output registers
//					 for D0-D15 (I32).
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
=cut
#// ###########################################################################
long
DigitalIO(idnum, demo, trisD, trisIO, stateD, stateIO, updateDigital)
	long  idnum
	long   demo
	long  trisD
	long   trisIO
	long  stateD
	long  stateIO
	long   updateDigital
  INIT:
	long  *i, *j, *k, *l, *m;
	long   errcode;	
	long   outputD;

	i = &idnum;
	j = &trisD;
	k = &stateD;
	l = &stateIO;
	m = &outputD;

  PPCODE:
	errcode = DigitalIO(i, demo, j, trisIO, k, l, updateDigital, m);

        // Return the results to perl in a big array
        if(errcode) {
          char errorString[51];
          GetErrorString ( errcode, errorString );
          XPUSHs(sv_2mortal(newSVpv(errorString,0)));
        } else {
          XPUSHs(sv_2mortal(newSVnv(errcode)));
        }

        XPUSHs(sv_2mortal(newSVnv(idnum)));
        XPUSHs(sv_2mortal(newSVnv(trisD)));
        XPUSHs(sv_2mortal(newSVnv(stateD)));
        XPUSHs(sv_2mortal(newSVnv(stateIO)));
        XPUSHs(sv_2mortal(newSVnv(outputD)));

#// ###########################################################################
=head
//======================================================================
//GetDriverVersion
//
//	Returns:	Version number of this DLL (SGL).
//	Inputs:		none
//	Outputs:	none
//----------------------------------------------------------------------
float _stdcall GetDriverVersion(void);
=cut
#// ###########################################################################

float
GetDriverVersion()
  CODE:
	RETVAL = GetDriverVersion();
  OUTPUT:
	RETVAL

#// ###########################################################################
=head
//======================================================================
//GetErrorString
//
//	Returns:	nothing
//  	Inputs:		errorcode	-LabJack errorcode (I32)
//			*errorString	-Must point to an array of at least 50
//					 chars (I8).
//	Outputs:	*errorString	-A sequence a characters describing the error
//					 will be copied into the char (I8) array.
//----------------------------------------------------------------------
void _stdcall GetErrorString	(long errorcode,
				 char *errorString);
=cut
#// ###########################################################################
void
GetErrorString(errn);
	long  errn
  INIT:
	char str[255];
  PPCODE:
	GetErrorString ( errn, str );
	XPUSHs(sv_2mortal(newSVpv(str,0)));

#// ###########################################################################
=head
//======================================================================
//GetWinVersion:  Uses a Windows API function to get the OS version.
//
//	Returns:	LabJack errorcodes or 0 for no error (I32).
//	Inputs:		none
//
//	Outputs: (U32)
//				Platform	Major	Minor	Build
//	Windows 3.1		 0		  -	  -	   -
//	Windows 95		 1		  4	  0	  950
//	Windows 95 OSR2		 1		  4	  0	 1111
//	Windows 98		 1		  4	 10	 1998
//	Windows 98SE		 1		  4	 10	 2222
//	Windows Me		 1		  4	 90	 3000
//	Windows NT 3.51		 2		  3	 51	   -
//	Windows NT 4.0		 2		  4	  0	 1381
//	Windows 2000		 2		  5	  0	 2195
//	Whistler		 2		  5	  1	   -
//----------------------------------------------------------------------
long _stdcall GetWinVersion(unsigned long *majorVersion,
			    unsigned long *minorVersion,
			    unsigned long *buildNumber,
			    unsigned long *platformID,
			    unsigned long *servicePackMajor,
			    unsigned long *servicePackMinor);
=cut
#// ###########################################################################
long
GetWinVersion()
  INIT:
	unsigned long maj, min, build, platform, Packmaj, Packmin;
	long errcode;
  PPCODE:
	errcode = GetWinVersion(&maj, &min, &build, &platform, &Packmaj, &Packmin);

        // Return the results to perl in a big array
        if(errcode) {
          char errorString[51];
          GetErrorString ( errcode, errorString );
          XPUSHs(sv_2mortal(newSVpv(errorString,0)));
          XPUSHs(sv_2mortal(newSVnv(errcode)));
        } else {
          XPUSHs(sv_2mortal(newSVnv(errcode)));
        }

        XPUSHs(sv_2mortal(newSVnv(maj)));
        XPUSHs(sv_2mortal(newSVnv(min)));
        XPUSHs(sv_2mortal(newSVnv(build)));
        XPUSHs(sv_2mortal(newSVnv(platform)));
        XPUSHs(sv_2mortal(newSVnv(Packmaj)));
        XPUSHs(sv_2mortal(newSVnv(Packmin)));








#// ###########################################################################
=head
//======================================================================
// ListAll: Searches the USB for all LabJacks.
//
//	Returns:	LabJack errorcodes or 0 for no error (I32).
//	Inputs:		*productIDList	-Send a 127 element array of zeros (I32).
//			*serialnumList	-Send a 127 element array of zeros (I32).
//			*localIDList	-Send a 127 element array of zeros (I32).
//			*powerList	-Send a 127 element array of zeros (I32).
//			*calMatrix	-Send a 127 by 20 element array of
//					 zeros (I32).
//	Outputs:	*productIDList	-Returns the product ID for each LabJack on
//					 the USB (I32).  Unused elements filled
//					 with 9999s.
//			*serialnumList	-Returns the serial number for each LabJack
//					 on the USB (I32).  Unused elements filled
//					 with 9999s.
//			*localIDList	-Returns the local ID for each LabJack on
//					 the USB (I32).  Unused elements filled
//					 with 9999s.
//			*powerList	-Returns the power allowance for each LabJack
//					 on the USB (I32).  Unused elements filled
//					 with 9999s.
//			*calMatrix	-Returns the cal constants for each LabJack
//					 on the USB (I32).  Unused elements filled
//					 with 9999s.
//			*numberFound	-Number of LabJacks found on the USB (I32).
//			*fcddMaxSize	-Max size of fcdd (I32).
//			*hvcMaxSize	-Max size of hvc (I32).
//----------------------------------------------------------------------
long _stdcall ListAll(long *productIDList,
		      long *serialnumList,
		      long *localIDList,
		      long *powerList,
		      long (*calMatrix)[20],
		      long *numberFound,
		      long *fcddMaxSize,
		      long *hvcMaxSize);
=cut
#// ###########################################################################

#// ###########################################################################
=head
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
=cut
#// ###########################################################################
long
LocalID(idnum,localID)
	long idnum
	long localID
  CODE:
	RETVAL = LocalID(&idnum, localID);
  OUTPUT:
	RETVAL
	idnum

#// ###########################################################################
=head
//======================================================================
// NoThread:  Use this function to disable/enable (enabled by default)
//            thread creation when this DLL reads data from a particular
//		  LabJack.  If noThread is TRUE, it also sends a dummy write
//		  followed by a dummy write/read to initialize that LabJack,
//		  since in normal operation the LabJack does not respond to
//		  the first command after reset/enumeration.
//
//		  Normally, the DLL creates a thread when it attempts to
//		  read data from the LabJack.  This way, if something goes
//		  wrong, the thread can be terminated after a timeout
//		  period rather than the the program just getting stuck
//		  while it waits for a read that might never complete.
//		  This would happen if Windows thinks the LabJack is
//		  present and operating correctly, but the LabJack does
//		  not send data, or Windows doesn't realize the LabJack
//		  has sent data.  We are not sure if this is possible, but
//		  just to be safe we normally lauch the read in a thread
//		  that can be terminated after a timeout period.
//
//		  We have found 2 situations where creating the thread
//		  causes a problem:
//		  1.  When using TestPoint on Windows 98SE (and ME?),
//		      the Windows API call CreateThread cannot be used
//			  in a DLL that is being interfaced.
//		  2.  In VC, creating a thread is very slow in the
//			  debugger.  If you call a function like AISample
//			  while in the debugger, it might take 200 ms to
//			  execute instead of 20 ms.
//
//		  If you fall into case #1 above, or if case #2 is too
//		  slow for your VC debugging needs, you should call this
//		  function, NoThread, before calling any other LabJack
//		  functions.  NoThread must be called first thing any
//		  time the LabJack enumerates.  If you use NoThread, but
//		  are concerned about your program getting stuck, you
//		  can use the Watchdog function to configure the LabJack
//		  to reset if it does not communicate with the PC within
//		  a given time.  When the LabJack resets, the read
//		  function should stop waiting for data and return
//		  an error.
//
//		  If the read thread is disabled, the "timeout"
//		  specified in AIBurst and AIStreamRead is also disabled.
// 
//
//	Returns:	LabJack errorcodes or 0 for no error (I32).
//	Inputs:		*idnum		-Local ID, Serial Number, or -1 for first
//					 found (I32).
//			noThread	-If >0, the thread will not be used (I32).
//	Outputs:	*idnum		-Returns the Local ID or -1 if no LabJack is
//					 found (I32).
//
//	Time:		80 ms
//----------------------------------------------------------------------
long _stdcall NoThread(long *idnum, long noThread);
=cut
#// ###########################################################################
long
NoThread(idnum,noThread)
	long idnum
	long noThread
  CODE:
	RETVAL = NoThread(&idnum,noThread);
  OUTPUT:
	RETVAL
	idnum

#// ###########################################################################
=head
//======================================================================
// PulseOut:	Requires firmware V1.05 or higher.
//
//		The timeout of this function, in milliseconds, is set to:
//		5000+numPulses*((B1*C1*0.02)+(B2*C2*0.02))
//
//		This command creates pulses on any/all of D0-D7.  The
//		desired D lines must be set to output using another
//		function (DigitalIO or AOUpdate).  All selected lines
//		are pulsed at the same time, at the same rate, for the
//		same number of pulses.
//
//		This function commands the time for the first half cycle
//		of each pulse, and the second half cycle of each pulse.
//		Each time is commanded by sending a value B & C, where
//		the time is,
//
//		1st half-cycle microseconds = ~17 + 0.83*C + 20.17*B*C
//		2nd half-cycle microseconds = ~12 + 0.83*C + 20.17*B*C
//
//		which can be approximated as,
//
//			microseconds = 20*B*C
//
//		For best accuracy when using the approximation, minimize C.
//		B and C must be between 1 and 255, so each half cycle can
//		vary from about 38/33 microseconds to just over 1.3 seconds.
//
//		If you have enabled the LabJack Watchdog function, make sure
//		it's timeout is longer than the time it takes to output all
//		pulses.
//
//	Returns:	LabJack errorcodes or 0 for no error (I32).
//	Inputs:		*idnum		-Local ID, Serial Number, or -1 for first
//					 found (I32).
//			demo		-Send 0 for normal operation, >0 for demo
//					 mode (I32).  Demo mode allows this function to
//					 be called without a LabJack, and does little but
//					 simulate execution time.
//			lowFirst	-If >0, each line is set low then high, otherwise
//					 the lines are set high then low (I32).
//			bitSelect	-Set bits 0 to 7 to enable pulsing on each of
//					 D0-D7 (I32, 0-255).
//			numPulses	-Number of pulses for all lines (I32, 1-32767).
//			timeB1		-B value for first half cycle (I32, 1-255).
//			timeC1		-C value for first half cycle (I32, 1-255).
//			timeB2		-B value for second half cycle (I32, 1-255).
//			timeC2		-C value for second half cycle (I32, 1-255).
//	Outputs:	*idnum		-Returns the Local ID or -1 if no LabJack is
//					 found (I32).
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
=cut
#// ###########################################################################
long
PulseOut(idnum,demo,lowFirst,bitSelect,numPulses,timeB1, timeC1,timeB2,timeC2)
	long idnum
	long demo
	long lowFirst
	long bitSelect
	long numPulses
	long timeB1
	long timeC1
	long timeB2
	long timeC2
  CODE:
	RETVAL = PulseOut(idnum,demo,lowFirst,bitSelect,numPulses,timeB1, timeC1,timeB2,timeC2);
  OUTPUT:
	RETVAL
	idnum

#// ###########################################################################
=head
//======================================================================
// PulseOutStart:	Requires firmware V1.07 or higher.
//
//			PulseOutStart and PulseOutFinish are used as an
//			alternative to PulseOut.  PulseOutStart starts the
//			pulse output and returns without waiting for the
//			finish.  PulseOutFinish waits for the LabJack's
//			response which signifies the end of the pulse
//			output.  If anything besides PulseOutFinish is
//			called after PulseOutStart, the pulse output
//			will be terminated and the LabJack will execute
//			the new command.  
//
//			Note that due to boot-up tests on the LabJack
//			U12, if PulseOutStart is the first command sent
//			to the LabJack after reset or power-up, there
//			would be no response for PulseOutFinish.  In
//			practice, even if no precautions were taken, this
//			would probably never happen, since before calling
//			PulseOutStart a call is needed to set the desired
//			D lines to output.
//
//			Also note that PulseOutFinish must be called before
//			the LabJack completes the pulse output to read the
//			response.  If PulseOutFinish is not called until
//			after the LabJack sends it's response, the function
//			will never receive the response and will timeout.
//
//			This command creates pulses on any/all of D0-D7.  The
//			desired D lines must be set to output using another
//			function (DigitalIO or AOUpdate).  All selected lines
//			are pulsed at the same time, at the same rate, for the
//			same number of pulses.
//
//			This function commands the time for the first half cycle
//			of each pulse, and the second half cycle of each pulse.
//			Each time is commanded by sending a value B & C, where
//			the time is,
//
//			1st half-cycle microseconds = ~17 + 0.83*C + 20.17*B*C
//			2nd half-cycle microseconds = ~12 + 0.83*C + 20.17*B*C
//
//			which can be approximated as,
//
//				microseconds = 20*B*C
//
//			For best accuracy when using the approximation, minimize C.
//			B and C must be between 1 and 255, so each half cycle can
//			vary from about 38/33 microseconds to just over 1.3 seconds.
//
//			If you have enabled the LabJack Watchdog function, make sure
//			it's timeout is longer than the time it takes to output all
//			pulses.
//
//	Returns:	LabJack errorcodes or 0 for no error (I32).
//	Inputs:		*idnum		-Local ID, Serial Number, or -1 for first
//					 found (I32).
//			demo		-Send 0 for normal operation, >0 for demo
//					 mode (I32).  Demo mode allows this function to
//					 be called without a LabJack, and does little but
//					 simulate execution time.
//			lowFirst	-If >0, each line is set low then high, otherwise
//					 the lines are set high then low (I32).
//			bitSelect	-Set bits 0 to 7 to enable pulsing on each of
//					 D0-D7 (I32, 0-255).
//			numPulses	-Number of pulses for all lines (I32, 1-32767).
//			timeB1		-B value for first half cycle (I32, 1-255).
//			timeC1		-C value for first half cycle (I32, 1-255).
//			timeB2		-B value for second half cycle (I32, 1-255).
//			timeC2		-C value for second half cycle (I32, 1-255).
//	Outputs:	*idnum		-Returns the Local ID or -1 if no LabJack is
//					 found (I32).
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
=cut
#// ###########################################################################
long
PulseOutStart(idnum,demo,lowFirst,bitSelect,numPulses,timeB1, timeC1,timeB2,timeC2)
	long idnum
	long demo
	long lowFirst
	long bitSelect
	long numPulses
	long timeB1
	long timeC1
	long timeB2
	long timeC2
  CODE:
	RETVAL = PulseOutStart(&idnum,demo,lowFirst,bitSelect,numPulses,timeB1, timeC1,timeB2,timeC2);
  OUTPUT:
	RETVAL
	idnum

#// ###########################################################################
=head
//======================================================================
// PulseOutFinish:	Requires firmware V1.07 or higher.
//
//			PulseOutStart and PulseOutFinish are used as an
//			alternative to PulseOut.  PulseOutStart starts the
//			pulse output and returns without waiting for the
//			finish.  PulseOutFinish waits for the LabJack's
//			response which signifies the end of the pulse
//			output.  If anything besides PulseOutFinish is
//			called after PulseOutStart, the pulse output
//			will be terminated and the LabJack will execute
//			the new command.  
//
//			Note that due to boot-up tests on the LabJack
//			U12, if PulseOutStart is the first command sent
//			to the LabJack after reset or power-up, there
//			would be no response for PulseOutFinish.  In
//			practice, even if no precautions were taken, this
//			would probably never happen, since before calling
//			PulseOutStart a call is needed to set the desired
//			D lines to output.
//
//			Also note that PulseOutFinish must be called before
//			the LabJack completes the pulse output to read the
//			response.  If PulseOutFinish is not called until
//			after the LabJack sends it's response, the function
//			will never receive the response and will timeout.
//
//	Returns:	LabJack errorcodes or 0 for no error (I32).
//	Inputs:		*idnum		-Local ID, Serial Number, or -1 for first
//					 found (I32).
//			demo		-Send 0 for normal operation, >0 for demo
//					 mode (I32).  Demo mode allows this function to
//					 be called without a LabJack, and does little but
//					 simulate execution time.
//			timeoutMS	-Amount of time, in milliseconds, that this
//					 function will wait for the Pulseout response (I32).
//	Outputs:	*idnum		-Returns the Local ID or -1 if no LabJack is
//					 found (I32).
//
//----------------------------------------------------------------------
long _stdcall PulseOutFinish	(long *idnum,
				 long demo,
				 long timeoutMS);
=cut
#// ###########################################################################
long
PulseOutFinish(idnum,demo,timeoutMS)
	long idnum
	long demo
	long timeoutMS
  CODE:
	RETVAL = PulseOutFinish(&idnum,demo,timeoutMS);
  OUTPUT:
	RETVAL
	idnum

#// ###########################################################################
=head
//======================================================================
// PulseOutCalc:
//
//			This function can be used to calculate the cycle times
//			for PulseOut or PulseOutStart.
//
//	Returns:	LabJack errorcodes or 0 for no error (I32).
//	Inputs:		*frequency	-Desired frequency in Hz (SGL).
//	Outputs:	*frequency	-Actual best frequency found in Hz (SGL).
//			*timeB		-B value for first and second half cycle (I32).
//			*timeC		-C value for first and second half cycle (I32).
//
//	Time:		
//----------------------------------------------------------------------
long _stdcall PulseOutCalc(	float *frequency,
				long *timeB,
				long *timeC);
=cut
#// ###########################################################################
long
PulseOutCalc(frequency)
	float	frequency
  INIT:
	long	errcode;
	long	timeB;
	long	timeC;
  CODE:
	errcode = PulseOutCalc(&frequency, &timeB, &timeC);

        // Return the results to perl in a big array
        if(errcode) {
          char errorString[51];
          GetErrorString ( errcode, errorString );
          XPUSHs(sv_2mortal(newSVpv(errorString,0)));
        } else {
          XPUSHs(sv_2mortal(newSVnv(errcode)));
        }

        XPUSHs(sv_2mortal(newSVnv(frequency)));
        XPUSHs(sv_2mortal(newSVnv(timeB)));
        XPUSHs(sv_2mortal(newSVnv(timeC)));

#// ###########################################################################
=head
//======================================================================
// ReEnum:  Causes the LabJack to detach and re-attach from the bus
//	    so it will re-enumerate.  Configuration constants (local ID,
//	    power allowance, calibration data) are updated.
//
//	Returns:	LabJack errorcodes or 0 for no error (I32).
//	Inputs:		*idnum		-Local ID, Serial Number, or -1 for first
//					 found (I32).
//	Outputs:	*idnum		-Returns the Local ID or -1 if no LabJack is
//					 found (I32).
//
//	Time:		10 ms
//----------------------------------------------------------------------
long _stdcall ReEnum(long *idnum);
=cut
#// ###########################################################################
long
ReEnum(idnum)
	long idnum
  CODE:
	RETVAL = ReEnum(&idnum);
  OUTPUT:
	RETVAL
	idnum

#// ###########################################################################
=head
//======================================================================
// Reset:	Causes the LabJack to reset after about 2 seconds.
//
//	Returns:	LabJack errorcodes or 0 for no error (I32).
//	Inputs:		*idnum		-Local ID, Serial Number, or -1 for first
//					 found (I32).
//	Outputs:	*idnum		-Returns the Local ID or -1 if no LabJack is
//					 found (I32).
//
//	Time:		10 ms
//----------------------------------------------------------------------
long _stdcall Reset(long *idnum);
=cut
#// ###########################################################################
long
Reset(idnum)
	long idnum
  CODE:
	RETVAL = Reset(&idnum);
  OUTPUT:
	RETVAL
	idnum

#// ###########################################################################
=head
//======================================================================
// ResetLJ:	Same as "Reset".
//
//	Returns:	LabJack errorcodes or 0 for no error (I32).
//	Inputs:		*idnum		-Local ID, Serial Number, or -1 for first
//					 found (I32).
//	Outputs:	*idnum		-Returns the Local ID or -1 if no LabJack is
//					 found (I32).
//
//	Time:		10 ms
//----------------------------------------------------------------------
long _stdcall ResetLJ(long *idnum);
=cut
#// ###########################################################################
long
ResetLJ(idnum)
	long idnum
  CODE:
	RETVAL = ResetLJ(&idnum);
  OUTPUT:
	RETVAL
	idnum

#// ###########################################################################
=head
//======================================================================
// SHT1X:	This function retrieves temperature and/or humidity
//		readings from a SHT1X sensor.  Data rate is about 2 kbps
//		with firmware V1.09 or higher (hardware communication).
//		If firmware is less than V1.09, or TRUE is passed for
//		softComm, data rate is about 20 bps.
//
//		DATA = IO0
//		SCK  = IO1
//
//		The EI-1050 has an extra enable line that allows multiple
//		probes to be connected at the same time using only the one
//		line for DATA and one line for SCK.  This function does not
//		control the enable line.
//
//		This function automatically configures IO0 has an input
//		and IO1 as an output.
//
//		Note that internally this function operates on the state and
//		direction of IO0 and IO1, and to operate on any of the IO
//		lines the LabJack must operate on all 4.  The DLL keeps track
//		of the current direction and output state of all lines, so that
//		this function can operate on IO0 and IO1 without changing
//		IO2 and IO3.  When the DLL is first loaded,
//		though, it does not know the direction and state of
//		the lines and assumes all directions are input and
//		output states are low.
//
//	Returns:	LabJack errorcodes or 0 for no error (I32).
//	Inputs:		*idnum		-Local ID, Serial Number, or -1 for first
//					 found (I32).
//			demo		-Send 0 for normal operation, >0 for demo
//					 mode (I32).  Demo mode allows this function to
//					 be called without a LabJack, and does little but
//					 simulate execution time.
//			softComm	-If >0, forces software based communication.  Otherwise
//					 software communication is only used if the LabJack U12
//					 firmware version is less than V1.09.
//			mode		-0=temp and RH,1=temp only,2=RH only.  If mode is 2,
//					 the current temperature must be passed in for the
//					 RH corrections using *tempC.
//			statusReg	-Current value of the SHT1X status register.  The
//					 value of the status register is 0 unless you
//					 have used advanced functions to write to the
//					 status register (enabled heater, low resolution, or
//					 no reload from OTP).
//	Outputs:	*idnum		-Returns the Local ID or -1 if no LabJack is
//					 found (I32).
//			*tempC		-Returns temperature in degrees C.  If mode is 2,
//					 the current temperature must be passed in for the
//					 RH corrections.
//			*tempF		-Returns temperature in degrees F.
//			*rh		-Returns RH in percent.
//
//	Time:		About 20 ms plus SHT1X measurement time for hardware comm.
//			Default measurement time is 210 ms for temp and 55 ms for RH.
//			About 2 s per measurement for software comm.
//----------------------------------------------------------------------
long _stdcall SHT1X(	long *idnum,
			long demo,
			long softComm,
			long mode,
			long statusReg,
			float *tempC,
			float *tempF,
			float *rh);
=cut
#// ###########################################################################

#// ###########################################################################
=head
//======================================================================
// SHTComm:	Low-level public function to send and receive up to 4 bytes
//		to from an SHT1X sensor.  Data rate is about 2 kbps
//		with firmware V1.09 or higher (hardware communication).
//		If firmware is less than V1.09, or TRUE is passed for
//		softComm, data rate is about 20 bps.
//
//		DATA = IO0
//		SCK  = IO1
//
//		The EI-1050 has an extra enable line that allows multiple
//		probes to be connected at the same time using only the one
//		line for DATA and one line for SCK.  This function does not
//		control the enable line.
//
//		This function automatically configures IO0 has an input
//		and IO1 as an output.
//
//		Note that internally this function operates on the state and
//		direction of IO0 and IO1, and to operate on any of the IO
//		lines the LabJack must operate on all 4.  The DLL keeps track
//		of the current direction and output state of all lines, so that
//		this function can operate on IO0 and IO1 without changing
//		IO2 and IO3.  When the DLL is first loaded,
//		though, it does not know the direction and state of
//		the lines and assumes all directions are input and
//		output states are low.
//
//	Returns:	LabJack errorcodes or 0 for no error (I32).
//	Inputs:		*idnum		-Local ID, Serial Number, or -1 for first
//					 found (I32).
//			softComm	-If >0, forces software based communication.  Otherwise
//					 software communication is only used if the LabJack U12
//					 firmware version is less than V1.09.
//			waitMeas	-If >0, this is a T or RH measurement request.
//			serialReset	-If >0, a serial reset is issued before sending and
//					 receiving bytes.
//			dataRate	-0=no extra delay (default),1=medium delay,2=max delay.
//			numWrite	-Number of bytes to write (0-4,I32).
//			numRead		-Number of bytes to read (0-4,I32).
//			*datatx		-Array of 0-4 bytes to send.  Make sure you pass at least
//					 numWrite number of bytes (U8).
//	Outputs:	*idnum		-Returns the Local ID or -1 if no LabJack is
//					 found (I32).
//			*datarx		-Returns 0-4 read bytes as determined by numRead (U8).
//
//	Time:		About 20 ms plus SHT1X measurement time for hardware comm.
//			Default measurement time is 210 ms for temp and 55 ms for RH.
//			About 2 s per measurement for software comm.
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
=cut
#// ###########################################################################

#// ###########################################################################
=head
//======================================================================
// SHTCRC:	Checks the CRC on a SHT1X communication.  Last byte of
//		datarx is the CRC.  Returns 0 if CRC is good, or
//		SHT1X_CRC_ERROR_LJ if CRC is bad.
//----------------------------------------------------------------------
long _stdcall SHTCRC(	long statusReg,
			long numWrite,		// 0-4
			long numRead,		// 0-4
			unsigned char *datatx,  //4 byte write array
			unsigned char *datarx);	//4 byte read array
=cut
#// ###########################################################################

#// ###########################################################################
=head
//======================================================================
// Synch:	Requires firmware V1.09 or higher.
//
//		This function performs SPI communication.  Data rate is
//		about 160 kbps with no extra delay, although delays of
//		100 us or 1 ms per bit can be enabled.
//
//		Control of CS (chip select) can be enabled in this
//		function for D0-D7 or handled externally via any digital
//		output.
//
//		MOSI is D13
//		MISO is D14
//		SCK  is D15
//
//		If using the CB25, the protection resistors might need to be
//		shorted on all SPI connections (MOSI,MISO,SCK,CS).
//
//		The initial state of SCK is set properly (CPOL), by
//		this function, before !CS is brought low (final state is also
//		set properly before !CS is brought high again).  If chip-select
//		is being handled manually, outside of this function, care
//		must be taken to make sure SCK is initially set to CPOL.
//
//		All modes supported (A, B, C, and D).
//
//		Mode A: CPHA=1, CPOL=1
//		Mode B: CPHA=1, CPOL=0
//		Mode C: CPHA=0, CPOL=1
//		Mode D: CPHA=0, CPOL=0
//
//		If Clock Phase (CPHA) is 1, data is valid on the edge
//		going to CPOL.  If CPHA is 0, data is valid on the edge
//		going away from CPOL.
//		Clock Polarity (CPOL) determines the idle state of SCK.
//
//		Up to 18 bytes can be written/read.  Communication is full
//		duplex so 1 byte is read at the same time each byte is written.
//		If more than 4 bytes are written or read, this function uses
//		calls to WriteMem/ReadMem to load/read the LabJack's data buffer.
//
//		This function has the option (configD) to automatically configure
//		default state and direction for MOSI (D13 Output), MISO (D14 Input),
//		SCK (D15 Output CPOL), and CS (D0-D7 Output High for !CS).  This
//		function uses a call to DigitalIO to do this.  Similar to
//		EDigitalIn and EDigitalOut, the DLL keeps track of the current
//		direction and output state of all lines, so that these 4 D lines
//		can be configured without affecting other digital lines.  When the
//		DLL is first loaded, though, it does not know the direction and
//		state of the lines and assumes all directions are input and
//		output states are low.
//
//	Returns:	LabJack errorcodes or 0 for no error (I32).
//	Inputs:		*idnum		-Local ID, Serial Number, or -1 for first
//					 found (I32).
//			demo		-Send 0 for normal operation, >0 for demo
//					 mode (I32).  Demo mode allows this function to
//					 be called without a LabJack, and does little but
//					 simulate execution time.
//			mode		-Specify SPI mode as: 0=A,1=B,2=C,3=D (I32, 0-3).
//			msDelay		-If >0, a 1 ms delay is added between each bit.
//			husDelay	-If >0, a hundred us delay is added between each bit.
//			controlCS	-If >0, D0-D7 is automatically controlled as CS.  The
//					 state and direction of CS is only tested if control
//					 is enabled.
//			csLine		-D line to use as CS if enabled (I32, 0-7).
//			csState		-Active state for CS line.  This would be 0 for the
//					 normal !CS, or >0 for the less common CS.
//			configD		-If >0, state and tris are configured for D13, D14,
//					 D15, and !CS.
//			numWriteRead	-Number of bytes to write and read (I32, 1-18).
//			*data		-Serial data buffer.  Send an 18 element
//					 array of bytes.  Fill unused locations with zeros (I32).
//	Outputs:	*idnum		-Returns the Local ID or -1 if no LabJack is
//					 found (I32).
//			*data		-Serial data buffer.  Returns any serial read
//					 data.  Unused locations are filled
//					 with 9999s. (I32).
//
//	Time:		20 ms to read & write up to 4 bytes, plus 40 ms for each
//			additional 4 bytes to read or write.  Extra 20 ms if configIO
//			is true.  Extra time if delays are enabled.
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
=cut
#// ###########################################################################
long
Synch(idnum, demo, mode, msDelay, husDelay, controlCS, csLine, csState, configD, numWriteRead, data)
	long idnum
	long demo
	long mode
	long msDelay
	long husDelay
	long controlCS
	long csLine
	long csState
	long configD
	long numWriteRead
	long data
  INIT:
	long i, errcode;
  PPCODE:
	errcode = Synch(&idnum, demo, mode, msDelay, husDelay, controlCS, csLine, csState, configD, numWriteRead, &data);

        // Return the results to perl in a big array
        if(errcode) {
          char errorString[51];
          GetErrorString ( errcode, errorString );
          XPUSHs(sv_2mortal(newSVpv(errorString,0)));
          XPUSHs(sv_2mortal(newSVnv(errcode)));
        } else {
          XPUSHs(sv_2mortal(newSVnv(errcode)));
        }
        XPUSHs(sv_2mortal(newSVnv(idnum)));
	// This still needs lots of work!
	XSRETURN_PVN((long *) &data, (sizeof(long) * numWriteRead));

#// ###########################################################################
=head
//======================================================================
// Watchdog:	Controls the LabJack watchdog function.
//
//	Returns:	LabJack errorcodes or 0 for no error (I32).
//	Inputs:		*idnum		-Local ID, Serial Number, or -1 for first
//					 found (I32).
//			demo		-Send 0 for normal operation, >0 for demo
//					 mode (I32).  Demo mode allows this function to
//					 be called without a LabJack, and does little but
//					 simulate execution time.
//			active		-Enables the LabJack watchdog function.  If
//					 enabled, the 32-bit counter is disabled.
//			timeout		-Timer reset value in seconds (I32).
//			reset		-If >0, the LabJack will reset on timeout (I32).
//			activeDn	-If >0, Dn will be set to stateDn upon
//					 timeout (I32).
//			stateDn		-Timeout state of Dn, 0=low, >0=high (I32).
//	Outputs:	*idnum		-Returns the Local ID or -1 if no LabJack is
//					 found (I32).
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
=cut
#// ###########################################################################
long
Watchdog(idnum, demo, active, timeout, reset, activeD0, activeD1, activeD8, stateD0, stateD1, stateD8)
	long idnum
	long demo
	long active
	long timeout
	long reset
	long activeD0
	long activeD1
	long activeD8
	long stateD0
	long stateD1
	long stateD8
  CODE:
	RETVAL = Watchdog(&idnum, demo, active, timeout, reset, activeD0, activeD1, activeD8, stateD0, stateD1, stateD8);
  OUTPUT:
	RETVAL
	idnum

#// ###########################################################################
=head
//======================================================================
// ReadMem: Reads 4 bytes from a specified address in the LabJack's
//	    nonvolatile memory.
//
//	Returns:	LabJack errorcodes or 0 for no error (I32).
//	Inputs:		*idnum		-Local ID, Serial Number, or -1 for first
//					 found (I32).
//			address		-Starting address of data to read
//					 from 0-8188 (I32).
//	Outputs:	*idnum		-Returns the Local ID or -1 if no LabJack is
//					 found (I32).
//			*data3		-Byte at address (I32).
//			*data2		-Byte at address+1 (I32).
//			*data1		-Byte at address+2 (I32).
//			*data0		-Byte at address+3 (I32).
//
//	Time:		20 ms
//----------------------------------------------------------------------
long _stdcall ReadMem(long *idnum,
		      long address,
		      long *data3,
		      long *data2,
		      long *data1,
		      long *data0);
=cut
#// ###########################################################################
long
ReadMem(idnum,address)
	long idnum
	long address
  INIT:
	long errcode;
	long d0, d1, d2, d3;

  PPCODE:
	errcode = ReadMem(&idnum, address, &d3, &d2, &d1, &d0);

        // Return the results to perl in a big array
        if(errcode) {
          char errorString[51];
          GetErrorString ( errcode, errorString );
          XPUSHs(sv_2mortal(newSVpv(errorString,0)));
          XPUSHs(sv_2mortal(newSVnv(errcode)));
        } else {
          XPUSHs(sv_2mortal(newSVnv(errcode)));
        }

        XPUSHs(sv_2mortal(newSVnv(idnum)));
        XPUSHs(sv_2mortal(newSVnv(d0)));
        XPUSHs(sv_2mortal(newSVnv(d1)));
        XPUSHs(sv_2mortal(newSVnv(d2)));
        XPUSHs(sv_2mortal(newSVnv(d3)));

#// ###########################################################################
=head
//======================================================================
// WriteMem: Writes 4 bytes to the LabJack's nonvolatile memory at a
//	     specified address.  The data is read back and verified
//	     after the write.  Memory 0-511 is used for configuration
//	     and calibration data.  Memory from 512-1023 is unused by the
//     	     the LabJack and available for the user (this corresponds to
//	     starting addresses from 512-1020).  Memory 1024-8191 is
//	     used as a data buffer in hardware timed AI modes.
//
//	Returns:	LabJack errorcodes or 0 for no error (I32).
//	Inputs:		*idnum		-Local ID, Serial Number, or -1 for first
//					 found (I32).
//			unlocked	-If >0, addresses 0-511 are unlocked for
//					 writing (I32).
//			address		-Starting address for writing 0-8188 (I32).
//			data3		-Byte for address (I32).
//			data2		-Byte for address+1 (I32).
//			data1		-Byte for address+2 (I32).
//			data0		-Byte for address+3 (I32).
//	Outputs:	*idnum		-Returns the Local ID or -1 if no LabJack is
//					 found (I32).
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
=cut
#// ###########################################################################
long
WriteMem(idnum,unlocked,address,data3,data2,data1,data0)
	long idnum
	long unlocked
	long address
	long data3
	long data2
	long data1
	long data0
  CODE:
	RETVAL = WriteMem(&idnum,unlocked,address,data3,data2,data1,data0);
  OUTPUT:
	RETVAL
	idnum

#// ###########################################################################

=head1 NAME

LabJack - access to USB LabJack libraries

=head1 SYNOPSIS

Perl Extension for access to the LabJack USB-based
measurement and automation device (http://www.labjack.com/) using
either the Eric Sortons Linux LabJack library
(http://www.cctcorp.com/~eric/labjack/) or the LabJack provided
ljackuw.lib (include on the LabJack CD).

=head1 DESCRIPTION

LabJack - Perl Extension for access to the LabJack USB-based
measurement and automation device (http://www.labjack.com/).

We can currently support the following library calls:

   EAnalog
   EAnalogOut
   ECount
   EDigitalIn
   EDigitalOut
   AISample
   Counter
   DigitalIO
   GetDriverVersion
   GetErrorString
   GetWinVersion
   ReEnum
   Reset
   ResetLJ
   SHT1X
   SHTComm
   SHTCRC
   Synch
   Watchdog
   ReadMem
   WriteMem

   BitsToVolts
   VoltsToBits

The following are not yet tested but written:

   AsynchConfig
   PulseOut
   PulseOutStart
   PulseOutFinish
   PulseOutCalc

The following are not yet supported:

   Asynch
   AIBurst
   AIStreamStart
   AIStreamRead
   AIStreamClear
   AOUpdate
   ListAll
   LocalID
   NoThread

=head1 METHODS

  =head2 EAnalog
  =head2 EAnalogOut
  =head2 ECount
  =head2 EDigitalIn
  =head2 EDigitalOut
  =head2 AISample
  =head2 Counter
  =head2 DigitalIO
  =head2 GetDriverVersion
  =head2 GetErrorString
  =head2 GetWinVersion
  =head2 ReEnum
  =head2 Reset
  =head2 ResetLJ
  =head2 SHT1X
  =head2 SHTComm
  =head2 SHTCRC
  =head2 Synch
  =head2 Watchdog
  =head2 ReadMem
  =head2 WriteMem
  =head2 BitsToVolts
  =head2 VoltsToBits
  =head2 AsynchConfig
  =head2 PulseOut
  =head2 PulseOutStart
  =head2 PulseOutFinish
  =head2 PulseOutCalc
  =head2 Asynch
  =head2 AIBurst
  =head2 AIStreamStart
  =head2 AIStreamRead
  =head2 AIStreamClear
  =head2 AOUpdate
  =head2 ListAll
  =head2 LocalID
  =head2 NoThread

-head1 EXPORT

=head1 AUTHOR

Version 0.1
Chris Drake Feb. 1, 2003
http://www.ReadNotify.com

Version 0.2 
Neil Cherry <lt>ncherry\@comcast.net<gt> Aug. 16, 2003
http://home.comcast.net/ncherry/index.html (http://mywebpages.comcast.net/ncherry/)

Version 0.21
Chris Drake <lt>christopher\@pobox.com<gt> Oct. 25, 2005


=head SEE ALSO

L<perl>
???

=cut
=head

Excerpts from the mail message of Clinton A. Pierce:

) Ok, I've been through perlxstut, and I'm pretty comfortable there.  I
) just wish it had one more example covering something like this.

Yes, I think the coverage of things requiring memory allocation is
almost zero.

) What I have is a library that essentially populates a structure (the
) memory for which the caller is assumed to have allocated) and then
) performs calculations on that structure.

Well, let's jump right to a solution.  In XS:

    SV *
    populate()
    preinit:
	struct pinfo rec;
    code:
	populate( &rec );
	XSRETURN_PVN( (char *)&rec, sizeof(rec) );

    SV *
    calculate( payroll )
	char *  payroll
    preinit:
	struct pinfo rec;
    code:
	if(  SvCUR(ST(0)) < sizeof(rec)  )
	    XSRETURN_UNDEF;	/* Passed in too short of a string */
	memcpy( (char *)&rec, payroll, sizeof(rec) );
	caculate( &rec );
	XSRETURN_PVN( (char *)&rec, sizeof(rec) );

Perl:

    $rec= populate();
    $rec= calculate( $rec );

or just:

    $rec= calculate populate;

) I was just hoping to get the structure
) stored in a perl scalar that I could unpack as I needed...

Yo got it, mang!

Now, the analysis, in case you care.  Since the library lets the
caller allocate the buffer, you can do this easily.  For your
case, I'd probably do:

  * Have the C code allocate a temporary buffer, pass a pointer to
    that into your library, copy the buffer contents to an SV. 
    This has several important advantages:
      + Copying buffer contents into an SV is well covered [in
	documentation and APIs] and so is very easy to do.
      + Allocating a temporary buffer in C is usually within the
        skill set of an XS writer.
      + This is usually hard to do well with a typemap so you
        don't have to learn about typemaps to do it.  :)
    There are a few cases where you probably wouldn't want to do
    this:
      - If the buffer contains pointers to items in the buffer
        [copying invalidates such pointers].
      - If the buffer is large [copying large buffers takes too
        much CPU time].
      - If the required buffer size is hard to predict [you can
        still handle this case this way, but people who do this
        often make poor compromises, like assuming that needing
        more than X bytes is unreasonable].
      - You are wrapping a ton of these type of APIs so you'd
        really rather have a typemap.
      - You want to handle input-only, output-only, and update
        buffers in a consistant manner.

Another solution is:

  * Have the Perl code pass in an SV to the XS, have the XS ensure
    that the SV has a big enough buffer, pass the SV buffer to the
    library, if the library modified the buffer contents, then
    "tell" the SV that its value has changed.  This fixes all of
    the problems mentioned, though two are only partially addressed:
      + If the required buffer size is hard to predict, using this
	solution will usually result in an interface where the
	Perl code that calls the XS can force an extra large buffer
	to be allocated.
      + For some cases, you can't do this well in a typemap.
    Of course, it has a few major disadvantages:
      - The documentation falls far short here.
      - You'll need several macros for each step instead of just
        one macro at the end.
      - There are a lot of details [most of which are not
        critical] that you won't get right at first.

If you are interested in this, grab the latest Win32API::Registry
and read F<buffers.h>.

Then there is the solution of:

  * Have the XS code wrap an object around the buffer.

That is what T_PTROBJ is about.  I personally hate this option
[if you want to create an object, do it in Perl code].  So I'd
never consider it unless the library won't allow me to allocate
the buffer.

) The example in perlxs confuses me when I get to the part about
) "Netconfig *T_PTROBJ".  What is this?

I don't think this is completely documented.  It is about the
only support in XS that can kind of handle buffers that are not
allocated by Perl.  You stuff a pointer to the buffer into an SV
and bless it [making a Perl object] and then write XS routines
that act as methods for this object.

) What's this typemap file and where does it go, and what should
) it be named?  Do I need an INPUT and OUTPUT section?

If it called "typemap" and it goes in the same directory as your
*.xs file.  You can see a sample in perl/lib/ExtUtils/typemap. 
To handle C<populate>, you'd only need an OUTPUT section.  For
C<calculate>, you'd need both.  Code in the INPUT section is used
for [by default] all parameters.  Code in the OUTPUT section is
used for things mentioned in a routine's OUTPUT section [include
RETVAL which is in the OUTPUT section by default].

) And why does perlxs muddle the discussion about passing structures back
) and forth with a discussion about perl namespaces?  That just confuses
) me further.

Because handling the worst cases of dealing with structures
requires dealing with memory not allocated by Perl which requires
black magic which the author thinks is best done by creating
objects, which messes with perl namespaces??

)         struct pinfo *payroll;
)         payroll=(struct pinfo *)malloc(sizeof (struct pinfo));

Why not just this:

    struct pinfo rec;
    payroll= &rec;

Then you don't have to C<free(payroll)> [which you forgot to do].
-- 
Tye McQueen    Nothing is obvious unless you are overlooking something
         http://www.metronet.com/~tye/ (scripts, links, nothing fancy)
=cut



