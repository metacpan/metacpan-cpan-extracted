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
#include <iostream>
#include "SubImageFinder.h"
#include "ImageProcessor.h"
#include "GPC.h"
#include "DWVB.h"

SubImageFinder::SubImageFinder(char *hayFile, int compareMethod)
{
	string hFile(hayFile);
	Initialize(hFile, "", (ComparisonMethod)compareMethod);
}

SubImageFinder::SubImageFinder(char *hayFile, char *needleFile, int compareMethod)
{
	string hFile(hayFile);
	string nFile(needleFile);
	Initialize(hFile, nFile, (ComparisonMethod)compareMethod);
}

SubImageFinder::SubImageFinder(char *hayFile, char *needleFile, ComparisonMethod compareMethod)
{
	string hFile(hayFile);
	string nFile(needleFile);
	Initialize(hFile, nFile, compareMethod);
}

SubImageFinder::SubImageFinder(const string &hayFile, const string &needleFile, ComparisonMethod compareMethod)
{
	Initialize(hayFile, needleFile, compareMethod);
}

void SubImageFinder::Initialize(const string &hayFile, const string &needleFile, ComparisonMethod compareMethod)
{
	if (compareMethod == CM_DWVB) {
		this->imgProcessor = new DWVB(hayFile, needleFile);
	} else if (compareMethod == CM_GPC) {
		this->imgProcessor = new GPC(hayFile, needleFile);
	} else {
		throw "Unknown compare method specified: " + compareMethod;
	}
}

SubImageFinder::~SubImageFinder()
{
	delete this->imgProcessor;
}

bool SubImageFinder::getCoordinates(size_t &x, size_t &y)
{
	return this->imgProcessor->getCoordinates(x, y);
}

void SubImageFinder::setMaxDelta(unsigned long maxDelta)
{
	this->imgProcessor->setMaxDelta(maxDelta);
}

unsigned long SubImageFinder::getMaxDelta()
{
	return this->imgProcessor->getMaxDelta();
}

void SubImageFinder::loadNeedle(char *needleFile)
{
	string nFile(needleFile);
	this->imgProcessor->loadNeedle(nFile);
}
