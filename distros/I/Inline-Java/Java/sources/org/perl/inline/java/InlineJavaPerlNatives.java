package org.perl.inline.java ;

import java.lang.reflect.* ;
import java.util.* ;
import java.io.* ;


public class InlineJavaPerlNatives extends InlineJavaPerlCaller {
	static private boolean inited = false ;
	static private Map registered_classes = Collections.synchronizedMap(new HashMap()) ;
	static private Map registered_methods = Collections.synchronizedMap(new HashMap()) ;


	protected InlineJavaPerlNatives() throws InlineJavaException {
		init() ;
		RegisterPerlNatives(this.getClass()) ;
	}


	static protected void init() throws InlineJavaException {
		init("install") ;
	}


	synchronized static protected void init(String mode) throws InlineJavaException {
		InlineJavaPerlCaller.init() ;
		if (! inited){
			try {
				String perlnatives_so = GetBundle().getString("inline_java_perlnatives_so_" + mode) ;
				File f = new File(perlnatives_so) ;
				if (! f.exists()){
					throw new InlineJavaException("Can't initialize PerlNatives " +
						"functionnality: PerlNatives extension (" + perlnatives_so + 
						") can't be found") ;
				}

				try {
					Class ste_class = Class.forName("java.lang.StackTraceElement") ;
				}
				catch (ClassNotFoundException cnfe){
					throw new InlineJavaException("Can't initialize PerlNatives " +
                        "functionnality: Java 1.4 or higher required (current is " +
						System.getProperty("java.version") + ").") ;
				}      	

				// Load the Natives shared object
				InlineJavaUtils.debug(2, "loading shared library " + perlnatives_so) ;
				System.load(perlnatives_so) ;

				inited = true ;
			}                                   
			catch (MissingResourceException mre){
				throw new InlineJavaException("Error loading InlineJava.properties resource: " + mre.getMessage()) ;
			}
		}
	}


	// This method actually does the real work of registering the methods.
	synchronized private void RegisterPerlNatives(Class c) throws InlineJavaException {
		if (registered_classes.get(c) == null){
			InlineJavaUtils.debug(3, "registering natives for class " + c.getName()) ;

			Constructor constructors[] = c.getDeclaredConstructors() ;
			Method methods[] = c.getDeclaredMethods() ;

			registered_classes.put(c, c) ;
			for (int i = 0 ; i < constructors.length ; i++){
				Constructor x = constructors[i] ;
				if (Modifier.isNative(x.getModifiers())){
					RegisterMethod(c, "new", x.getParameterTypes(), c) ;
				}
			}

			for (int i = 0 ; i < methods.length ; i++){
				Method x = methods[i] ;
				if (Modifier.isNative(x.getModifiers())){
					RegisterMethod(c, x.getName(), x.getParameterTypes(), x.getReturnType()) ;
				}
			}
		}
	}


	private void RegisterMethod(Class c, String mname, Class params[], Class rt) throws InlineJavaException {
		String cname = c.getName() ;
		InlineJavaUtils.debug(3, "registering native method " + mname + " for class " + cname) ;

		// Check return type
		if ((! Object.class.isAssignableFrom(rt))&&(rt != void.class)){
			throw new InlineJavaException("Perl native method " + mname + " of class " + cname + " can only have Object or void return types (not " + rt.getName() + ")") ;
		}

		// fmt starts with the return type, which for now is Object only (or void).
		StringBuffer fmt = new StringBuffer("L") ;
		StringBuffer sign = new StringBuffer("(") ;
		for (int i = 0 ; i < params.length ; i++){
			String code = InlineJavaClass.FindJNICode(params[i]) ;
			sign.append(code) ;
			char ch = code.charAt(0) ;
			char f = ch ;
			if (f == '['){
				// Arrays are Objects...
				f = 'L' ;
			}
			fmt.append(new String(new char [] {f})) ;
		}
		sign.append(")") ;

		sign.append(InlineJavaClass.FindJNICode(rt)) ;
		InlineJavaUtils.debug(3, "signature is " + sign) ;
		InlineJavaUtils.debug(3, "format is " + fmt) ;

		// For now, no method overloading so no signature necessary
		String meth = cname + "." + mname ;
		String prev = (String)registered_methods.get(meth) ;
		if (prev != null){
			throw new InlineJavaException("There already is a native method '" + mname + "' registered for class '" + cname + "'") ;
		}
		registered_methods.put(meth, fmt.toString()) ;

		// call the native method to hook it up
		RegisterMethod(c, mname, sign.toString()) ;
	}


