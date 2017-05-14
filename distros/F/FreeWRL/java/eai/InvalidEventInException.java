// Copyright (C) 1998 Tuomas J. Lukka
// DISTRIBUTED WITH NO WARRANTY, EXPRESS OR IMPLIED.
// See the GNU Library General Public License (file COPYING in the distribution)
// for conditions of use and redistribution.

package vrml.external.exception;

public class InvalidEventInException extends RuntimeException
{
    /**
     * Constructs an InvalidEventInException with no detail message.
     */
    public InvalidEventInException() {
        super();
    }

    /**
     * Constructs an InvalidEventInException with the specified detail message.
     * A detail message is a String that describes this particular exception.
     * @param s the detail message
     */
    public InvalidEventInException(String s) {
        super(s);
    }
}
