package org.perl.inline.java ;

import java.util.* ;
import java.io.* ;


/*
	Callback to Perl...
*/
public class InlineJavaPerlCaller {
	private InlineJavaServer ijs = InlineJavaServer.GetInstance() ;
	private Thread creator = null ;
	static private Map thread_callback_queues = Collections.synchronizedMap(new HashMap()) ;
	static private ResourceBundle resources = null ;
	static private boolean inited = false ;


	/*
		Only thread that communicate with Perl are allowed to create PerlCallers because
		this is where we get the thread that needs to be notified when the callbacks come in.
	*/
	public InlineJavaPerlCaller() throws InlineJavaException {
		init() ;
		Thread t = Thread.currentThread() ;
		if (ijs.IsThreadPerlContact(t)){
			creator = t ;
		}
		else{
			throw new InlineJavaException("InlineJavaPerlCaller objects can only be created by threads that communicate directly with Perl") ;
		}
	}


	synchronized static protected void init() throws InlineJavaException {
		if (! inited){
			try {
				resources = ResourceBundle.getBundle("InlineJava") ;

				inited = true ;
			}
			catch (MissingResourceException mre){
				throw new InlineJavaException("Error loading InlineJava.properties: " + mre.getMessage()) ;
			}
		}
	}


	static protected ResourceBundle GetBundle(){
		return resources ;
	}

	/* Old interface */
	/**
	 * @deprecated  As of 0.48, replaced by {@link #CallPerlSub(String,Object[])}
	 */
	public Object CallPerl(String pkg, String method, Object args[]) throws InlineJavaException, InlineJavaPerlException {
		return CallPerl(pkg, method, args, null) ;
	}


	/* Old interface */
	/**
	 * @deprecated  As of 0.48, replaced by {@link #CallPerlSub(String,Object[],Class)}
	 */
	public Object CallPerl(String pkg, String method, Object args[], String cast) throws InlineJavaException, InlineJavaPerlException {
		InlineJavaCallback ijc = new InlineJavaCallback(
			(String)null, pkg + "::" + method, args, 
			(cast == null ? null : InlineJavaClass.ValidateClass(cast))) ; 
		return CallPerl(ijc) ;
	}


	/* New interface */
	public Object CallPerlSub(String sub, Object args[]) throws InlineJavaException, InlineJavaPerlException {
		return CallPerlSub(sub, args, null) ;
	}
	
	
	/* New interface */	
	public Object CallPerlSub(String sub, Object args[], Class cast) throws InlineJavaException, InlineJavaPerlException {
		InlineJavaCallback ijc = new InlineJavaCallback(
			(String)null, sub, args, cast) ; 
		return CallPerl(ijc) ;
	}
	
	
	/* New interface */
	public Object CallPerlMethod(InlineJavaPerlObject obj, String method, Object args[]) throws InlineJavaException, InlineJavaPerlException {
		return CallPerlMethod(obj, method, args, null) ;
	}
	
	
	/* New interface */	
	public Object CallPerlMethod(InlineJavaPerlObject obj, String method, Object args[], Class cast) throws InlineJavaException, InlineJavaPerlException {
		InlineJavaCallback ijc = new InlineJavaCallback(
			obj, method, args, cast) ; 
		return CallPerl(ijc) ;
	}


	/* New interface */
	public Object CallPerlStaticMethod(String pkg, String method, Object args[]) throws InlineJavaException, InlineJavaPerlException {
		return CallPerlStaticMethod(pkg, method, args, null) ;
	}
	
	
	/* New interface */	
	public Object CallPerlStaticMethod(String pkg, String method, Object args[], Class cast) throws InlineJavaException, InlineJavaPerlException {
		InlineJavaCallback ijc = new InlineJavaCallback(
			pkg, method, args, cast) ; 
		return CallPerl(ijc) ;
	}


	public Object eval(String code) throws InlineJavaPerlException, InlineJavaException {
		return eval(code, null) ;
	}


	public Object eval(String code, Class cast) throws InlineJavaPerlException, InlineJavaException {
		return CallPerlSub("Inline::Java::Callback::java_eval", new Object [] {code}, cast) ;
	}


	public Object require(String module_or_file) throws InlineJavaPerlException, InlineJavaException {
		return CallPerlSub("Inline::Java::Callback::java_require", new Object [] {module_or_file}) ;
	}


	public Object require_file(String file) throws InlineJavaPerlException, InlineJavaException {
		return CallPerlSub("Inline::Java::Callback::java_require", new Object [] {file, new Boolean("true")}) ;
	}
	
	
	public Object require_module(String module) throws InlineJavaPerlException, InlineJavaException {
		return CallPerlSub("Inline::Java::Callback::java_require", new Object [] {module, new Boolean("false")}) ;
	}
	

