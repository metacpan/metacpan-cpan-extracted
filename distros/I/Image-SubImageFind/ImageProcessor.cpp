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
#include "ImageProcessor.h"

/*
 * Constructor
 */
ImageProcessor::ImageProcessor(const string &haystackFile, const string &needleFile)
{
	loadHaystack(haystackFile);
	loadNeedle(needleFile);
}

ImageProcessor::ImageProcessor(const string &haystackFile)
{
	loadHaystack(haystackFile);
}

bool ImageProcessor::loadHaystack(const string &haystackFile)
{
	if (!haystackFile.empty()) {
		this->haystackFile = haystackFile;
		this->hayImage.read(haystackFile);
		this->hayPixels = this->hayImage.getPixels(0, 0, this->hayImage.columns(), this->hayImage.rows());
		return true;
	}
	return false;
}

bool ImageProcessor::loadNeedle(const string &needleFile)
{
	if (!needleFile.empty()) {
		this->needleFile = needleFile;
		this->needleImage.read(needleFile);
		this->needlePixels = this->needleImage.getPixels(0, 0, this->needleImage.columns(), this->needleImage.rows());
		return true;	
	}
	return false;
}

/*
 * Sets the max delta of the comparison.  This is currently only
 * used in the GPC (Generic Pixel Comparison) algorithm.
 */
void ImageProcessor::setMaxDelta(unsigned long maxDelta)
{
	this->maxDelta = maxDelta;
}

/*
 * Get the current value of the max delta.
 */
unsigned long ImageProcessor::getMaxDelta()
{
	return this->maxDelta;
}


/*
 * Utility function to read all pixels of an image as grayscale.  Used
 * in one or more comparison mechanisms.
 *
 * Caller is responsible for freeing the signed2* returned.
 *
 */
signed2* ImageProcessor::readImageGrayscale(Image image, size_t &sx, size_t &sy)
{
    sx = image.columns();
    sy = image.rows();

    signed2 *img = (signed2 *)malloc(sizeof(signed2) * (sx) * (sy));

    Color color;

    size_t x = 0;
    size_t y = 0;
    for ( x = 0; x < sx; x++ )
    {
        for ( y = 0; y < sy; y++ )
        {
        	color = image.pixelColor(x, y);
        	// get grayscale value for pixel
            img[x + y * ( sx ) ] =
                ( signed2 ) ( color.redQuantum() * 11 + color.greenQuantum() * 16 +
                		color.blueQuantum() * 5 ) / 32;
        }
    }
    return img;
}
