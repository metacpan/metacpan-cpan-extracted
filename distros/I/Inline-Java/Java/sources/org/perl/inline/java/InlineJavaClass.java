package org.perl.inline.java ;

import java.util.* ;
import java.lang.reflect.* ;


class InlineJavaClass {
	private InlineJavaServer ijs ;
	private InlineJavaProtocol ijp ;

	static private HashMap class2jni_code = new HashMap() ;
	static {
		class2jni_code.put(byte.class, "B") ;
		class2jni_code.put(short.class, "S") ;
		class2jni_code.put(int.class, "I") ;
		class2jni_code.put(long.class, "J") ;
		class2jni_code.put(float.class, "F") ;
		class2jni_code.put(double.class, "D") ;
		class2jni_code.put(boolean.class, "Z") ;
		class2jni_code.put(char.class, "C") ;
		class2jni_code.put(void.class, "V") ;
	} ;

	static private HashMap class2wrapper = new HashMap() ;
	static {
		class2wrapper.put(byte.class, java.lang.Byte.class) ;
		class2wrapper.put(short.class, java.lang.Short.class) ;
		class2wrapper.put(int.class, java.lang.Integer.class) ;
		class2wrapper.put(long.class, java.lang.Long.class) ;
		class2wrapper.put(float.class, java.lang.Float.class) ;
		class2wrapper.put(double.class, java.lang.Double.class) ;
		class2wrapper.put(boolean.class, java.lang.Boolean.class) ;
		class2wrapper.put(char.class, java.lang.Character.class) ;
		class2wrapper.put(void.class, java.lang.Void.class) ;
	} ;

	static private HashMap name2class = new HashMap() ;
	static {
		name2class.put("byte", byte.class) ;
		name2class.put("short", short.class) ;
		name2class.put("int", int.class) ;
		name2class.put("long", long.class) ;
		name2class.put("float", float.class) ;
		name2class.put("double", double.class) ;
		name2class.put("boolean", boolean.class) ;
		name2class.put("char", char.class) ;
		name2class.put("void", void.class) ;
		name2class.put("B", byte.class) ;
		name2class.put("S", short.class) ;
		name2class.put("I", int.class) ;
		name2class.put("J", long.class) ;
		name2class.put("F", float.class) ;
		name2class.put("D", double.class) ;
		name2class.put("Z", boolean.class) ;
		name2class.put("C", char.class) ;
		name2class.put("V", void.class) ;
	} ;


	InlineJavaClass(InlineJavaServer _ijs, InlineJavaProtocol _ijp){
		ijs = _ijs ;
		ijp = _ijp ;
	}


	/*
		Makes sure a class exists
	*/
	static Class ValidateClass(String name) throws InlineJavaException {
		Class pc = FindType(name) ;
		if (pc != null){
			return pc ;
		}

		try {
			Class c = Class.forName(name, true, InlineJavaServer.GetInstance().GetUserClassLoader()) ;
			return c ;
		}
		catch (ClassNotFoundException e){
			throw new InlineJavaException("Class " + name + " not found") ;
		}
	}


	/*
 		Remove L...; from a class name if it has been extracted from an Array class name.
	*/
	static String CleanClassName(String name){
		if (name != null){
			int l = name.length() ;
			if ((l > 2)&&(name.charAt(0) == 'L')&&(name.charAt(l - 1) == ';')){
				name = name.substring(1, l - 1) ; 
			}
		}
		return name ;
	}


	static private Class ValidateClassQuiet(String name){
		try {
			return ValidateClass(name) ;
		}
		catch (InlineJavaException ije){
			return null ;
		}
	}

	/*
		This is the monster method that determines how to cast arguments
	*/
	Object [] CastArguments(Class [] params, ArrayList args) throws InlineJavaException {
		Object ret[] = new Object [params.length] ;
	
		for (int i = 0 ; i < params.length ; i++){	
			// Here the args are all strings or objects (or undef)
			// we need to match them to the prototype.
			Class p = params[i] ;
			InlineJavaUtils.debug(4, "arg " + String.valueOf(i) + " of signature is " + p.getName()) ;

			ret[i] = CastArgument(p, (String)args.get(i)) ;
		}

		return ret ;
	}


