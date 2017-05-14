import java.lang.reflect.Method;
import java.lang.reflect.Constructor;
import java.lang.reflect.Field;
import java.lang.reflect.InvocationTargetException;
import java.util.Iterator;
import java.util.HashMap;

public class ObjectWrapper {

	protected Object wrappedObject = null;
	protected InvocationTargetException lastThrownException = null;
	protected boolean primitive = false;

	protected static HashMap staticExceptions = new HashMap();

	protected ObjectWrapper() {
	}

	protected ObjectWrapper ( Object wrapMe ) {
		wrappedObject = wrapMe;
	}

	protected ObjectWrapper ( Object wrapMe, boolean isPrimitive ) {
		wrappedObject = wrapMe;
		primitive = isPrimitive;
	}

	protected void finalize() {
	}

	public Object getWrappedObject (  ) {
		return wrappedObject;
	}

	protected Class getObjectType (  ) {
		if ( primitive ) {
			return (Class) this.getField("TYPE").getWrappedObject();
		} else {
			return wrappedObject.getClass();
		}
	}

	public boolean isArray (  ) {
		return wrappedObject.getClass().isArray();
	}

	//public ArrayWrapper getAsArray (  ) {
	//}

	public ObjectWrapper getField ( String fieldName ) {
		try {
			Field thisField = wrappedObject.getClass().getField(fieldName);
			return new ObjectWrapper(thisField.get(wrappedObject));
		} catch (NoSuchFieldException e) {
			e.printStackTrace();
		} catch (IllegalAccessException e) {
			e.printStackTrace();
		}
		return null;
	}

	public void setField ( String fieldName, ObjectWrapper value ) {
		try {
			Field thisField = wrappedObject.getClass().getField(fieldName);
			thisField.set(wrappedObject, value.getWrappedObject());
		} catch (NoSuchFieldException e) {
			e.printStackTrace();
		} catch (IllegalAccessException e) {
			e.printStackTrace();
		}
	}

	public boolean perl_isa ( String javaClassName ) {
		//System.out.println("ISA CALLED IN JAVA");
		//System.out.println("The class being asked about is: ." + javaClassName + ".");
		boolean temp;
		try {
			temp = Class.forName(javaClassName).isAssignableFrom(wrappedObject.getClass());
			//System.out.println("perl_isa is returning: " + temp);
			return temp;
		} catch (ClassNotFoundException e) {
			return false;
		}
	}

	public boolean can ( String methodName ) {
		Method[] methods = wrappedObject.getClass().getMethods();
		for ( int i = 0; i < methods.length; i++ ) {
			if ( methods[i].getName().equals(methodName) ) {
				return true;
			}
		}
		return false;
	}
	
	public String toString (  ) {
		return wrappedObject.toString();
	}

	private static void getArguments ( ArgumentArray wrapped, Class[] types, Object[] values ) {
		if ( wrapped != null ) {
			Iterator itr = wrapped.getIterator();
			ObjectWrapper curr = null;
			//int i = 0;
			for ( int i = 0; itr.hasNext(); i++ ) {
			//while ( itr.hasNext() ) {
				curr = (ObjectWrapper) itr.next();
				values[i] = curr.getWrappedObject();
				//argClasses[i] = args[i].getClass();
				types[i] = curr.getObjectType();
				i++;
			}
		}
	}

	public ObjectWrapper invokeMethod ( String methodName, ArgumentArray inputArgs ) {
		Class[] argClasses = null;
		Object[] args = null;
		if ( inputArgs != null ) {
			argClasses = new Class[inputArgs.getSize()];
			args = new Object[inputArgs.getSize()];	
		}
		getArguments(inputArgs, argClasses, args);
		
		try {
			Method thisMethod = wrappedObject.getClass().getMethod(methodName, argClasses);
			Object returnValue = thisMethod.invoke(wrappedObject, args);
			if ( returnValue.getClass().isArray() ) {
				return new ArrayWrapper(returnValue);
			}
			return new ObjectWrapper(returnValue);
		} catch (InvocationTargetException e) {
			lastThrownException = e;
		} catch ( Exception e ) {
			lastThrownException = new InvocationTargetException(e);
		}
		return null;
	}

