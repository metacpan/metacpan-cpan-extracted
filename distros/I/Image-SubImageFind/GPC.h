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
#ifndef _GPC_H
#define _GPC_H

#include <Magick++.h>
#include "ImageProcessor.h"

#define DEFAULT_MAX_DELTA 6000000

using namespace std;
using namespace Magick;

class GPC : public ImageProcessor {
public:
	GPC(const string &hayFilePath, const string &needleFilePath) : ImageProcessor(hayFilePath, needleFilePath)
	{ this->setMaxDelta(DEFAULT_MAX_DELTA); }
	GPC(const string &hayFilePath) : ImageProcessor(hayFilePath)
	{ this->setMaxDelta(DEFAULT_MAX_DELTA); }
	bool getCoordinates(size_t &x, size_t &y);
private:
	long long checkRegion(size_t x, size_t y);
};


#endif
