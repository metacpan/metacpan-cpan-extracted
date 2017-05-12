/* --------------------------------------------------------------------------
 * WinUtils.c:	José Enrique Gallardo Ruiz, Feb 1999
 *
 * The Hugs 98 system is Copyright (c) José Enrique Gallardo, Mark P Jones,
 * Alastair Reid, the Yale Haskell Group, and the OGI School of
 * Science & Engineering at OHSU, 1994-2003, All rights reserved.  It is
 * distributed as free software under the license in the file "License",
 * which is included in the distribution.
 *
 * Common functions
 * ------------------------------------------------------------------------*/


#include "..\Prelude.h"

#if HUGS_FOR_WINDOWS
#define STRICT 1


#include "WinUtils.h"
#include <StdLib.h>
#include <direct.h>


/* Default colors used to map the DIB colors	*/
/* to the current system colors:                */
#define MAPPED_BUTTONTEXT      (RGB(000,000,000))  /* black          */
#define MAPPED_BUTTONSHADOW    (RGB(128,000,000))  /* dark red       */
#define MAPPED_BUTTONFACE      (RGB(255,000,255))  /* bright magenta */
#define MAPPED_BUTTONHILIGHT   (RGB(255,255,255))  /* white          */


/* Executes the dialog with DlgId identifier using lpDlgProc */
VOID ExecDialog (HINSTANCE hInstance, WORD DlgId, WNDPROC lpDlgProc)
{
  DLGPROC lpProcedure;

  lpProcedure = (DLGPROC)MakeProcInstance((FARPROC)lpDlgProc, hInstance);
  DialogBox(hInstance, MAKEINTRESOURCE(DlgId), GetFocus(), lpProcedure);
  FreeProcInstance((FARPROC)lpProcedure);
}

/* Check whether the extension of file FileName is Ext */
BOOL CheckExt (LPCSTR FileName, LPCSTR Ext)
{
   CHAR currentExt[_MAX_EXT];

   /* try to get extension */
   _splitpath (FileName, NULL, NULL, NULL, currentExt);

   return !stricmp (currentExt, Ext);
}


/* Obtain full file's path */
VOID FullPath (LPSTR Dest, LPCSTR Src)
{
   CHAR path[_MAX_PATH];

   /* try to get path */
   _splitpath (Src, NULL, path, NULL, NULL);

   if (path[0]) {
     strcpy(Dest, Src);
   }
   else {
     _fullpath(Dest, Src, _MAX_PATH);
   }
   strlwr(Dest);
}



/* builds a short name for a file path of maximum length MAX_SHORTNAME */
#define MAX_SHORTNAME	40

VOID ShortFileName(CHAR *SrcFileName, CHAR *DestFileName)
{
   CHAR dir[_MAX_PATH], shortDir[_MAX_PATH], shortAux[_MAX_PATH];
   CHAR ext[_MAX_EXT];
   CHAR drive[_MAX_DRIVE];
   CHAR fName[_MAX_FNAME];
   CHAR *ptr;
   BOOL Stop = FALSE;

   /* try to get path */
   _splitpath (SrcFileName, drive, dir, fName, ext);

   /* delete last '\\' char */
   ptr = strrchr(dir,'\\'); 
   if (ptr)
     *ptr = (CHAR)0;

   wsprintf(shortDir, "\\%s%s", fName, ext);
   
   while (*dir && !Stop) {
     ptr = strrchr(dir,'\\');

     if(strlen(shortDir)+strlen(ptr) < MAX_SHORTNAME) {
       /* shortDir = ptr ++ shortDir */
       sprintf(shortAux, "%s%s", ptr, shortDir);
       strcpy(shortDir, shortAux);

       /* delete appended string from dir */
       *ptr = (CHAR)0;
     }
     else
       Stop = TRUE;
   }

   if (*dir)
     wsprintf(DestFileName, "%s\\...%s",drive,shortDir);
   else
     wsprintf(DestFileName, "%s%s",drive,shortDir);

}




