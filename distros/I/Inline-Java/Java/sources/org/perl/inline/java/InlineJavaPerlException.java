package org.perl.inline.java ;


public class InlineJavaPerlException extends Exception {
	private Object obj ;


	public InlineJavaPerlException(Object o){
		super(o.toString()) ;
		obj = o ;
	}

	public InlineJavaPerlException(String s){
		super(s) ;
		obj = s ;
	}

	public Object GetObject(){
		return obj ;
	}

	public String GetString(){
		return (String)obj ;
	}
}
