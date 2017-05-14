// Copyright (C) 1998 Tuomas J. Lukka
// DISTRIBUTED WITH NO WARRANTY, EXPRESS OR IMPLIED.
// See the GNU Library General Public License (file COPYING in the distribution)
// for conditions of use and redistribution.

import vrml.external.*;
import vrml.external.field.*;
import vrml.external.exception.*;

public class test {
public static void main(String argv[]) throws Exception {
	FreeWRLBrowser brow = new FreeWRLBrowser("eai/test2.wrl");
	Node nod = brow.getNode("MAT");
	EventInSFColor col = 
		(EventInSFColor) nod.getEventIn("diffuseColor");
	col.setValue(new float[] {0.8F,0F,0F});
	Thread.sleep(5000);
}
}