	/*
		This is the monster method that determines how to cast arguments
	*/
	Object CastArgument(Class p, String argument) throws InlineJavaException {
		Object ret = null ;
	
		ArrayList tokens = new ArrayList() ;
		StringTokenizer st = new StringTokenizer(argument, ":") ;
		for (int j = 0 ; st.hasMoreTokens() ; j++){
			tokens.add(j, st.nextToken()) ;
		}
		if (tokens.size() == 1){
			tokens.add(1, "") ;
		}
		String type = (String)tokens.get(0) ;
		
		// We need to separate the primitive types from the 
		// reference types.
		boolean num = ClassIsNumeric(p) ;
		if ((num)||(ClassIsString(p))){
			Class ap = p ;
			if (ap == java.lang.Number.class){
				InlineJavaUtils.debug(4, "specializing java.lang.Number to java.lang.Double") ;
				ap = java.lang.Double.class ;
			}
			else if (ap.getName().equals("java.lang.CharSequence")){
				InlineJavaUtils.debug(4, "specializing java.lang.CharSequence to java.lang.String") ;
				ap = java.lang.String.class ;
			}

			if (type.equals("undef")){
				if (num){
					InlineJavaUtils.debug(4, "args is undef -> forcing to " + ap.getName() + " 0") ;
					ret = ijp.CreateObject(ap, new Object [] {"0"}, new Class [] {String.class}) ;
					InlineJavaUtils.debug(4, " result is " + ret.toString()) ;
				}
				else{
					ret = null ;
					InlineJavaUtils.debug(4, "args is undef -> forcing to " + ap.getName() + " " + ret) ;
					InlineJavaUtils.debug(4, " result is " + ret) ;
				}
			}
			else if (type.equals("scalar")){
				String arg = ijp.Decode((String)tokens.get(1)) ;
				InlineJavaUtils.debug(4, "args is scalar (" + arg + ") -> forcing to " + ap.getName()) ;
				try	{
					ret = ijp.CreateObject(ap, new Object [] {arg}, new Class [] {String.class}) ;
					InlineJavaUtils.debug(4, " result is " + ret.toString()) ;
				}
				catch (NumberFormatException e){
					throw new InlineJavaCastException("Can't convert " + arg + " to " + ap.getName()) ;
				}
			}
			else if (type.equals("double")){
				String arg = ijp.Decode((String)tokens.get(1)) ;
				// We have native double bytes in arg.
				long l = 0 ;
				char c[] = arg.toCharArray() ;
				for (int i = 0 ; i < 8 ; i++){
					l += (((long)c[i]) << (8 * i)) ;
				}
				double d = Double.longBitsToDouble(l) ;
				ret = new Double(d) ;
			}
			else {
				throw new InlineJavaCastException("Can't convert reference to " + p.getName()) ;
			}
		}
		else if (ClassIsBool(p)){
			if (type.equals("undef")){
				InlineJavaUtils.debug(4, "args is undef -> forcing to bool false") ;
				ret = new Boolean("false") ;
				InlineJavaUtils.debug(4, " result is " + ret.toString()) ;
			}
			else if (type.equals("scalar")){
				String arg = ijp.Decode((String)tokens.get(1)) ;
				InlineJavaUtils.debug(4, "args is scalar (" + arg + ") -> forcing to bool") ;
				if ((arg.equals(""))||(arg.equals("0"))){
					arg = "false" ;
				}
				else{
					arg = "true" ;
				}
				ret = new Boolean(arg) ;
				InlineJavaUtils.debug(4, " result is " + ret.toString()) ;
			}
			else{
				throw new InlineJavaCastException("Can't convert reference to " + p.getName()) ;
			}
		}
		else if (ClassIsChar(p)){
			if (type.equals("undef")){
				InlineJavaUtils.debug(4, "args is undef -> forcing to char '\0'") ;
				ret = new Character('\0') ;
				InlineJavaUtils.debug(4, " result is " + ret.toString()) ;
			}
			else if (type.equals("scalar")){
				String arg = ijp.Decode((String)tokens.get(1)) ;
				InlineJavaUtils.debug(4, "args is scalar -> forcing to char") ;
				char c = '\0' ;
				if (arg.length() == 1){
					c = arg.toCharArray()[0] ;
				}
				else if (arg.length() > 1){
					throw new InlineJavaCastException("Can't convert " + arg + " to " + p.getName()) ;
				}
				ret = new Character(c) ;
				InlineJavaUtils.debug(4, " result is " + ret.toString()) ;
			}
			else{
				throw new InlineJavaCastException("Can't convert reference to " + p.getName()) ;
			}
		}
		else {
			InlineJavaUtils.debug(4, "class " + p.getName() + " is reference") ;
			// We know that what we expect here is a real object
			if (type.equals("undef")){
				InlineJavaUtils.debug(4, "args is undef -> forcing to null") ;
				ret = null ;
			}
			else if (type.equals("scalar")){
				// Here if we need a java.lang.Object.class, it's probably
				// because we can store anything, so we use a String object.
				if (p == java.lang.Object.class){
					String arg = ijp.Decode((String)tokens.get(1)) ;
					ret = arg ;
				}
				else{
					throw new InlineJavaCastException("Can't convert primitive type to " + p.getName()) ;
				}
			}
			else if (type.equals("java_object")){
				// We need an object and we got an object...
				InlineJavaUtils.debug(4, "class " + p.getName() + " is reference") ;

				String c_name = (String)tokens.get(1) ;
				String objid = (String)tokens.get(2) ;

				Class c = ValidateClass(c_name) ;

				if (DoesExtend(c, p) > -1){
					InlineJavaUtils.debug(4, " " + c.getName() + " is a kind of " + p.getName()) ;
					// get the object from the hash table
					int id = Integer.parseInt(objid) ;
					Object o = ijs.GetObject(id) ;
					ret = o ;
				}
				else{
					throw new InlineJavaCastException("Can't cast a " + c.getName() + " to a " + p.getName()) ;
				}
			}
			else{
				InlineJavaUtils.debug(4, "class " + p.getName() + " is reference") ;

				String pkg = (String)tokens.get(1) ;
				pkg = pkg.replace('/', ':') ;
				String objid = (String)tokens.get(2) ;


				if (DoesExtend(p, org.perl.inline.java.InlineJavaPerlObject.class) > -1){
					InlineJavaUtils.debug(4, " Perl object is a kind of " + p.getName()) ;
					int id = Integer.parseInt(objid) ;
					ret = new InlineJavaPerlObject(pkg, id) ;
				}
				else{
					throw new InlineJavaCastException("Can't cast a Perl object to a " + p.getName()) ;
				}
			}
		}

		return ret ;
	}


