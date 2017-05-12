package org.perl.inline.java ;

class InlineJavaInvocationTargetException extends InlineJavaException {
	private Throwable t ;


	InlineJavaInvocationTargetException(String m, Throwable _t){
		super(m) ;
		t = _t ;
	}

	Throwable GetThrowable(){
		return t ;
	}
}
