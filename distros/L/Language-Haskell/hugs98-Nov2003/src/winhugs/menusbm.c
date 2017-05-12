
////////////////////////////////////

VOID WINAPI DrawCheck(HDC hdc, SIZE size) 
{ 
    HBRUSH hbrOld; 
    hbrOld = SelectObject(hdc, GetStockObject(NULL_BRUSH)); 
    Rectangle(hdc, 0, 0, size.cx, size.cy); 
    MoveToEx(hdc, 0, 0, NULL); 
    LineTo(hdc, size.cx, size.cy); 
    MoveToEx(hdc, 0, size.cy - 1, NULL); 
    LineTo(hdc, size.cx - 1, 0); 
    SelectObject(hdc, hbrOld); 
} 
 
VOID WINAPI DrawUncheck(HDC hdc, SIZE size) 
{ 
    HBRUSH hbrOld; 
    hbrOld = SelectObject(hdc, GetStockObject(NULL_BRUSH)); 
    Rectangle(hdc, 0, 0, size.cx, size.cy); 
    SelectObject(hdc, hbrOld); 
} 

// Function-pointer type for drawing functions 
 
typedef VOID (WINAPI * DRAWFUNC)(HDC hdc, SIZE size);
 

HBITMAP WINAPI CreateMenuBitmap(DRAWFUNC lpfnDraw) 
{ 
    // Create a DC compatible with the desktop window's DC. 
 
    HWND hwndDesktop = GetDesktopWindow(); 
    HDC hdcDesktop = GetDC(hwndDesktop); 
    HDC hdcMem = CreateCompatibleDC(hdcDesktop); 
 
    // Determine the required bitmap size. 
 
    DWORD dwExt = GetMenuCheckMarkDimensions(); 
    SIZE size = { LOWORD(dwExt), HIWORD(dwExt) }; 
 
    // Create a monochrome bitmap and select it. 
 
    HBITMAP hbm = CreateBitmap(size.cx, size.cy, 1, 1, NULL); 
    HBITMAP hbmOld = SelectObject(hdcMem, hbm); 
 
    // Erase the background and call the drawing function. 
 
    PatBlt(hdcMem, 0, 0, size.cx, size.cy, WHITENESS); 
    (*lpfnDraw)(hdcMem, size); 
 
    // Clean up. 
 
    SelectObject(hdcMem, hbmOld); 
    DeleteDC(hdcMem); 
    ReleaseDC(hwndDesktop, hdcDesktop); 
    return hbm; 
} 



static local VOID SetMenuBitmap(HMENU hMenu, UINT MenuId, CHAR* BitmapName, UINT Sizex, UINT Sizey) 
{
  HBITMAP hBitmap;
  hBitmap = ResizeBitmap(LoadMappedBitmap(hThisInstance, BitmapName), Sizex, Sizey);
    
  SetMenuItemBitmaps(hMenu, MenuId, MF_BYCOMMAND, hBitmap, hBitmap); 
}
 
BOOL WINAPI SetMenuBitmaps(HWND hwnd) 
{ 
    HMENU hmenuBar = GetMenu(hwnd); 


    DWORD dwExt = GetMenuCheckMarkDimensions(); 
    SIZE size = { LOWORD(dwExt), HIWORD(dwExt) }; 
    
    SetMenuBitmap(hmenuBar, ID_EXIT,            "EXITBUTTON",      size.cx, size.cy);
    SetMenuBitmap(hmenuBar, ID_OPEN,            "OPENFILEBUTTON",  size.cx, size.cy);
    SetMenuBitmap(hmenuBar, ID_SCRIPTMAN,       "SCRIPTMANBUTTON", size.cx, size.cy);

    SetMenuBitmap(hmenuBar, ID_CUT,             "CUTBUTTON",       size.cx, size.cy);
    SetMenuBitmap(hmenuBar, ID_COPY,            "COPYBUTTON",      size.cx, size.cy);
    SetMenuBitmap(hmenuBar, ID_PASTE,           "PASTEBUTTON",     size.cx, size.cy);
    SetMenuBitmap(hmenuBar, ID_CLEAR,           "DELETEBUTTON",    size.cx, size.cy);
    SetMenuBitmap(hmenuBar, ID_GOEDIT,          "EDITBUTTON",      size.cx, size.cy);

    SetMenuBitmap(hmenuBar, ID_RUN,             "RUNBUTTON",       size.cx, size.cy);
    SetMenuBitmap(hmenuBar, ID_STOP,            "STOPBUTTON",      size.cx, size.cy);
    SetMenuBitmap(hmenuBar, ID_MAKE,            "MAKEBUTTON",      size.cx, size.cy);
    SetMenuBitmap(hmenuBar, ID_SETOPTIONS,      "OPTIONSBUTTON",   size.cx, size.cy);

    SetMenuBitmap(hmenuBar, ID_BROWSEHIERARCHY, "HIERARCHYBUTTON", size.cx, size.cy);

    SetMenuBitmap(hmenuBar, ID_HELPINDEX,       "HELPBUTTON",      size.cx, size.cy);
 
    return TRUE; 
} 



////////////////////////////////////



