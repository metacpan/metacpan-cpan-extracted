// Copyright 2012 Kevin Ryde
// 
// This file is part of Image-Base-Wx.
// 
// Image-Base-Wx is free software; you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by the
// Free Software Foundation; either version 3, or (at your option) any later
// version.
// 
// Image-Base-Wx is distributed in the hope that it will be useful, but
// WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
// or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
// for more details.
// 
// You should have received a copy of the GNU General Public License along
// with Image-Base-Wx.  If not, see <http://www.gnu.org/licenses/>.

#include "wx/wx.h"

class MyApp: public wxApp
{
    virtual bool OnInit();
};
IMPLEMENT_APP(MyApp)

bool MyApp::OnInit()
{
  wxBitmap bm(10,10);
  bm.LoadFile (wxT("/dev/null"),wxBITMAP_TYPE_XPM);
  return false;
}