	/* 
		Returns the number of levels that separate a from b
	*/
	static int DoesExtend(Class a, Class b){
		return DoesExtend(a, b, 0) ;
	}


	static int DoesExtend(Class a, Class b, int level){
		InlineJavaUtils.debug(4, "checking if " + a.getName() + " extends " + b.getName()) ;

		if (a == b){
			return level ;
		}

		Class parent = a.getSuperclass() ;
		if (parent != null){
			InlineJavaUtils.debug(4, " parent is " + parent.getName()) ;
			int ret = DoesExtend(parent, b, level + 1) ;
			if (ret != -1){
				return ret ;
			}
		}

		// Maybe b is an interface a implements it?
		Class inter[] = a.getInterfaces() ;
		for (int i = 0 ; i < inter.length ; i++){
			InlineJavaUtils.debug(4, " interface is " + inter[i].getName()) ;
			int ret = DoesExtend(inter[i], b, level + 1) ;
			if (ret != -1){
				return ret ;
			}
		}

		return -1 ;
	}


	/*
		Finds the wrapper class for the passed primitive type.
	*/
	static Class FindWrapper(Class p){
		Class w = (Class)class2wrapper.get(p) ;
		if (w == null){
			w = p ;
		}
		
		return w ;
	}


	/*
		Finds the primitive type class for the passed primitive type name.
	*/
	static Class FindType (String name){
		return (Class)name2class.get(name) ;
	}


	static String FindJNICode(Class p){
		if (! Object.class.isAssignableFrom(p)){
			return (String)class2jni_code.get(p) ;
		}
		else {
			String name = p.getName().replace('.', '/') ;
			if (p.isArray()){
				return name ;
			}
			else{
				return "L" + name + ";" ;
			}
		}
	}


