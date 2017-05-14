// Copyright (C) 1998 Tuomas J. Lukka
// DISTRIBUTED WITH NO WARRANTY, EXPRESS OR IMPLIED.
// See the GNU Library General Public License (file COPYING in the distribution)
// for conditions of use and redistribution.

import vrml.external.*;
import vrml.external.field.*;
import vrml.external.exception.*;

public class test2 implements EventOutObserver {
EventInSFColor col;

test2() throws Exception {
	FreeWRLBrowser brow = new FreeWRLBrowser("eai/test3.wrl");
	Node nod = brow.getNode("MAT");
	col = 
		(EventInSFColor) nod.getEventIn("diffuseColor");
	col.setValue(new float[] {0.8F,0F,0F});
	Node nod2 = brow.getNode("TS");
	EventOut eo = nod2.getEventOut("touchTime");
	eo.advise(this,this);
}

public static void main(String argv[]) throws Exception {
	test2 t2 = new test2();
	Thread.sleep(5000);
}
public void callback(EventOut value,double timestamp,Object ud) {
	col.setValue(new float[] {(float)Math.random(),
		(float)(Math.random()),
		(float)(Math.random())});
}


}

