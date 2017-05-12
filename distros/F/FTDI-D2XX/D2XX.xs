#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"


#ifdef WIN32

// windows includes
#include "ftd2xx.h"
#include <windows.h>

#else

//linux includes
#include <ftd2xx.h>
#include "WinTypes.h"
#include <strings.h>

#endif

#include <stdlib.h>


// #define DEBUG 1

// written on linux (debian) for ftdi d2xx version 0.4.16
//


MODULE = FTDI::D2XX		PACKAGE = FTDI::D2XX		

PROTOTYPES: ENABLE

FT_STATUS 
FT_Open( deviceNumber, pHandle )
	int deviceNumber
	FT_HANDLE *pHandle = NO_INIT
	CODE:
		pHandle = malloc(sizeof(FT_HANDLE));
		RETVAL = FT_Open( deviceNumber, pHandle);
		
	OUTPUT:
		pHandle
		RETVAL

FT_STATUS 
FT_OpenEx( Arg1, Flags, pHandle )
    	SV * Arg1
    	DWORD Flags
    	FT_HANDLE *pHandle = NO_INIT
	INIT:
		DWORD pArg1D;
		PVOID pArg1P;
	CODE:
		pHandle = malloc(sizeof(FT_HANDLE));
		if((Flags != FT_OPEN_BY_SERIAL_NUMBER) 
			&& (Flags != FT_OPEN_BY_DESCRIPTION )) {
			// pArg1 equals ID number
			pArg1D = (DWORD)SvUV(Arg1);
			RETVAL = FT_OpenEx( &pArg1D, Flags, pHandle );
		} else {
			// pArg1 equals pointer to string
			pArg1P = SvPV_nolen(Arg1); // Convert to string
			RETVAL = FT_OpenEx( pArg1P, Flags, pHandle );

		}
	OUTPUT:
		pHandle
		RETVAL
  
FT_STATUS 
FT_Close( ftHandle )
    FT_HANDLE *ftHandle
	CODE:
		RETVAL=FT_Close( *ftHandle );
		free(ftHandle);
	OUTPUT:
		RETVAL

  
# So far not implemented
# FT_STATUS 
# FT_ListDevices( pArg1, pArg2, Flags ) 

FT_STATUS FT_CreateDeviceInfoList( NumDevs )
	DWORD NumDevs = NO_INIT
	CODE:
		RETVAL = FT_CreateDeviceInfoList( &NumDevs );
	OUTPUT:
		RETVAL
		NumDevs

# FT_STATUS FT_GetDeviceInfoList( DevInfo, NumDevs)
# Not implemented, use GetDeviceInfoDetail

FT_STATUS FT_GetDeviceInfoDetail( dwIndex, dwFlags, dwType, dwID, dwLocId,SerialNumber,Description, pftHandle)
	DWORD dwIndex
	DWORD dwFlags = NO_INIT
	DWORD dwType = NO_INIT
	DWORD dwID = NO_INIT
	DWORD dwLocId = NO_INIT
	SV * SerialNumber = NO_INIT
	SV * Description = NO_INIT
	FT_HANDLE *pftHandle = NO_INIT
	INIT:
		char * lpSerialNumber;
		char * lpDescription;
	CODE:
		pftHandle = malloc(sizeof(FT_HANDLE));
		lpSerialNumber = malloc(16);
		lpDescription = malloc(64);
		RETVAL = FT_GetDeviceInfoDetail( dwIndex, &dwFlags, &dwType, &dwID, &dwLocId, lpSerialNumber, lpDescription, pftHandle);
		SerialNumber = sv_2mortal(newSVpv(lpSerialNumber,16));
		free(lpSerialNumber);
		Description = sv_2mortal(newSVpv(lpDescription,64));
		free(lpDescription);
	OUTPUT:
		dwFlags
		dwType
		dwID
		dwLocId
		SerialNumber
		Description
		pftHandle
		RETVAL
	
