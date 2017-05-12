/* Image::SubImageFind ($Id$)
 *
 * Copyright (c) 2010-2011  Dennis K. Paulsen, All Rights Reserved.
 * Email: ctrondlp@cpan.org
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License as
 * published by the Free Software Foundation; either version 2 of
 * the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, see <http://www.gnu.org/licenses>.
 *
 */
#ifndef _IMAGEPROCESSOR_H
#define _IMAGEPROCESSOR_H

#include <iostream>
#include <string>
#include <Magick++.h>

typedef unsigned char unsigned1;
typedef signed short signed2;
typedef signed long long signed8;

using namespace std;
using namespace Magick;

class ImageProcessor {
public:
	ImageProcessor(const string &haystackFile, const string &needleFile);
	ImageProcessor(const string &haystackFile);
	virtual bool getCoordinates(size_t &x, size_t &y) { return false; }
	void setMaxDelta(unsigned long maxDelta);
	unsigned long getMaxDelta();
	static signed2* readImageGrayscale(Image image, size_t &sx, size_t &sy);
	bool loadHaystack(const string &haystackFile);
	bool loadNeedle(const string &needleFile);
protected:
	string haystackFile;
	string needleFile;
	const PixelPacket *hayPixels;
	const PixelPacket *needlePixels;
	Image hayImage;
	Image needleImage;
private:
	unsigned long maxDelta;
};


#endif
