package org.perl.inline.java ;

import java.net.* ;
import java.util.* ;
import java.io.* ;
import java.lang.reflect.* ;


/*
	This is the ClassLoader that loads the users code. It is also
	used to pass reflection calls to the InlineJavaUserClassLink
	so that it will execute them.
*/
class InlineJavaUserClassLoader extends URLClassLoader {
    private HashMap urls = new HashMap() ;

	private Object link = null ;
	private Method invoke = null ;
	private Method get = null ;
	private Method set = null ;
	private Method array_get = null ;
	private Method array_set = null ;
	private Method create = null ;


    public InlineJavaUserClassLoader(){
		// Added Thread.currentThread().getContextClassLoader() so that the code works
		// in Tomcat and possibly other embedded environments asa well.
        super(new URL [] {}, Thread.currentThread().getContextClassLoader()) ;
    }


    public void AddClassPath(String path) throws InlineJavaException {
		try {
			File p = new File(path) ;
			URL u = p.toURI().toURL() ;
			if (urls.get(u) == null){
	            urls.put(u, "1") ;
	            addURL(u) ;
				InlineJavaUtils.debug(2, "added " + u + " to classpath") ;
	        }
		}
		catch (MalformedURLException e){
			throw new InlineJavaException("Can't add invalid classpath entry '" + path + "'") ;
		}
	}


	synchronized private void check_link() throws InlineJavaException {
		if (link == null){
			try {
				InlineJavaUtils.debug(1, "loading InlineJavaUserClassLink via InlineJavaUserClassLoader") ;
				Class c = Class.forName("InlineJavaUserClassLink", true, this) ;
				link = c.newInstance() ;

				invoke = find_method(c, "invoke") ;
				get = find_method(c, "get") ;
				set = find_method(c, "set") ;
				array_get = find_method(c, "array_get") ;
				array_set = find_method(c, "array_set") ;
				create = find_method(c, "create") ;
			}
			catch (Exception e){
				throw new InlineJavaException("InlineJavaUserClassLoader can't load InlineJavaUserClassLink: invalid classpath setup (" +
					e.getClass().getName() + ": " + e.getMessage() + ")") ;
			}
		}
	}
	

	private Method find_method(Class c, String name) throws InlineJavaException {
		Method ml[] = c.getMethods() ;
		for (int i = 0 ; i < ml.length ; i++){
			if (ml[i].getName().equals(name)){
				return ml[i] ;
			}
		}

		throw new InlineJavaException("Can't find method '" + name +
			"' in class InlineJavaUserClassLink") ;
	}


	private Object invoke_via_link(Method m, Object p[]) throws NoSuchMethodException, InstantiationException, IllegalAccessException, IllegalArgumentException, InvocationTargetException, InlineJavaException {
		try {
			return m.invoke(link, p) ;
		}
		catch (IllegalAccessException e){
			throw new InlineJavaException("Can't invoke method from class InlineJavaUserClassLink: IllegalAccessException") ;			
		}
		catch (IllegalArgumentException e){
			throw new InlineJavaException("Can't invoke method from class InlineJavaUserClassLink: IllegalArgumentException") ;
		}
		catch (InvocationTargetException e){
			Throwable t = e.getTargetException() ;
			if (t instanceof NoSuchMethodException){
				throw (NoSuchMethodException)t ;
			}
			else if (t instanceof InstantiationException){
				throw (InstantiationException)t ;
			}
			else if (t instanceof IllegalAccessException){
				throw (IllegalAccessException)t ;
			}
			if (t instanceof IllegalAccessException){
				throw (IllegalAccessException)t ;
			}
			else if (t instanceof IllegalArgumentException){
				throw (IllegalArgumentException)t ;
			}
			else if (t instanceof InvocationTargetException){
				throw (InvocationTargetException)t ;
			}
			// Not sure if this is really necessary, but...
			else if (t instanceof RuntimeException){
				RuntimeException re = (RuntimeException)t ;
				throw re ;
			}
			else{
				// In theory this case is impossible.
				throw new InlineJavaException("Unexpected exception of type '" + 
					t.getClass().getName() + "': " + t.getMessage()) ;
			}
		}
	}


	public Object invoke(Method m, Object o, Object p[]) throws IllegalAccessException, IllegalArgumentException, InvocationTargetException, InlineJavaException {
		check_link() ;
		try {
			return invoke_via_link(invoke, new Object [] {m, o, p}) ;
		}
		catch (NoSuchMethodException me){/* Impossible */}
		catch (InstantiationException ie){/* Impossible */}
		return null ;
	}


	public Object get(Field f, Object o) throws IllegalAccessException, IllegalArgumentException, InlineJavaException {
		check_link() ;
		try {
			return invoke_via_link(get, new Object [] {f, o}) ;
		}
		catch (NoSuchMethodException me){/* Impossible */}
		catch (InstantiationException ie){/* Impossible */}
		catch (InvocationTargetException e){/* Impossible */}
		return null ;
	}


	public void set(Field f, Object o, Object p) throws IllegalAccessException, IllegalArgumentException, InlineJavaException {
		check_link() ;
		try {
			invoke_via_link(set, new Object [] {f, o, p}) ;
		}
		catch (NoSuchMethodException me){/* Impossible */}
		catch (InstantiationException ie){/* Impossible */}
		catch (InvocationTargetException e){/* Impossible */}
	}


	public Object array_get(Object o, int idx) throws InlineJavaException {
		check_link() ;
		try {
			return invoke_via_link(array_get, new Object [] {o, new Integer(idx)}) ;
		}
		catch (NoSuchMethodException me){/* Impossible */}
		catch (InstantiationException ie){/* Impossible */}
		catch (IllegalAccessException iae){/* Impossible */}
		catch (IllegalArgumentException iae){/* Impossible */}
		catch (InvocationTargetException e){/* Impossible */}
		return null ;
	}


	public void array_set(Object o, int idx, Object elem) throws IllegalArgumentException, InlineJavaException {
		check_link() ;
		try {
			invoke_via_link(array_set, new Object [] {o, new Integer(idx), elem}) ;
		}
		catch (NoSuchMethodException me){/* Impossible */}
		catch (InstantiationException ie){/* Impossible */}
		catch (IllegalAccessException iae){/* Impossible */}
		catch (InvocationTargetException e){/* Impossible */}
	}

	
	public Object create(Class p, Object args[], Class proto[]) throws NoSuchMethodException, InstantiationException, IllegalAccessException, IllegalArgumentException, InvocationTargetException, InlineJavaException {
		check_link() ;
		return invoke_via_link(create, new Object [] {p, args, proto}) ;
	}
}
