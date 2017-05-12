package org.perl.inline.java ;


/*
	InlineJavaPerlObject
*/
public class InlineJavaPerlObject extends InlineJavaPerlCaller {
	private int id = 0 ;
	private String pkg = null ;


	/* 
		Creates a Perl Object by calling 
			pkg->new(args) ;
	*/
	public InlineJavaPerlObject(String _pkg, Object args[]) throws InlineJavaPerlException, InlineJavaException {
		pkg = _pkg ;
		InlineJavaPerlObject stub = (InlineJavaPerlObject)CallPerlStaticMethod(pkg, "new", args, getClass()) ;
		id = stub.GetId() ;
		stub.id = 0 ;
	}


	/*
		This is just a stub for already existing objects
	*/
	InlineJavaPerlObject(String _pkg, int _id) throws InlineJavaException {
		pkg = _pkg ;
		id = _id ;
	}


	int GetId(){
		return id ;
	}


	public String GetPkg(){
		return pkg ;
	}


	public Object InvokeMethod(String name, Object args[]) throws InlineJavaPerlException, InlineJavaException {
		return InvokeMethod(name, args, null) ;
	}


	public Object InvokeMethod(String name, Object args[], Class cast) throws InlineJavaPerlException, InlineJavaException {
		return CallPerlMethod(this, name, args, cast) ;
	}


	public void Dispose() throws InlineJavaPerlException, InlineJavaException {
		Dispose(false) ;
	}


	protected void Dispose(boolean gc) throws InlineJavaPerlException, InlineJavaException {
		if (id != 0){
			CallPerlSub("Inline::Java::Callback::java_finalize", new Object [] {new Integer(id), new Boolean(gc)}) ;
		}
	}


	protected void finalize() throws Throwable {
		try {
			Dispose(true) ;
		}
		finally {
			super.finalize() ;
		}
	}
}
