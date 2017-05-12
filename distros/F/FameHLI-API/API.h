/*****************************************************************************
**	File:	FameHLI_funcs.h
**	Type:	interface library (for Perl and friends)
**	Author:	David Oberholtzer, (daveo@obernet.com)
**			Copyright (c)2005, David Oberholtzer
**	Date:	2001/03/23
**	Rev:	$Id: API.h,v 1.1 2003/06/18 02:01:57 daveo Exp daveo $
**	Use:	Access to  FAME functions in other platforms.
*****************************************************************************/

#ifndef	__FAMEHLI_FUNCS__
#define	__FAMEHLI_FUNCS__

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
//		Getting FAME Errors
//		------------------------------------------------------------
char	*Cfmferr();
int		Cfmlerr();

//		------------------------------------------------------------
//		O T H E R   S T U F F
//		------------------------------------------------------------
void	SetErrBuff();
char	*newString(char *src);

#endif	// __FAMEHLI_FUNCS__

