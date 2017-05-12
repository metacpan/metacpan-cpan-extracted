package org.perl.inline.java ;

import java.util.* ;
import java.io.* ;


/*
	Queue for callbacks to Perl...
*/
class InlineJavaCallbackQueue {
	// private InlineJavaServer ijs = InlineJavaServer.GetInstance() ;
	private ArrayList queue = new ArrayList() ;
	private boolean wait_interrupted = false ;
	private boolean stream_opened = false ;


	InlineJavaCallbackQueue(){
	}


	synchronized void EnqueueCallback(InlineJavaCallback ijc){
		queue.add(ijc) ;
		notify() ;
	}


	synchronized private InlineJavaCallback DequeueCallback(){
		if (GetSize() > 0){
			return (InlineJavaCallback)queue.remove(0) ;
		}
		return null ;
	}


    synchronized int WaitForCallback(double timeout){
        long secs = (long)Math.floor(timeout) ;
        double rest = timeout - ((double)secs) ;
        long millis = (long)Math.floor(rest * 1000.0) ;
        rest = (rest * 1000.0) - ((double)millis) ;
        int nanos = (int)Math.floor(rest * 1000000.0) ;

        return WaitForCallback((secs * 1000) + millis, nanos) ;
    }


	/*
		Blocks up to the specified time for the next callback to arrive.
		Returns -1 if the wait was interrupted voluntarily, 0 on timeout or
		> 0 if a callback has arrived before the timeout expired.
	*/
	synchronized int WaitForCallback(long millis, int nanos){
		wait_interrupted = false ;
		Thread t = Thread.currentThread() ;
		InlineJavaUtils.debug(3, "waiting for callback request (" + millis + " millis, " + 
			nanos + " nanos) in " + t.getName() + "...") ;

		if (! stream_opened){
			return -1 ;
		}

		while ((stream_opened)&&(! wait_interrupted)&&(IsEmpty())){
			try {
				wait(millis, nanos) ;
				// If we reach this code, it means the either we timed out
				// or that we were notify()ed. 
				// In the former case, we must break out and return 0.
				// In the latter case, either the queue will not be empty or 
                // wait_interrupted will be set. We must therefore also break out.
				break ;
			}
			catch (InterruptedException ie){
				// Do nothing, return and wait() some more...
			}
		}
		InlineJavaUtils.debug(3, "waiting for callback request finished " + t.getName() + "...") ;

		if (wait_interrupted){
			return -1 ;
		}
		else {
			return GetSize() ;
		}
	}


	/*
		Waits indefinetely for the next callback to arrive and executes it.
		Return true on success of false if the wait was interrupted voluntarily.
	*/
	synchronized boolean ProcessNextCallback() throws InlineJavaException, InlineJavaPerlException {
		int rc = WaitForCallback(0, 0) ;
		if (rc == -1){
			// Wait was interrupted
			return false ;
		}

		// DequeueCallback can't return null because we explicetely
		// waited until a callback was there.
		Thread t = Thread.currentThread() ;
		InlineJavaUtils.debug(3, "processing callback request in " + t.getName() + "...") ;
		InlineJavaCallback ijc = DequeueCallback() ;
		ijc.Process() ;
		ijc.NotifyOfResponse(t) ;

		return true ;
	}


	private boolean IsEmpty(){
		return (GetSize() == 0) ;
	}


	void OpenCallbackStream(){
		stream_opened = true ;
	}


	synchronized void CloseCallbackStream(){
		stream_opened = false ;
		InterruptWaitForCallback() ;
	}


	boolean IsStreamOpen(){
		return stream_opened ;
	}


	int GetSize(){
		return queue.size() ;
	}


	synchronized private void InterruptWaitForCallback(){
		Thread t = Thread.currentThread() ;
		InlineJavaUtils.debug(3, "interrupting wait for callback request in " + t.getName() + "...") ;
		wait_interrupted = true ;
		notify() ;
	}
}
