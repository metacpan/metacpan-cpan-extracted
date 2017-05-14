// Copyright (C) 1998 Tuomas J. Lukka
// DISTRIBUTED WITH NO WARRANTY, EXPRESS OR IMPLIED.
// See the GNU Library General Public License (file COPYING in the distribution)
// for conditions of use and redistribution.

package vrml.external.field;

public interface EventOutObserver {
  void callback(EventOut value, double timeStamp, Object userData);
}