FT_STATUS FT_GetDriverVersion( ftHandle, dwVersion)
    	FT_HANDLE ftHandle
	DWORD	dwVersion = NO_INIT
	CODE:
		RETVAL = FT_GetDriverVersion( ftHandle, &dwVersion);
	OUTPUT:
		RETVAL
		dwVersion
	
	
FT_STATUS FT_GetLibraryVersion( dwVersion )
	DWORD dwVersion = NO_INIT
	CODE:
		RETVAL = FT_GetLibraryVersion( &dwVersion );
	OUTPUT:
		RETVAL
		dwVersion


## These functions are not defined in the Windows header file from driver Version
## 2.06.00

#ifndef WIN32

FT_STATUS
FT_SetVIDPID( dwVID, dwPID)
	DWORD dwVID 
	DWORD dwPID
	

FT_STATUS
FT_GetVIDPID( dwVID, dwPID)
	DWORD dwVID = NO_INIT; 
	DWORD dwPID = NO_INIT;
	CODE:
		RETVAL = FT_GetVIDPID(&dwVID, &dwPID);
	OUTPUT:
		dwVID
		dwPID
		RETVAL

#endif


FT_STATUS
FT_Read( pHandle, Buffer, nBufferSize, lpBytesReturned)
    FT_HANDLE * pHandle
    SV * Buffer = NO_INIT
    DWORD nBufferSize
    DWORD lpBytesReturned = NO_INIT
	PREINIT:
		char* lpBuffer;
		AV* array;
		DWORD i;
	CODE:
		// get mem
		lpBuffer = malloc(nBufferSize);
		RETVAL = FT_Read(*pHandle, lpBuffer, nBufferSize, &lpBytesReturned);
		
		// convert output to array
		// new array
		array = (AV *)sv_2mortal((SV *)newAV());
		// extend it ( not required but faster) 
		av_extend(array,lpBytesReturned);
		// copy to array
		for( i = 0; i< lpBytesReturned; i++) {
			av_push(array,newSVuv(lpBuffer[i]));
		}
		// give back mem
		free(lpBuffer);
		// return reference of the array
		Buffer = newRV((SV *) array);
	OUTPUT: 
		Buffer
		lpBytesReturned
		RETVAL

FT_STATUS
FT_Write( ftHandle, Buffer, nBufferSize, BytesWritten)
    	FT_HANDLE  ftHandle
    	SV * Buffer
    	DWORD nBufferSize
    	DWORD BytesWritten = NO_INIT
    	PREINIT:
		AV * arrayBuffer;
		char * lpBuffer;
		DWORD i;
	CODE:	
		if( (!SvROK(Buffer)) 
			|| (SvTYPE(SvRV(Buffer)) != SVt_PVAV) 
			|| !((DWORD)av_len((AV *)SvRV(Buffer)) < nBufferSize)) 
		{
			printf("Data type error\n");
			printf("!SvROK(Buffer): %d\n",!SvROK(Buffer));
			printf("(SvTYPE(SvRV(Buffer)) != SVt_PVAV) %di\n", (SvTYPE(SvRV(Buffer)) != SVt_PVAV));
			printf("av_len((AV *)SvRV(Buffer)): %d\n", av_len((AV *)SvRV(Buffer)));
			
			XSRETURN_UNDEF;
		}
	
		// copy from array (reference) to buffer
		lpBuffer = malloc(nBufferSize);
		arrayBuffer = (AV *)SvRV(Buffer);
		for(i=0; i<nBufferSize;i++) {
			lpBuffer[i] = (char)SvUV(*av_fetch(arrayBuffer,i,0));
//			#ifdef DEBUG
//			printf("FT_Write buffer [%i] = %X\n", i, lpBuffer[i]);
//			#endif
		}
		RETVAL = FT_Write( ftHandle, lpBuffer, nBufferSize, &BytesWritten);
		free(lpBuffer);
	OUTPUT:
		RETVAL
		BytesWritten


