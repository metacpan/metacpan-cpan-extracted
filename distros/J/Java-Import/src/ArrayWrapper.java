import java.lang.reflect.Array;

public class ArrayWrapper extends ObjectWrapper {

	private int length = 0;

	public ArrayWrapper ( String javaClassName, int size ) {
		//System.out.println("Creating a Java array, " + javaClassName + ", of size " + size);
		try {
			wrappedObject = Array.newInstance(Class.forName(javaClassName), size);
			length = size;
		} catch (ClassNotFoundException e) {
			e.printStackTrace();
		}
	}

	public ArrayWrapper ( Object prisoner ) {
		wrappedObject = prisoner;
	}

	public int getSize (  )  {
		//return length;
		return Array.getLength(wrappedObject);
	}

	public void set ( ObjectWrapper obj, int index ) {
		Array.set(wrappedObject, index, obj.getWrappedObject());
	}

	public ObjectWrapper get ( int index ) {
		return new ObjectWrapper(Array.get(wrappedObject, index));
	}

	public String toString (  ) {
		StringBuffer sb = new StringBuffer();
		for ( int i = 0; i < length; i++ ) {
			sb.append(Array.get(wrappedObject, i).toString());
			sb.append(" ");
		}
		return sb.toString();
	}

	public static ArrayWrapper getObjectAsArray ( ObjectWrapper object ) {
		try {
			return (ArrayWrapper) object;
		} catch (ClassCastException e) {
			e.printStackTrace();
		}
		return null;
	}
	
}
