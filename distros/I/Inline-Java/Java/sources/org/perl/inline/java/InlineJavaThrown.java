package org.perl.inline.java ;


class InlineJavaThrown {
	Throwable t ;

	InlineJavaThrown(Throwable _t){
		t = _t ;
	}

	Throwable GetThrowable(){
		return t ;
	}
}