#FTD2XX_API 
#FT_STATUS WINAPI FT_IoCtl(		// Linux, OS X: Not supported
#    FT_HANDLE ftHandle,
#    DWORD dwIoControlCode,
#    LPVOID lpInBuf,
#    DWORD nInBufSize,
#    LPVOID lpOutBuf,
#    DWORD nOutBufSize,
#    LPDWORD lpBytesReturned,
#    LPOVERLAPPED lpOverlapped
#    );


FT_STATUS FT_SetBaudRate( FT_HANDLE ftHandle, ULONG BaudRate );


FT_STATUS FT_SetDivisor( FT_HANDLE ftHandle, USHORT Divisor );


FT_STATUS FT_SetDataCharacteristics( FT_HANDLE ftHandle, UCHAR WordLength, UCHAR StopBits, UCHAR Parity	);


FT_STATUS FT_SetFlowControl( FT_HANDLE ftHandle,USHORT FlowControl,UCHAR XonChar,UCHAR XoffChar	);


FT_STATUS FT_ResetDevice( FT_HANDLE ftHandle);


FT_STATUS FT_SetDtr( FT_HANDLE ftHandle	);


FT_STATUS FT_ClrDtr( FT_HANDLE ftHandle	);


FT_STATUS FT_SetRts( FT_HANDLE ftHandle	);


FT_STATUS FT_ClrRts( FT_HANDLE ftHandle	);
		
FT_STATUS FT_GetModemStatus( ftHandle,	ModemStatus )
	FT_HANDLE ftHandle
	ULONG ModemStatus = NO_INIT
	CODE:
		RETVAL = FT_GetModemStatus( ftHandle,&ModemStatus );
	OUTPUT:
		RETVAL
		ModemStatus

FT_STATUS FT_SetChars( FT_HANDLE ftHandle,UCHAR EventChar,UCHAR EventCharEnabled,UCHAR ErrorChar,UCHAR ErrorCharEnabled);


FT_STATUS FT_Purge( FT_HANDLE ftHandle,	ULONG Mask);


FT_STATUS FT_SetTimeouts(FT_HANDLE ftHandle,ULONG ReadTimeout,ULONG WriteTimeout);


FT_STATUS FT_GetQueueStatus( ftHandle, RxBytes) 
	FT_HANDLE ftHandle
	DWORD RxBytes = NO_INIT
	CODE:
		RETVAL = FT_GetQueueStatus( ftHandle, &RxBytes);
	OUTPUT:
		RETVAL
		RxBytes

## unfinished
# FT_STATUS FT_SetEventNotification(FT_HANDLE ftHandle,DWORD Mask,PVOID Param);

FT_STATUS 
FT_GetStatus( ftHandle, RxBytes, TxBytes, EventDWord)
    	FT_HANDLE ftHandle
    	DWORD RxBytes = NO_INIT
    	DWORD TxBytes = NO_INIT
    	DWORD EventDWord = NO_INIT
	CODE:
		RETVAL = FT_GetStatus(ftHandle, &RxBytes, &TxBytes, &EventDWord);
	OUTPUT:
		RxBytes
		TxBytes
		EventDWord
		RETVAL

FT_STATUS FT_SetBreakOn(FT_HANDLE ftHandle);

FT_STATUS FT_SetBreakOff(FT_HANDLE ftHandle );

#// Linux, OS X: Not supported
FT_STATUS FT_SetWaitMask(ftHandle, Mask)	
    FT_HANDLE ftHandle
    DWORD Mask
    
#// Linux, OS X: Not supported
FT_STATUS FT_WaitOnMask(ftHandle, Mask)		
    	FT_HANDLE ftHandle
    	DWORD Mask = NO_INIT
    	CODE:
		RETVAL = FT_WaitOnMask(ftHandle, &Mask);
	OUTPUT:
		RETVAL
		Mask

FT_STATUS FT_GetEventStatus( ftHandle, EventDWord)
    FT_HANDLE ftHandle
    DWORD EventDWord = NO_INIT
    CODE:
	RETVAL = FT_GetEventStatus( ftHandle, &EventDWord);
    OUTPUT:
	EventDWord
	RETVAL