/* Draws a bitmap, making cTransparentColor transparent */
VOID DrawTransparentBitmap(HDC hdc, HBITMAP hBitmap, UINT xStart, UINT yStart, COLORREF cTransparentColor)
{
   BITMAP     bm;
   COLORREF   cColor;
   HBITMAP    bmAndBack, bmAndObject, bmAndMem, bmSave;
   HBITMAP    bmBackOld, bmObjectOld, bmMemOld, bmSaveOld;
   HDC        hdcMem, hdcBack, hdcObject, hdcTemp, hdcSave;
   POINT      ptSize;


   hdcTemp = CreateCompatibleDC(hdc);
   SelectObject(hdcTemp, hBitmap);   // Select the bitmap

   GetObject(hBitmap, sizeof(BITMAP), (LPSTR)&bm);
   ptSize.x = bm.bmWidth;            // Get width of bitmap

   ptSize.y = bm.bmHeight;           // Get height of bitmap
   DPtoLP(hdcTemp, &ptSize, 1);      // Convert from device
				     // to logical points

   // Create some DCs to hold temporary data.
   hdcBack   = CreateCompatibleDC(hdc);
   hdcObject = CreateCompatibleDC(hdc);
   hdcMem    = CreateCompatibleDC(hdc);
   hdcSave   = CreateCompatibleDC(hdc);

   // Create a bitmap for each DC. DCs are required for a number of
   // GDI functions.

   // Monochrome DC
   bmAndBack   = CreateBitmap(ptSize.x, ptSize.y, 1, 1, NULL);

   // Monochrome DC
   bmAndObject = CreateBitmap(ptSize.x, ptSize.y, 1, 1, NULL);

   bmAndMem    = CreateCompatibleBitmap(hdc, ptSize.x, ptSize.y);
   bmSave      = CreateCompatibleBitmap(hdc, ptSize.x, ptSize.y);

   // Each DC must select a bitmap object to store pixel data.
   bmBackOld   = SelectObject(hdcBack, bmAndBack);
   bmObjectOld = SelectObject(hdcObject, bmAndObject);
   bmMemOld    = SelectObject(hdcMem, bmAndMem);
   bmSaveOld   = SelectObject(hdcSave, bmSave);

   // Set proper mapping mode.
   SetMapMode(hdcTemp, GetMapMode(hdc));

   // Save the bitmap sent here, because it will be overwritten.
   BitBlt(hdcSave, 0, 0, ptSize.x, ptSize.y, hdcTemp, 0, 0, SRCCOPY);

   // Set the background color of the source DC to the color.
   // contained in the parts of the bitmap that should be transparent
   cColor = SetBkColor(hdcTemp, cTransparentColor);

   // Create the object mask for the bitmap by performing a BitBlt
   // from the source bitmap to a monochrome bitmap.
   BitBlt(hdcObject, 0, 0, ptSize.x, ptSize.y, hdcTemp, 0, 0,
	  SRCCOPY);

   // Set the background color of the source DC back to the original
   // color.
   SetBkColor(hdcTemp, cColor);

   // Create the inverse of the object mask.
   BitBlt(hdcBack, 0, 0, ptSize.x, ptSize.y, hdcObject, 0, 0,
	  NOTSRCCOPY);

   // Copy the background of the main DC to the destination.
   BitBlt(hdcMem, 0, 0, ptSize.x, ptSize.y, hdc, xStart, yStart,
	  SRCCOPY);

   // Mask out the places where the bitmap will be placed.
   BitBlt(hdcMem, 0, 0, ptSize.x, ptSize.y, hdcObject, 0, 0, SRCAND);

   // Mask out the transparent colored pixels on the bitmap.
   BitBlt(hdcTemp, 0, 0, ptSize.x, ptSize.y, hdcBack, 0, 0, SRCAND);

   // XOR the bitmap with the background on the destination DC.
   BitBlt(hdcMem, 0, 0, ptSize.x, ptSize.y, hdcTemp, 0, 0, SRCPAINT);

   // Copy the destination to the screen.
   BitBlt(hdc, xStart, yStart, ptSize.x, ptSize.y, hdcMem, 0, 0,
	  SRCCOPY);

   // Place the original bitmap back into the bitmap sent here.
   BitBlt(hdcTemp, 0, 0, ptSize.x, ptSize.y, hdcSave, 0, 0, SRCCOPY);

   // Delete the memory bitmaps.
   DeleteObject(SelectObject(hdcBack, bmBackOld));
   DeleteObject(SelectObject(hdcObject, bmObjectOld));
   DeleteObject(SelectObject(hdcMem, bmMemOld));
   DeleteObject(SelectObject(hdcSave, bmSaveOld));

   // Delete the memory DCs.
   DeleteDC(hdcMem);
   DeleteDC(hdcBack);
   DeleteDC(hdcObject);
   DeleteDC(hdcSave);

   DeleteDC(hdcTemp);
}


