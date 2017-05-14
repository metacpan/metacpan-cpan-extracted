// Copyright (C) 1998 Tuomas J. Lukka
// DISTRIBUTED WITH NO WARRANTY, EXPRESS OR IMPLIED.
// See the GNU Library General Public License (file COPYING in the distribution)
// for conditions of use and redistribution.

package vrml.external.field;
import java.util.*;

public abstract class EventOut implements Runnable {

  Hashtable advisees = new Hashtable();

  // Get the type of this EventOut (specified in FieldTypes.java)
  public int           getType() { return 0; };

  // Mechanism for setting up an observer for this field.
  // The EventOutObserver's callback gets called when the
  // EventOut's value changes.
  public void          advise(EventOutObserver f, Object userData)
  { 
  	advisees.put(f,userData);
  };

  // terminate notification on the passed EventOutObserver
  public void          unadvise(EventOutObserver f) { 
  	advisees.remove(f);
  };


// ----- freewrl-specific

  public abstract void value__set(String value) throws Exception;

  // Here we update all the advised parties
  public void run() {
  	for(Enumeration e = advisees.elements(); e.hasMoreElements() ;) {
		Object o;
		( (EventOutObserver)(o=e.nextElement()) ).callback(
			this, 0.0, advisees.get(o));
	}
  }

}


