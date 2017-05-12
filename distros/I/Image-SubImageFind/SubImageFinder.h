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
#ifndef _SUBIMAGEFINDER_H
#define _SUBIMAGEFINDER_H

#include "ImageProcessor.h"

/*
 * Abstraction layer for comparison routines.
 */
class SubImageFinder {
public:
	enum ComparisonMethod { CM_DWVB = 0, CM_GPC = 1 };
	SubImageFinder(char *hayFile, int compareMethod);
	SubImageFinder(char *hayFile, char *needleFile, int compareMethod);
	SubImageFinder(char *hayFile, char *needleFile, ComparisonMethod compareMethod);
	SubImageFinder(const string &hayFile, const string &needleFile, ComparisonMethod compareMethod);
	~SubImageFinder();
	bool getCoordinates(size_t &x, size_t &y);
	void setMaxDelta(unsigned long maxDelta);
	unsigned long getMaxDelta();
	void loadNeedle(char *needleFile);
protected:
	void Initialize(const string &hayFile, const string &needleFile, ComparisonMethod compareMethod);
private:
	ImageProcessor *imgProcessor;
};


#endif
