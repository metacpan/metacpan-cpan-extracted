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
#include <stdlib.h>
#include <string.h>
#include <malloc.h>
#include <assert.h>
#include <math.h>
#include <fftw3.h>
#include <Magick++.h>
#include "GPC.h"


bool GPC::getCoordinates(size_t &x, size_t &y)
{
	x = y = -1; // initialize
	for (size_t hy = 0; hy < this->hayImage.rows(); hy++) {
		for (size_t hx = 0; hx < this->hayImage.columns(); hx++)	{
			long long ret = checkRegion(hx, hy);
			if (ret >= 0) {
				x = hx;
				y = hy;
				return true;
			}
		}
	}
	return false;
}

long long GPC::checkRegion(size_t x, size_t y)
{
	unsigned long maxDelta = this->getMaxDelta();
	unsigned long delta = 0;
	bool searched = false;

	if (x > (this->hayImage.columns() - this->needleImage.columns())) {
		// No room left for needle
		return -3;
	} else if (y > (this->hayImage.rows() - this->needleImage.rows())) {
		// No room left for needle
		return -3;
	}

	for (size_t ny = 0; ny < this->needleImage.rows(); ny++) {
		for (size_t nx = 0; nx < this->needleImage.columns(); nx++)	{
			searched = true;
			PixelPacket hayPixel = this->hayPixels[(x+nx) + (y+ny) * this->hayImage.columns()];
			PixelPacket needlePixel = this->needlePixels[nx + ny * this->needleImage.columns()];

			unsigned long pd = 0;
			pd = labs(hayPixel.red - needlePixel.red);
			pd += labs(hayPixel.green - needlePixel.green);
			pd += labs(hayPixel.blue - needlePixel.blue);
			pd += labs(hayPixel.opacity - needlePixel.opacity);
			delta += pd;

			if (delta > maxDelta) {
				// bail if delta is too different
				return -2;
			}
		}
	}

	if (searched) {
		return delta;
	} else {
		return -1;
	}
}