FT_STATUS FT_ReadEE( ftHandle, dwWordOffset, Value)
    	FT_HANDLE ftHandle
	DWORD dwWordOffset
    	WORD Value = NO_INIT
	CODE:
		RETVAL = FT_ReadEE( ftHandle, dwWordOffset, &Value);
	OUTPUT:
		RETVAL
		Value



FT_STATUS FT_WriteEE(FT_HANDLE ftHandle,DWORD dwWordOffset,WORD wValue);


FT_STATUS FT_EraseEE(FT_HANDLE ftHandle	);

# Implements FT_EE_Program but requires an Array Ref as input. The data conversion from a Hash structure
# to the array will be implemented in Perl
FT_STATUS FT_EE_ProgramByArray( ftHandle, Data) 
	FT_HANDLE ftHandle
	SV * Data
	PREINIT:
		// Data is a reference of a array
		AV * arrayBuffer;
		char * pData;
		DWORD i;
	CODE:	
		if( (!SvROK(Data)) || 
			(SvTYPE(SvRV(Data)) != SVt_PVAV) || 
			(av_len((AV *)SvRV(Data)) < 0)) 
		{
			XSRETURN_UNDEF;
		}
	
		// copy from array (reference) to buffer
		pData = malloc(sizeof(FT_PROGRAM_DATA));
		arrayBuffer = (AV *)SvRV(Data);
		for(i=0; i<sizeof(FT_PROGRAM_DATA);i++) {
			pData[i] = (char)SvUV(*av_fetch(arrayBuffer,i,0));
		}
		RETVAL = FT_EE_Program(ftHandle, (PFT_PROGRAM_DATA)pData);
		free(pData);
	OUTPUT:
		RETVAL
	

# The functionallity of FT_EE_ProgramEx is generally not needed in Perl and can be simply implemented by
# Perl and FT_EE_ProgramByArray if required.

# Implements FT_EE_Read but returns an RefArray as output. The data conversion from a Array
# to the Hash structure will be implemented in Perl
FT_STATUS FT_EE_ReadToArray( ftHandle, Data)
    	FT_HANDLE ftHandle
	SV * Data = NO_INIT
	PREINIT:
		char *lpBuffer;
		AV * array;
		DWORD i;
	CODE:
		// get mem
		lpBuffer = malloc(sizeof(FT_PROGRAM_DATA));
		RETVAL = FT_EE_Read(ftHandle, (PFT_PROGRAM_DATA)lpBuffer);
		
		// convert output to array
		// new array
		array = (AV *)sv_2mortal((SV *)newAV());
		// extend it ( not required but faster) 
		av_extend(array,sizeof(FT_PROGRAM_DATA));
		// copy to array
		for( i = 0; i< sizeof(FT_PROGRAM_DATA); i++) {
			av_push(array,newSVuv(lpBuffer[i]));
		}
		// give back mem
		free(lpBuffer);
		// return reference of the array
		Data = newRV((SV *) array);
	OUTPUT:
		Data
		RETVAL
	
FT_STATUS  FT_EE_UASize( ftHandle, dwSize)
    	FT_HANDLE ftHandle
	DWORD dwSize = NO_INIT
	CODE:
		RETVAL = FT_EE_UASize( ftHandle, &dwSize);
	OUTPUT:
		dwSize
		RETVAL


FT_STATUS  FT_EE_UAWrite( ftHandle, Data, dwDataLen)
    	FT_HANDLE ftHandle
	SV * Data
	WORD dwDataLen
	PREINIT:
		// Data is a reference of a array
		AV * arrayBuffer;
		PUCHAR pData;
		DWORD i;
	CODE:	
		if( (!SvROK(Data)) || 
			(SvTYPE(SvRV(Data)) != SVt_PVAV) || 
			(av_len((AV *)SvRV(Data)) < 0)) 
		{
			XSRETURN_UNDEF;
		}

		// copy from array (reference) to buffer
		pData = malloc(dwDataLen);
		arrayBuffer = (AV *)SvRV(Data);
		for(i=0; i<dwDataLen;i++) {
			pData[i] = (char)SvUV(*av_fetch(arrayBuffer,i,0));
		}
		RETVAL = FT_EE_UAWrite(ftHandle, pData, dwDataLen);
		free(pData);
	OUTPUT:
		RETVAL