/* Draws a bitmap on a DC */
VOID DrawBitmap (HDC hDC, HBITMAP hBitmap, UINT left, UINT top)
{
   HBITMAP hOldBitmap;
   BITMAP  bm;
   HDC     hDCMemory;

   GetObject(hBitmap, sizeof(BITMAP), &bm);
   hDCMemory = CreateCompatibleDC(hDC);
   hOldBitmap = SelectObject(hDCMemory, hBitmap);
   BitBlt(hDC, left, top, bm.bmWidth, bm.bmHeight, hDCMemory, 0, 0, SRCCOPY);
   SelectObject(hDCMemory, hOldBitmap);
   DeleteDC(hDCMemory);
}


/* Call this function in WM_INITDIALOG to center the dialog in Parent window */
VOID CenterDialogInParent (HWND hDlg)
{
   RECT rDlg, rMain;

   GetWindowRect(hDlg, &rDlg);
   GetWindowRect(GetParent(hDlg), &rMain);

   SetWindowPos(hDlg, NULL,
       rMain.left+((rMain.right-rMain.left-(rDlg.right - rDlg.left))/2),
       rMain.top+((rMain.bottom-rMain.top-(rDlg.bottom - rDlg.top))/2),
       0, 0, SWP_NOSIZE | SWP_NOACTIVATE);
}




BOOL CALLBACK SetDialogFontProc(HWND hwndChild, LPARAM hFont) 
{ 
  SendMessage(hwndChild, WM_SETFONT, (WPARAM)hFont, (DWORD)TRUE);
  return TRUE;
}


/* Call this fucntion in WM_INITDIALOG to set a font for every control in the dialog */
VOID SetDialogFont (HWND hDlg, HFONT hFont)
{
                          
   EnumChildWindows(hDlg, SetDialogFontProc, (LPARAM) hFont);
}


/* change working directory */
INT SetWorkingDir (LPCSTR Src)
{
   CHAR path[_MAX_PATH];
   CHAR drive[_MAX_DRIVE];
   CHAR thePath[2*_MAX_PATH];

   /* ignore file name and extension */
   _splitpath (Src, drive, path, NULL, NULL);
   wsprintf(thePath,"%s%s",drive,path);

      /* Set path */
   return !SetCurrentDirectory(thePath);
}




/*************************************************************************
 *
 * ChangeBitmapColorDC()
 *
 * This function makes all pixels in the given DC that have the
 * color rgbOld have the color rgbNew.  This function is used by
 * ChangeBitmapColor().
 *
 * Parameters:
 *
 * HDC hdcBM        - Memory DC containing bitmap
 * LPBITMAP lpBM    - Long pointer to bitmap structure from hdcBM
 * COLORREF rgbOld  - Source color
 * COLORREF rgbNew  - Destination color
 *
 * Return value: none.
 *
 * History:   Date      Author      Reason
 *            6/10/91   CKindel     Created
 *            1/23/92   MarkBad     Added big nifty comments which explain
 *                                  how this works, split bitmap graying
 *                                  code out
 *
 *************************************************************************/

