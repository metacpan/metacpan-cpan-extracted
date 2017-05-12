// Copyright 2010 Kevin Ryde
//
// This file is part of Image-Base-PNGwriter.
//
// Image-Base-PNGwriter is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License as published
// by the Free Software Foundation; either version 3, or (at your option)
// any later version.
//
// Image-Base-PNGwriter is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
// Public License for more details.
//
// You should have received a copy of the GNU General Public License along
// with Image-Base-PNGwriter.  If not, see <http://www.gnu.org/licenses/>.

#include <pngwriter.h>

int
main (void)
{
  pngwriter foo(20, 10, 0, "/tmp/foo.png");

  // filename==NULL segv
  //     const char *filename = "";
  //     foo.pngwriter_rename (filename);
  //     foo.write_png();

  foo.plot(1,1, 0x11, 0x22, 0x33);
  std::cout << "dread "
            << foo.dread(1,1,1) << " "
            << foo.dread(1,1,3) << " "
            << foo.dread(1,1,2) << std::endl;

  pngwriter bar (foo);
  std::cout << "dread "
            << bar.dread(1,1,1) << " "
            << bar.dread(1,1,3) << " "
            << bar.dread(1,1,2) << std::endl;

  return 0;
}