	private Object CallPerl(InlineJavaCallback ijc) throws InlineJavaException, InlineJavaPerlException {
		Thread t = Thread.currentThread() ;
		if (t == creator){
			ijc.Process() ;
			return ijc.GetResponse() ;
		}
		else {
			// Enqueue the callback into the creator thread's queue and notify it
			// that there is some work for him.
			ijc.ClearResponse() ;
			InlineJavaCallbackQueue q = GetQueue(creator) ;
			InlineJavaUtils.debug(3, "enqueing callback for processing for " + creator.getName() + " in " + t.getName() + "...") ;
			q.EnqueueCallback(ijc) ;
			InlineJavaUtils.debug(3, "notifying that a callback request is available for " + creator.getName() + " in " + t.getName()) ;

			// Now we must wait until the callback is processed and get back the result...
			return ijc.WaitForResponse(t) ;
		}
	}


	public void OpenCallbackStream() throws InlineJavaException {
		Thread t = Thread.currentThread() ;
		if (! ijs.IsThreadPerlContact(t)){
			throw new InlineJavaException("InlineJavaPerlCaller.OpenCallbackStream() can only be called by threads that communicate directly with Perl") ;
		}

		InlineJavaCallbackQueue q = GetQueue(t) ;
		q.OpenCallbackStream() ;
	}


	/* 
		Blocks until either a callback arrives, timeout seconds has passed or the call is 
		interrupted by Interrupt?
	*/
	public int WaitForCallback(double timeout) throws InlineJavaException {
		Thread t = Thread.currentThread() ;
		if (! ijs.IsThreadPerlContact(t)){
			throw new InlineJavaException("InlineJavaPerlCaller.WaitForCallback() can only be called by threads that communicate directly with Perl") ;
		}

		InlineJavaCallbackQueue q = GetQueue(t) ;
		if (timeout == 0.0){
			// no wait
			return q.GetSize() ;
		}
		else if (timeout == -1.0){
			timeout = 0.0 ;
		}

		return q.WaitForCallback(timeout) ;
	}


	public boolean ProcessNextCallback() throws InlineJavaException, InlineJavaPerlException {
		Thread t = Thread.currentThread() ;
		if (! ijs.IsThreadPerlContact(t)){
			throw new InlineJavaException("InlineJavaPerlCaller.ProcessNextCallback() can only be called by threads that communicate directly with Perl") ;
		}

		InlineJavaCallbackQueue q = GetQueue(t) ;
		return q.ProcessNextCallback() ;
	}


	public void CloseCallbackStream() throws InlineJavaException {
		InlineJavaCallbackQueue q = GetQueue(creator) ;
		q.CloseCallbackStream() ;
	}


	public void StartCallbackLoop() throws InlineJavaException, InlineJavaPerlException {
		Thread t = Thread.currentThread() ;
		if (! ijs.IsThreadPerlContact(t)){
			throw new InlineJavaException("InlineJavaPerlCaller.StartCallbackLoop() can only be called by threads that communicate directly with Perl") ;
		}
	
		InlineJavaCallbackQueue q = GetQueue(t) ;
		InlineJavaUtils.debug(3, "starting callback loop for " + creator.getName() + " in " + t.getName()) ;
		q.OpenCallbackStream() ;
		while (q.IsStreamOpen()){
			q.ProcessNextCallback() ;
		}
	}


	public void StopCallbackLoop() throws InlineJavaException {
		Thread t = Thread.currentThread() ;
		InlineJavaCallbackQueue q = GetQueue(creator) ;
		InlineJavaUtils.debug(3, "stopping callback loop for " + creator.getName() + " in " + t.getName()) ;
		q.CloseCallbackStream() ;
	}


	/*
		Here the prototype accepts Threads because the JNI thread
		calls this method also.
	*/
	static synchronized void AddThread(Thread t){
		thread_callback_queues.put(t, new InlineJavaCallbackQueue()) ;
	}


	static synchronized void RemoveThread(InlineJavaServerThread t){
		thread_callback_queues.remove(t) ;
	}


	static private InlineJavaCallbackQueue GetQueue(Thread t) throws InlineJavaException {
		InlineJavaCallbackQueue q = (InlineJavaCallbackQueue)thread_callback_queues.get(t) ;

		if (q == null){
			throw new InlineJavaException("Can't find thread " + t.getName() + "!") ;
		}
		return q ;
	}
}