static VOID ChangeBitmapColorDC (HDC hdcBM, LPBITMAP lpBM,
				 COLORREF rgbOld, COLORREF rgbNew)
{
  HDC hdcMask;
  HBITMAP hbmMask, hbmOld;
  HBRUSH hbrOld;

  if (!lpBM)
    return;

  /* if the bitmap is mono we have nothing to do */
  if (lpBM->bmPlanes == 1 && lpBM->bmBitsPixel == 1)
    return;

  /* To perform the color switching, we need to create a monochrome
  // "mask" which is the same size as our color bitmap, but has all
  // pixels which match the old color (rgbOld) in the bitmap set to 1.
  //
  // We then use the ROP code "DSPDxax" to Blt our monochrome
  // bitmap to the color bitmap.  "D" is the Destination color
  // bitmap, "S" is the source monochrome bitmap, and "P" is the
  // selected brush (which is set to the replacement color (rgbNew)).
  // "x" and "a" represent the XOR and AND operators, respectively.
  //
  // The DSPDxax ROP code can be explained as having the following
  // effect:
  //
  // "Every place the Source bitmap is 1, we want to replace the
  // same location in our color bitmap with the new color.  All
  // other colors we leave as is."
  //
  // The truth table for DSPDxax is as follows:
  //
  //       D S P Result
  //       - - - ------
  //       0 0 0   0
  //       0 0 1   0
  //       0 1 0   0
  //       0 1 1   1
  //       1 0 0   1
  //       1 0 1   1
  //       1 1 0   0
  //       1 1 1   1
  //
  // (Even though the table is assuming monochrome D (Destination color),
  // S (Source color), & P's (Pattern color), the results apply to color
  // bitmaps also).
  //
  // By examining the table, every place that the Source is 1
  // (source bitmap contains a 1), the result is equal to the
  // Pattern at that location.  Where S is zero, the result equals
  // the Destination.
  //
  // See Section 11.2 (page 11-4) of the "Reference -- Volume 2" for more
  // information on the Termary Raster Operation codes.
  */

  if (hbmMask = CreateBitmap(lpBM->bmWidth, lpBM->bmHeight, 1, 1, NULL)) {
    if (hdcMask = CreateCompatibleDC(hdcBM)) {
      /* Select th mask bitmap into the mono DC */
      hbmOld = SelectObject(hdcMask, hbmMask);

      /* Create the brush and select it into the source color DC  */
      /* this is our "Pattern" or "P" color in our DSPDxax ROP.   */
      hbrOld = SelectObject(hdcBM, CreateSolidBrush(rgbNew));

      /* To create the mask, we will use a feature of BitBlt -- when
      // converting from Color to Mono bitmaps, all Pixels of the
      // background colors are set to WHITE (1), and all other pixels
      // are set to BLACK (0).  So all pixels in our bitmap that are
      // rgbOld color, we set to 1.
      */

      SetBkColor(hdcBM, rgbOld);
      BitBlt(hdcMask, 0, 0, lpBM->bmWidth, lpBM->bmHeight,
	     hdcBM, 0, 0, SRCCOPY);

      /* Where the mask is 1, lay down the brush, where it */
      /* is 0, leave the destination.                      */

      #define RGBBLACK     	RGB(0,0,0)
      #define RGBWHITE     	RGB(255,255,255)
      #define DSa       	0x008800C6L
      #define DSo       	0x00EE0086L
      #define DSx       	0x00660045L
      #define DSPDxax   	0x00E20746L

      SetBkColor(hdcBM, RGBWHITE);
      SetTextColor(hdcBM, RGBBLACK);

      BitBlt(hdcBM, 0, 0, lpBM->bmWidth, lpBM->bmHeight,
	     hdcMask, 0, 0, DSPDxax);

      SelectObject(hdcMask, hbmOld);

      hbrOld = SelectObject(hdcBM, hbrOld);
      DeleteObject(hbrOld);

      DeleteDC(hdcMask);
    }
    else
      return;

    DeleteObject(hbmMask);
  }
  else
    return;
}


