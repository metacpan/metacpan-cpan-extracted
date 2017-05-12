//  ***** BEGIN LICENSE BLOCK *****
//  Version: MPL 1.1/GPL 2.0/LGPL 2.1
// 
//  The contents of this file are subject to the Mozilla Public License Version
//  1.1 (the "License"); you may not use this file except in compliance with
//  the License. You may obtain a copy of the License at
//  http://www.mozilla.org/MPL/
// 
//  Software distributed under the License is distributed on an "AS IS" basis,
//  WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License
//  for the specific language governing rights and limitations under the
//  License.
// 
//  The Original Code is Encode::Detect wrapper
// 
//  The Initial Developer of the Original Code is
//  Proofpoint, Inc.
//  Portions created by the Initial Developer are Copyright (C) 2005
//  the Initial Developer. All Rights Reserved.
// 
//  Contributor(s):
// 
//  Alternatively, the contents of this file may be used under the terms of
//  either the GNU General Public License Version 2 or later (the "GPL"), or
//  the GNU Lesser General Public License Version 2.1 or later (the "LGPL"),
//  in which case the provisions of the GPL or the LGPL are applicable instead
//  of those above. If you wish to allow use of your version of this file only
//  under the terms of either the GPL or the LGPL, and not to allow others to
//  use your version of this file under the terms of the MPL, indicate your
//  decision by deleting the provisions above and replace them with the notice
//  and other provisions required by the GPL or the LGPL. If you do not delete
//  the provisions above, a recipient may use your version of this file under
//  the terms of any one of the MPL, the GPL or the LGPL.
// 
//  ***** END LICENSE BLOCK *****

extern "C" {
#define PERL_NO_GET_CONTEXT     /* we want efficiency */
#include "EXTERN.h"
#include "perl.h"

// work around perlbug #39634
#if __GNUC__ == 3 && __GNUC_MINOR__ <= 3
#undef HASATTRIBUTE_UNUSED
#endif

#include "XSUB.h"
}

#include "nscore.h"
#include "nsUniversalDetector.h"

class Detector: public nsUniversalDetector {
    public:
	Detector() {};
	virtual ~Detector() {}
	const char *getresult() { return mDetectedCharset; }
	virtual void Reset() { this->nsUniversalDetector::Reset(); }
    protected:
	virtual void Report(const char* aCharset) { mDetectedCharset = aCharset; }
};


MODULE = Encode::Detect::Detector		PACKAGE = Encode::Detect::Detector
PROTOTYPES: ENABLE


Detector *
Detector::new()

void
Detector::DESTROY()

int
Detector::handle(SV *buf)
    CODE:
	STRLEN len;
	char *ptr = SvPV(buf, len);
	RETVAL = THIS->HandleData(ptr, len);
    OUTPUT:
	RETVAL

void
Detector::eof()
    CODE:
	THIS->DataEnd();

void
Detector::reset()
    CODE:
	THIS->Reset();

const char *
Detector::getresult()
    CODE:
	RETVAL = THIS->getresult();
    OUTPUT:
	RETVAL


const char *
detect(buf)
	SV *buf
    CODE:
	STRLEN len;
	char *ptr = SvPV(buf, len);

	Detector *det = new Detector;
	det->HandleData(ptr, len);
	det->DataEnd();
	RETVAL = det->getresult();
	delete det;
    OUTPUT:
        RETVAL

