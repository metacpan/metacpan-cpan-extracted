package org.perl.inline.java ;


import java.util.* ;
import java.io.* ;


public class InlineJavaHandle {
	private static final String charset = "ISO-8859-1" ;


	static String read(Object o, int len) throws InlineJavaException, IOException {
		String ret = null ;
		if (InlineJavaClass.ClassIsReadHandle(o.getClass())){
			if (o instanceof java.io.Reader){
				char buf[] = new char[len] ;
				int rc = ((java.io.Reader)o).read(buf) ;
				if (rc != -1){
					ret = new String(buf) ;
				}
			}
			else {
				byte buf[] = new byte[len] ;
				int rc = ((java.io.InputStream)o).read(buf) ;
				if (rc != -1){
					ret = new String(buf, charset) ;
				}
			}
		}
		else {
			throw new InlineJavaException("Can't read from non-readhandle object (" + o.getClass().getName() + ")") ;
		}

		return ret ;
	}

	
	static String readLine(Object o) throws InlineJavaException, IOException {
		String ret = null ;
		if (InlineJavaClass.ClassIsReadHandle(o.getClass())){
			if (o instanceof java.io.BufferedReader){
				ret = ((java.io.BufferedReader)o).readLine() ;
			}
			else {
				throw new InlineJavaException("Can't read line from non-buffered Reader or InputStream") ;
			}
		}
		else {
			throw new InlineJavaException("Can't read line from non-readhandle object (" + o.getClass().getName() + ")") ;
		}

		return ret ;
	}


	static Object makeBuffered(Object o) throws InlineJavaException, IOException {
		Object ret = null ;
		if (InlineJavaClass.ClassIsReadHandle(o.getClass())){
			if (o instanceof java.io.BufferedReader){
				ret = (java.io.BufferedReader)o ;
			}
			else if (o instanceof java.io.Reader){
				ret = new BufferedReader((java.io.Reader)o) ;
			}
			else {
				ret = new BufferedReader(new InputStreamReader((java.io.InputStream)o, charset)) ;
			}
		}
		else if (InlineJavaClass.ClassIsWriteHandle(o.getClass())){
			if (o instanceof java.io.BufferedWriter){
				ret = (java.io.BufferedWriter)o ;
			}
			else if (o instanceof java.io.Writer){
				ret = new BufferedWriter((java.io.Writer)o) ;
			}
			else {
				ret = new BufferedWriter(new OutputStreamWriter((java.io.OutputStream)o, charset)) ;
			}
		}
		else {
			throw new InlineJavaException("Can't make non-handle object buffered (" + o.getClass().getName() + ")") ;
		}

		return ret ;
	}

	
	static int write(Object o, String str) throws InlineJavaException, IOException {
		int ret = -1 ;
		if (InlineJavaClass.ClassIsWriteHandle(o.getClass())){
			if (o instanceof java.io.Writer){
				((java.io.Writer)o).write(str) ;
				ret = str.length() ;
			}
			else {
				byte b[] = str.getBytes(charset) ;
				((java.io.OutputStream)o).write(b) ;
				ret = b.length ;
			}
		}
		else {
			throw new InlineJavaException("Can't write to non-writehandle object (" + o.getClass().getName() + ")") ;
		}

		return ret ;
	}


	static void close(Object o) throws InlineJavaException, IOException {
		if (InlineJavaClass.ClassIsReadHandle(o.getClass())){
			if (o instanceof java.io.Reader){
				((java.io.Reader)o).close() ;
			}
			else {
				((java.io.InputStream)o).close() ;
			}
		}
		else if (InlineJavaClass.ClassIsWriteHandle(o.getClass())){
			if (o instanceof java.io.Writer){
				((java.io.Writer)o).close() ;
			}
			else {
				((java.io.OutputStream)o).close() ;
			}
		}
		else {
			throw new InlineJavaException("Can't close non-handle object (" + o.getClass().getName() + ")") ;
		}
	}
}
