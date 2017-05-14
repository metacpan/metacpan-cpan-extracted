// Copyright (C) 1998 Tuomas J. Lukka
// DISTRIBUTED WITH NO WARRANTY, EXPRESS OR IMPLIED.
// See the GNU Library General Public License (file COPYING in the distribution)
// for conditions of use and redistribution.

// Specification of the Java interface to a VRML node.

package vrml.external;

import vrml.external.field.EventIn;
import vrml.external.field.EventOut;
import vrml.external.exception.InvalidEventInException;
import vrml.external.exception.InvalidEventOutException;

public class Node {
  String id;
  FreeWRLBrowser browser;
  public Node(FreeWRLBrowser br,String str) {
  	id = str;
	browser = br;
	System.out.println("New node '"+id+"'\n");
  }

  // Get a string specifying the type of this node. May return the
  // name of a PROTO, or the class name
  public String        getType() { return ""; };

  // Means of getting a handle to an EventIn of this node
  public EventIn       getEventIn(String name)
       throws InvalidEventInException {
		return browser.get__eventin(id,name);
	}

  // Means of getting a handle to an EventOut of this node
  public EventOut      getEventOut(String name)
       throws InvalidEventOutException {
       		return browser.get__eventout(id,name);
	}
}