	// This native method will call RegisterNative to hook up the magic
	// method implementation for the method.
	native private void RegisterMethod(Class c, String name, String signature) throws InlineJavaException ;


	// This method will be called from the native side. We need to figure
	// out who this method is and then look in up in the
	// registered method list and return the format.
	private String LookupMethod() throws InlineJavaException {
		InlineJavaUtils.debug(3, "entering LookupMethod") ;

		String caller[] = GetNativeCaller() ;
		String meth = caller[0] + "." + caller[1]  ;

		String fmt = (String)registered_methods.get(meth) ;
		if (fmt == null){
			throw new InlineJavaException("Native method " + meth + " is not registered") ;
		}

		InlineJavaUtils.debug(3, "exiting LookupMethod") ;

		return fmt ;
	}


	private Object InvokePerlMethod(Object args[]) throws InlineJavaException, InlineJavaPerlException {
		InlineJavaUtils.debug(3, "entering InvokePerlMethod") ;

		String caller[] = GetNativeCaller() ;
		String pkg = caller[0] ;
		String method = caller[1] ;

		// Transform the Java class name into the Perl package name
		StringTokenizer st = new StringTokenizer(pkg, ".") ;
		StringBuffer perl_sub = new StringBuffer() ;
		// Starting with "::" means that the package is relative to the caller package
		while (st.hasMoreTokens()){
			perl_sub.append("::" + st.nextToken()) ;
		}
		perl_sub.append("::" + method) ;

		for (int i = 0 ; i < args.length ; i++){
			InlineJavaUtils.debug(3, "InvokePerlMethod argument " + i + " = " + args[i]) ;
		}

		Object ret = CallPerlSub(perl_sub.toString(), args) ;

		InlineJavaUtils.debug(3, "exiting InvokePerlMethod") ;

		return ret ;
	}


	// This method must absolutely be called by a method DIRECTLY called
	// by generic_perl_native
	private String[] GetNativeCaller() throws InlineJavaException {
		InlineJavaUtils.debug(3, "entering GetNativeCaller") ;

		Class ste_class = null ;
		try {
			ste_class = Class.forName("java.lang.StackTraceElement") ;
		}
		catch (ClassNotFoundException cnfe){
			throw new InlineJavaException("Can't load class java.lang.StackTraceElement") ;
		}      	

		Throwable exec_point = new Throwable() ;
		try {
			Method m = exec_point.getClass().getMethod("getStackTrace", new Class [] {}) ;
			Object stack = m.invoke(exec_point, new Object [] {}) ;
			if (Array.getLength(stack) <= 2){
				throw new InlineJavaException("Improper use of InlineJavaPerlNatives.GetNativeCaller (call stack too short)") ;
			}

			Object ste = Array.get(stack, 2) ;
			m = ste.getClass().getMethod("isNativeMethod", new Class [] {}) ;
			Boolean is_nm = (Boolean)m.invoke(ste, new Object [] {}) ;
			if (! is_nm.booleanValue()){
				throw new InlineJavaException("Improper use of InlineJavaPerlNatives.GetNativeCaller (caller is not native)") ;
			}

			m = ste.getClass().getMethod("getClassName", new Class [] {}) ;
			String cname = (String)m.invoke(ste, new Object [] {}) ;
			m = ste.getClass().getMethod("getMethodName", new Class [] {}) ;
			String mname = (String)m.invoke(ste, new Object [] {}) ;

			InlineJavaUtils.debug(3, "exiting GetNativeCaller") ;

			return new String [] {cname, mname} ;
		}
		catch (NoSuchMethodException nsme){
			throw new InlineJavaException("Error manipulating java.lang.StackTraceElement classes: " +
				nsme.getMessage()) ;
		}
		catch (IllegalAccessException iae){
			throw new InlineJavaException("Error manipulating java.lang.StackTraceElement classes: " +
				iae.getMessage()) ;
		}
		catch (InvocationTargetException ite){
			// None of the methods invoked throw exceptions, so...
			throw new InlineJavaException("Exception caught while manipulating java.lang.StackTraceElement classes: " +
				ite.getTargetException()) ;
		}
	}
}