FT_STATUS  FT_EE_UARead( ftHandle, Buffer, nBufferSize, lpBytesReturned)
    	FT_HANDLE ftHandle
	SV * Buffer = NO_INIT
	DWORD nBufferSize
	DWORD lpBytesReturned = NO_INIT
	PREINIT:
		PUCHAR lpBuffer;
		AV * array;
		DWORD i;
	CODE:
		// get mem
		lpBuffer = malloc(nBufferSize);
		RETVAL = FT_EE_UARead(ftHandle, lpBuffer, nBufferSize, &lpBytesReturned);
		
		// convert output to array
		// new array
		array = (AV *)sv_2mortal((SV *)newAV());
		// extend it ( not required but faster) 
		av_extend(array,lpBytesReturned);
		// copy to array
		for( i = 0; i< lpBytesReturned; i++) {
			av_push(array,newSVuv(lpBuffer[i]));
		}
		// give back mem
		free(lpBuffer);
		// return reference of the array
		Buffer = newRV((SV *) array);
	OUTPUT: 
		Buffer
		lpBytesReturned
		RETVAL


FT_STATUS  FT_SetLatencyTimer(FT_HANDLE ftHandle,UCHAR ucLatency );


FT_STATUS  FT_GetLatencyTimer( ftHandle, Latency)
    FT_HANDLE ftHandle
    UCHAR Latency = NO_INIT
	CODE:
		RETVAL = FT_GetLatencyTimer( ftHandle, &Latency);
	OUTPUT:
		RETVAL
		Latency




FT_STATUS  FT_SetBitMode(FT_HANDLE ftHandle, UCHAR ucMask,UCHAR ucEnable);


FT_STATUS  FT_GetBitMode( ftHandle, Mode )
    	FT_HANDLE ftHandle
    	UCHAR Mode
    	CODE:
		RETVAL = FT_GetBitMode( ftHandle, &Mode );
	OUTPUT:
		Mode
		RETVAL



FT_STATUS  FT_SetUSBParameters(FT_HANDLE ftHandle,ULONG ulInTransferSize,ULONG ulOutTransferSize);
	

FT_STATUS  FT_SetDeadmanTimeout(FT_HANDLE ftHandle,ULONG ulDeadmanTimeout);
#		// -1 for infinite (2.6 kernels only). High +ve number for 2.4 kernels
	

FT_STATUS  FT_GetDeviceInfo( ftHandle, ftDevice, dwID, SerialNumber, Description, Dummy)
    	FT_HANDLE ftHandle
    	FT_DEVICE ftDevice
	DWORD dwID = NO_INIT
	char * SerialNumber = NO_INIT
	char * Description = NO_INIT
	SV * Dummy
    	CODE:
		SerialNumber = malloc(16); // from Databook
		Description = malloc(64);  // from Databook
		RETVAL = FT_GetDeviceInfo( ftHandle, &ftDevice, &dwID, SerialNumber, Description, Dummy);
	OUTPUT:
		dwID
		ftDevice
		SerialNumber
		Description
		RETVAL



FT_STATUS  FT_StopInTask(FT_HANDLE ftHandle);


FT_STATUS  FT_RestartInTask(FT_HANDLE ftHandle);

# 	// Linux, OS X: Not supported
FT_STATUS  FT_SetResetPipeRetryCount(FT_HANDLE ftHandle,DWORD dwCount);

#	// Linux, OS X: Not supported
FT_STATUS  FT_ResetPort(FT_HANDLE ftHandle);
	
#	// Linux, OS X: Not supported
FT_STATUS  FT_CyclePort(FT_HANDLE ftHandle);