	static boolean ClassIsPrimitive(Class p){
		String name = p.getName() ;

		if ((ClassIsNumeric(p))||(ClassIsString(p))||(ClassIsChar(p))||(ClassIsBool(p))){
			InlineJavaUtils.debug(4, "class " + name + " is primitive") ;
			return true ;
		}

		return false ;
	}


	/*
		Determines if class is of numerical type.
	*/
	static private HashMap numeric_classes = new HashMap() ;
	static {
		Class [] list = {
			java.lang.Byte.class,
			java.lang.Short.class,
			java.lang.Integer.class,
			java.lang.Long.class,
			java.lang.Float.class,
			java.lang.Double.class,
			java.lang.Number.class,
			byte.class,
			short.class,
			int.class,
			long.class,
			float.class,
			double.class,
		} ;
		for (int i = 0 ; i < list.length ; i++){
			numeric_classes.put(list[i], new Boolean(true)) ;
		}
	}
	static boolean ClassIsNumeric (Class p){
		return (numeric_classes.get(p) != null) ;
	}


	static private HashMap double_classes = new HashMap() ;
	static {
		Class [] list = {
			java.lang.Double.class,
			double.class,
		} ;
		for (int i = 0 ; i < list.length ; i++){
			double_classes.put(list[i], new Boolean(true)) ;
		}
	}
	static boolean ClassIsDouble (Class p){
		return (double_classes.get(p) != null) ;
	}


	/*
		Class is String or StringBuffer
	*/
	static private HashMap string_classes = new HashMap() ;
	static {
		Class csq = ValidateClassQuiet("java.lang.CharSequence") ;
		Class [] list = {
			java.lang.String.class,
			java.lang.StringBuffer.class,
			csq
		} ;
		for (int i = 0 ; i < list.length ; i++){
			string_classes.put(list[i], new Boolean(true)) ;
		}
	}
	static boolean ClassIsString (Class p){
		return (string_classes.get(p) != null) ;
	}


	/*
		Class is Char
	*/
	static private HashMap char_classes = new HashMap() ;
	static {
		Class [] list = {
			java.lang.Character.class,
			char.class,
		} ;
		for (int i = 0 ; i < list.length ; i++){
			char_classes.put(list[i], new Boolean(true)) ;
		}
	}
	static boolean ClassIsChar (Class p){
		return (char_classes.get(p) != null) ;
	}


	/*
		Class is Bool
	*/
	static private HashMap bool_classes = new HashMap() ;
	static {
		Class [] list = {
			java.lang.Boolean.class,
			boolean.class,
		} ;
		for (int i = 0 ; i < list.length ; i++){
			bool_classes.put(list[i], new Boolean(true)) ;
		}
	}
	static boolean ClassIsBool (Class p){
		return (bool_classes.get(p) != null) ;
	}

	
	/*
		Determines if a class is not of a primitive type or of a 
		wrapper class.
	*/
	static boolean ClassIsReference (Class p){
		String name = p.getName() ;

		if (ClassIsPrimitive(p)){
			return false ;
		}

		InlineJavaUtils.debug(4, "class " + name + " is reference") ;

		return true ;
	}


	static boolean ClassIsArray (Class p){
		String name = p.getName() ;

		if ((ClassIsReference(p))&&(name.startsWith("["))){
			InlineJavaUtils.debug(4, "class " + name + " is array") ;
			return true ;
		}

		return false ;
	}


	static boolean ClassIsPublic (Class p){
		int pub = p.getModifiers() & Modifier.PUBLIC ;
		if (pub != 0){
			return true ;
		}

		return false ;
	}


	static boolean ClassIsHandle (Class p){
		if ((ClassIsReadHandle(p))||(ClassIsWriteHandle(p))){
			return true ;
		}

		return false ;
	}


	static boolean ClassIsReadHandle (Class p){
		if ((java.io.Reader.class.isAssignableFrom(p))||
			(java.io.InputStream.class.isAssignableFrom(p))){
			return true ;
		}

		return false ;
	}


	static boolean ClassIsWriteHandle (Class p){
		if ((java.io.Writer.class.isAssignableFrom(p))||
			(java.io.OutputStream.class.isAssignableFrom(p))){
			return true ;
		}

		return false ;
	}
}