	public ObjectWrapper getLastThrownException (  ) {
		//System.out.println("Called getLastThrownException");
		Exception lastException = lastThrownException;
		lastThrownException = null;
		if ( lastException == null ) {
			return null;
		} else {
			return new ObjectWrapper(lastException);
		}
	}

	public static ObjectWrapper getLastStaticThrownException (  ) {
		Exception lastException = (Exception) staticExceptions.get(Thread.currentThread().getName());
		staticExceptions.put(Thread.currentThread().getName(), null);
		if ( lastException == null ) {
			return null;
		} else {
			return new ObjectWrapper(lastException);
		}
	}

	public static ObjectWrapper invokeStaticMethod ( String className, String staticMethodName, ArgumentArray inputArgs ) {
		Class[] argClasses = null;
                Object[] args = null;
		if ( inputArgs != null ) {
                        argClasses = new Class[inputArgs.getSize()];
                        args = new Object[inputArgs.getSize()];
		}
		getArguments(inputArgs, argClasses, args);

                try {
                        Method thisMethod = Class.forName(className).getMethod(staticMethodName, argClasses);
			Object returnValue = thisMethod.invoke(null, args);
			if ( returnValue.getClass().isArray() ) {
				return new ArrayWrapper(returnValue);
			}
                        return new ObjectWrapper(returnValue);
                } catch (InvocationTargetException e) {
			//index the exception based on the result of Thread.currentThread()
			staticExceptions.put(Thread.currentThread().getName(), e);
                } catch (Exception e) {
			staticExceptions.put(Thread.currentThread().getName(), new InvocationTargetException(e));
		}
                return null;
	}

	public static ObjectWrapper newClassInstance ( String javaClassName, ArgumentArray inputArgs ) {
		Class[] argClasses = null;
                Object[] args = null;
		if ( inputArgs != null ) {
                        argClasses = new Class[inputArgs.getSize()];
                        args = new Object[inputArgs.getSize()];
		}
		getArguments(inputArgs, argClasses, args);

		try {
			Class thisClass = Class.forName(javaClassName);
			Constructor thisConstructor = thisClass.getConstructor(argClasses);
			return new ObjectWrapper(thisConstructor.newInstance(args));
		} catch (InvocationTargetException e ) {
			//propagate this to Perl and die a standard message
			//index the exception based on the result of Thread.currentThread()
			staticExceptions.put(Thread.currentThread().getName(), e);
			//e.printStackTrace();
		} catch (Exception e) {
			staticExceptions.put(Thread.currentThread().getName(), new InvocationTargetException(e));
		}
		return null;
	}

	public static ArrayWrapper newJavaArray ( String javaClassName, int size ) {
		return new ArrayWrapper(javaClassName, size);
	}

	public static ObjectWrapper wrapInt ( int wrapMe ) {
		return new ObjectWrapper(new Integer(wrapMe), true);
	}

	public static ObjectWrapper wrapString ( String wrapMe ) {
		return new ObjectWrapper(wrapMe);
	}

	public static ObjectWrapper wrapBoolean ( boolean wrapMe ) {
		return new ObjectWrapper(new Boolean(wrapMe), true);
	}

	public static ObjectWrapper wrapShort ( short wrapMe ) {
		return new ObjectWrapper(new Short(wrapMe), true);
	}

	public static ObjectWrapper wrapLong ( long wrapMe ) {
		return new ObjectWrapper(new Long(wrapMe), true);
	}

	public static ObjectWrapper wrapFloat ( float wrapMe ) {
		return new ObjectWrapper(new Float(wrapMe), true);
	}
	
	public static ObjectWrapper wrapDouble ( double wrapMe ) {
		return new ObjectWrapper(new Double(wrapMe), true);
	}

	public static ObjectWrapper wrapByte ( byte wrapMe ) {
		return new ObjectWrapper(new Byte(wrapMe), true);
	}

	public static ObjectWrapper wrapChar ( char wrapMe ) {
		return new ObjectWrapper(new Character(wrapMe), true);
	}

}
