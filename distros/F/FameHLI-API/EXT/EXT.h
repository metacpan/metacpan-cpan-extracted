/*****************************************************************************
**	File:	EXT.h
**	Type:	Extension library for FameHLI
**	Author:	David Oberholtzer, (daveo@obernet.com)
**			Copyright (c)2005, David Oberholtzer
**	Date:	2001/03/23
**	Rev:	$Id: EXT.h,v 1.1 2003/06/18 02:29:32 daveo Exp daveo $
**	Use:	Access to  FAME functions in other platforms.
*****************************************************************************/

#ifndef	__FAMEHLI_API_EXT__
#define	__FAMEHLI_API_EXT__

#include <string.h>
#include <stdlib.h>
#include <ctype.h>
#include <time.h>
#include "hli.h"

//==========================================================================
//		D E F I N E S
//==========================================================================
#define	FAME_TRUE		(1==1)
#define	FAME_FALSE		(1==0)
#define	SMALLBUF		256
#define	BIGBUF			1024
#define	HNOTYET			999		/* Fame function not implemented yet */



//==========================================================================
//		F U N C T I O N   P R O T O T Y P E S
//==========================================================================

//		------------------------------------------------------------
//		C O D E   D E S C R I P T I O N S
//		------------------------------------------------------------
char	*ClassDesc(int fameclass);
char	*ErrDesc(int status);
char	*FreqDesc(int freq);
char	*TypeDesc(int fametype);
char	*AccessModeDesc(int code);
char	*BasisDesc(int code);
char	*ObservedDesc(int code);
char	*MonthsDesc(int observed);
char	*OldFYEndDesc(int code);
char	*WeekdayDesc(int code);
char	*BiWeekdayDesc(int code);
char	*FYLabelDesc(int code);

//		------------------------------------------------------------
//		O T H E R   S T U F F
//		------------------------------------------------------------
char	*newString(char *src);
char	*FormatDate(int date, int freq, char *image, int fmonth, int flabel);


#endif	// __FAMEHLI_API_EXT__

