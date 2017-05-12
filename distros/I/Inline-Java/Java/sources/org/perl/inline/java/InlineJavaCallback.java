package org.perl.inline.java ;

import java.util.* ;
import java.io.* ;


/*
	Callback to Perl...
*/
class InlineJavaCallback {
	private InlineJavaServer ijs = InlineJavaServer.GetInstance() ;
	private String pkg = null ;
	private InlineJavaPerlObject obj = null ;
	private String method = null ;
	private Object args[] = null ;
	private Class cast = null ;
	private Object response = null ;
	private boolean response_set = false ;


	InlineJavaCallback(String _pkg, String _method, Object _args[], Class _cast) {
		this(null, _pkg, _method, _args, _cast) ;
	}
	
	
	InlineJavaCallback(InlineJavaPerlObject _obj, String _method, Object _args[], Class _cast) {
		this(_obj, null, _method, _args, _cast) ;
		if (obj == null){
			throw new NullPointerException() ;
		}
	}
	
	
	private InlineJavaCallback(InlineJavaPerlObject _obj, String _pkg, String _method, Object _args[], Class _cast) {
		obj = _obj ;
		pkg = _pkg ;
		method = _method ;
		args = _args ;
		cast = _cast ;
				
		if (method == null){
			throw new NullPointerException() ;
		}
		if (cast == null){
			cast = java.lang.Object.class ;
		}
	}


	private String GetCommand(InlineJavaProtocol ijp) throws InlineJavaException {
		String via = null ;
		if (obj != null){
			via = "" + obj.GetId() ;
		}
		else if (pkg != null){
			via = pkg ;
		}
		StringBuffer cmdb = new StringBuffer("callback " + via + " " + method + " " + cast.getName()) ;
		if (args != null){
			for (int i = 0 ; i < args.length ; i++){
				cmdb.append(" " + ijp.SerializeObject(args[i], null)) ;
			}
		}
		return cmdb.toString() ;
	}


	void ClearResponse(){
		response = null ;
		response_set = false ;
	}


	Object GetResponse(){
		return response ;
	}


	synchronized Object WaitForResponse(Thread t){
		while (! response_set){
			try {
				InlineJavaUtils.debug(3, "waiting for callback response in " + t.getName() + "...") ;
				wait() ;
			}
			catch (InterruptedException ie){
				// Do nothing, return and wait() some more...
			}
		}
		InlineJavaUtils.debug(3, "got callback response") ;
		Object resp = response ;
		response = null ;
		response_set = false ;
		return resp ;
	}


	synchronized void NotifyOfResponse(Thread t){
		InlineJavaUtils.debug(3, "notifying that callback has completed in " + t.getName()) ;
		notify() ;
	}


	synchronized void Process() throws InlineJavaException, InlineJavaPerlException {
		Object ret = null ;
		try {
			InlineJavaProtocol ijp = new InlineJavaProtocol(ijs, null) ;
			String cmd = GetCommand(ijp) ;
			InlineJavaUtils.debug(2, "callback command: " + cmd) ;

			Thread t = Thread.currentThread() ;
			String resp = null ;
			while (true) {
				InlineJavaUtils.debug(3, "packet sent (callback) is " + cmd) ;
				if (! ijs.IsJNI()){
					// Client-server mode.
					InlineJavaServerThread ijt = (InlineJavaServerThread)t ;
					ijt.GetWriter().write(cmd + "\n") ;
					ijt.GetWriter().flush() ;

					resp = ijt.GetReader().readLine() ;
				}
				else{
					// JNI mode
					resp = ijs.jni_callback(cmd) ;
				}
				InlineJavaUtils.debug(3, "packet recv (callback) is " + resp) ;

				StringTokenizer st = new StringTokenizer(resp, " ") ;
				String c = st.nextToken() ;
				if (c.equals("callback")){
					boolean thrown = new Boolean(st.nextToken()).booleanValue() ;
					String arg = st.nextToken() ;
					InlineJavaClass ijc = new InlineJavaClass(ijs, ijp) ;
					ret = ijc.CastArgument(cast, arg) ;

					if (thrown){
						throw new InlineJavaPerlException(ret) ;
					}

					break ;
				}
				else{
					// Pass it on through the regular channel...
					InlineJavaUtils.debug(3, "packet is not callback response: " + resp) ;
					cmd = ijs.ProcessCommand(resp, false) ;

					continue ;
				}
			}
		}
		catch (IOException e){
			throw new InlineJavaException("IO error: " + e.getMessage()) ;
		}

		response = ret ;
		response_set = true ;
	}
}
