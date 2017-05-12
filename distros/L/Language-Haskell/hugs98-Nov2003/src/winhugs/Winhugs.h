/* --------------------------------------------------------------------------
 * WinHugs.h:	José Enrique Gallardo Ruiz, Feb 1999
 *
 * The Hugs 98 system is Copyright (c) José Enrique Gallardo, Mark P Jones,
 * Alastair Reid, the Yale Haskell Group, and the OGI School of
 * Science & Engineering at OHSU, 1994-2003, All rights reserved.  It is
 * distributed as free software under the license in the file "License",
 * which is included in the distribution.
 *
 * This file contains prototypes for functions in WinHugs.c
 * ------------------------------------------------------------------------*/

#define __WINHUGS_H


#define FILES_TO_REMEMBER	10

typedef struct {
  WORD MenuId;					/* Menu identifier            */
  WORD FirstMenuId;				/* First file item into menu  */
  CHAR FileNames[FILES_TO_REMEMBER][_MAX_PATH]; /* Files full names           */
  UINT Length;                                  /* Files currently added      */
} FILENAMESMENU;


static VOID 	 local	DoAbout 	  	      Args((HWND, UINT, WPARAM, LPARAM));
static VOID 	 local	DoBrowseClasses	  	      Args((HWND, UINT, WPARAM, LPARAM));
static VOID 	 local	DoBrowseTycons	  	      Args((HWND, UINT, WPARAM, LPARAM));
static VOID 	 local	DoBrowseNames	  	      Args((HWND, UINT, WPARAM, LPARAM));
static VOID 	 local	DoClose 	  	      Args((HWND, UINT, WPARAM, LPARAM));
static VOID 	 local	DoCommand 	  	      Args((HWND, UINT, WPARAM, LPARAM));
static INT  	 local	DoCreate 	  	      Args((HWND, UINT, WPARAM, LPARAM));
static VOID 	 local	DoDestroy 	  	      Args((HWND, UINT, WPARAM, LPARAM));
static VOID 	 local	DoDropFiles 		      Args((HWND, UINT, WPARAM, LPARAM));
static VOID 	 local	DoGetMinMaxInfo   	      Args((HWND, UINT, WPARAM, LPARAM));
static VOID 	 local 	DoInitMenu	   	      Args((HWND, UINT, WPARAM, LPARAM));
static VOID 	 local	DoMove	 	  	      Args((HWND, UINT, WPARAM, LPARAM));
static VOID 	 local 	DoOptions 	  	      Args((HWND, UINT, WPARAM, LPARAM));
static VOID 	 local 	DoScriptMan 	  	      Args((HWND, UINT, WPARAM, LPARAM));
static VOID      local  DrawClassesHierarchy	      Args((VOID));
static LPSTR     local  ExpandFileName		      Args((LPSTR));
static CHAR*   	 local	GetaFileName	   	      Args((HWND, UINT));
static CHAR*     local  GetFileNameFromFileNamesMenu  Args((FILENAMESMENU*, UINT));
static VOID      local  GetFromRegistryFileNamesMenu  Args((FILENAMESMENU*, LPSTR));
static VOID 	 local  GetFromRegistryFont	      Args((CHAR*, INT, INT*, INT*));
static int	 local  GetFromRegistryDocPath	      Args((char *HelpPath, int));
static VOID 	 local  GetFromRegistryDialogFont     Args((CHAR*, INT, INT*));
static VOID 	 local  GetFromRegistryScreenSize     Args((INT*, INT *));
static VOID      local  GetFromRegistryScreenPosition Args((INT*, INT *));
static BOOL 	 local	InitApplication		      Args((VOID));
static VOID      local  InitFileNamesMenu             Args((WORD, WORD, FILENAMESMENU*)); 
static BOOL 	 local	InitInstance 	   	      Args((LPSTR, INT));
static VOID 	 local  InitMenus		      Args((VOID));
static VOID      local  OpenHtml		      Args((LPSTR));
static VOID      local  OpenHtmlFromDocs	      Args((LPSTR));
static VOID      local  SaveToRegistryFileNamesMenu   Args((FILENAMESMENU*, LPSTR));
static VOID 	 local  SaveToRegistryWinPos 	      Args((VOID));
static VOID 	 local 	SaveToRegistryWorkingDir      Args((VOID));
static VOID 	 local  SaveToRegistryMenus	      Args((VOID));
static VOID	 local  SetInterpreterCommand	      Args((LPCSTR, ...));

extern VOID      AddFileToFileNamesMenu   Args((FILENAMESMENU*, LPSTR));
extern VOID	 ReadGUIOptions		  Args((VOID));
extern VOID      SaveGUIOptions           Args((VOID));

extern 	HCURSOR 	GarbageCursor;
extern	HCURSOR		SaveCursor;

extern  FILENAMESMENU   FilesMenu, EditMenu;


extern Void loopInBackground  Args((Void));
extern Void startEvaluatorThread Args((Void));

extern Bool InAutoReloadFiles;
