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
#ifndef _DWVB_H
#define _DWVB_H

#include "ImageProcessor.h"

using namespace Magick;

class DWVB : public ImageProcessor {
public:
	DWVB(const string &hayFilePath, const string &needleFilePath) : ImageProcessor(hayFilePath, needleFilePath) {}
	DWVB(const string &hayFilePath) : ImageProcessor(hayFilePath) {}
	bool getCoordinates(size_t &x, size_t &y);
private:
	signed2* boxaverage(signed2 *input, int sx, int sy, int wx, int wy);
	void window(signed2 *img, int sx, int sy, int wx, int wy);
	signed2* readImage(Image *image, size_t &sx, size_t &sy);
	void normalize (signed2 *img, int sx, int sy, int wx, int wy);
};


#endif