VOID MapBitmap (HBITMAP hbmSrc, COLORREF rgbOld, COLORREF rgbNew)
{
  HDC 		hDC, hdcMem;
  BITMAP 	bmBits;

  if (hDC = GetDC(NULL)) {
    if (hdcMem = CreateCompatibleDC(hDC)) {

      /* Get the bitmap struct needed by ChangeBitmapColorDC() */
      GetObject(hbmSrc, sizeof(BITMAP), (LPSTR)&bmBits);

      /* Select our bitmap into the memory DC */
      hbmSrc = SelectObject(hdcMem, hbmSrc);

      /* Translate the sucker */
      ChangeBitmapColorDC(hdcMem, &bmBits, rgbOld, rgbNew);

      /* Unselect our bitmap before deleting the DC */
      hbmSrc = SelectObject(hdcMem, hbmSrc);

      DeleteDC(hdcMem);
    }
    ReleaseDC(NULL, hDC);
  }
}


/* Loads a bitmap and maps system colors */
HBITMAP LoadMappedBitmap (HINSTANCE hInstance, LPCSTR BitmapName)
{
  HBITMAP hBitmap;

  hBitmap = LoadBitmap (hInstance, BitmapName);
  MapBitmap (hBitmap, MAPPED_BUTTONHILIGHT, GetSysColor(COLOR_BTNHIGHLIGHT));
  MapBitmap (hBitmap, MAPPED_BUTTONTEXT,    GetSysColor(COLOR_BTNTEXT));
  MapBitmap (hBitmap, MAPPED_BUTTONSHADOW,  GetSysColor(COLOR_BTNSHADOW));
  MapBitmap (hBitmap, MAPPED_BUTTONFACE,    GetSysColor(COLOR_BTNFACE));

  return hBitmap;
}



HBITMAP ResizeBitmap (HBITMAP SrcBitmap, UINT x, UINT y) 
{
  BITMAP bmBits;
  HBITMAP DestBitmap, svBitmap1, svBitmap2;
  HDC hdcMem1, hdcMem2;

  
  HWND hwndDesktop = GetDesktopWindow(); 
  HDC hdcDesktop = GetDC(hwndDesktop); 

  hdcMem1 = CreateCompatibleDC(hdcDesktop);
  hdcMem2 = CreateCompatibleDC(hdcDesktop);

  /* Create and select new bitmap */
  DestBitmap =CreateCompatibleBitmap(hdcDesktop, x, y);
  svBitmap2 = SelectObject(hdcMem2, DestBitmap);
  
  /* Select our bitmap into the memory DC and get its size */
  svBitmap1 = SelectObject(hdcMem1, SrcBitmap);
  GetObject(SrcBitmap, sizeof(BITMAP), (LPSTR)&bmBits);

  /* Translate the sucker */
  StretchBlt(hdcMem2, 0, 0, x, y, hdcMem1, 0, 0, bmBits.bmWidth, bmBits.bmHeight, SRCCOPY);
 
  /* Unselect our bitmap before deleting the DC */
  SelectObject(hdcMem1, svBitmap1);

  SelectObject(hdcMem2, svBitmap2);

  DeleteDC(hdcMem2);
  DeleteDC(hdcMem1);

  ReleaseDC(hwndDesktop, hdcDesktop);
  return DestBitmap;
}


#endif // HUGS_FOR_WINDOWS
