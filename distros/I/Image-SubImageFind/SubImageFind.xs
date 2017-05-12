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
#ifdef __cplusplus
extern "C" {
#endif
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#ifdef __cplusplus
}
#endif
#include "ppport.h"

#include "SubImageFinder.h"
#include "ImageProcessor.h"
#include <iostream>

MODULE = Image::SubImageFind		PACKAGE = Image::SubImageFind		
PROTOTYPES: DISABLE

#SubImageFinder *
#SubImageFinder::new(char *hayFile, char *needleFile, int compareMethod)

# Allow for optional parameters
SubImageFinder *
SubImageFinder::new(hayFile, needleFile = "", compareMethod = 0)
	char *hayFile
	char *needleFile
	int compareMethod
CODE:
	if (*needleFile) {
		RETVAL = new SubImageFinder(hayFile, needleFile, compareMethod);
	} else {
		RETVAL = new SubImageFinder(hayFile, compareMethod);
	}
OUTPUT:
	RETVAL

void
SubImageFinder::DESTROY()

void 
SubImageFinder::SetMaxDelta(unsigned long maxDelta)
PPCODE:
	THIS->setMaxDelta(maxDelta);	

unsigned long 
SubImageFinder::GetMaxDelta()
CODE:
	RETVAL = THIS->getMaxDelta();
OUTPUT:
	RETVAL

void
SubImageFinder::GetCoordinates(needleFile = "")
	char *needleFile
PREINIT:
	size_t x = -1, y = -1;
	bool retval = false;
PPCODE:
	if (*needleFile) {
		THIS->loadNeedle(needleFile);
	}
	retval = THIS->getCoordinates(x, y);
	EXTEND(SP, 3);
	PUSHs( sv_2mortal(newSViv((IV)x)) );
	PUSHs( sv_2mortal(newSViv((IV)y)) );
	PUSHs( sv_2mortal(newSViv((IV)retval)) );
	XSRETURN(3);

