// Copyright (C) 1998 Tuomas J. Lukka
// DISTRIBUTED WITH NO WARRANTY, EXPRESS OR IMPLIED.
// See the GNU Library General Public License (file COPYING in the distribution)
// for conditions of use and redistribution.

package vrml.external;
import java.net.*;
import java.io.*;
import java.util.Hashtable;
import vrml.external.exception.*;
import vrml.external.field.*;

public class FreeWRLBrowser implements IBrowser, Runnable {

  Socket sock;
  InputStream istr;
  LineNumberReader ird;
  OutputStream ostr;
  PrintWriter owr;
  Thread inputter;
  int reqno;
  int obsno;
 
  Hashtable results;
  Hashtable eventouts;

  // construct an instance of the Browser class
  // Associates this instance with the first embedded plugin in the current frame.
  public FreeWRLBrowser(String worldfile) throws Exception {
	Runtime rt = Runtime.getRuntime();
  	ServerSocket s = new ServerSocket(0);
	int port = s.getLocalPort();
	String ea = new String("freewrl >/tmp/VRMLLOG 2>/tmp/VRMLERR ")
	 	+ "-eai 127.0.0.1:" + String.valueOf(port)
			+ " " + worldfile ;
  	rt.exec(new String[]{"sh","-c",ea});
	sock = s.accept();
	s.close();
	istr = sock.getInputStream();
	ird = new LineNumberReader(new InputStreamReader(istr));
	ostr = sock.getOutputStream();
	owr = new PrintWriter(ostr);
	owr.println("TJL EAI CLIENT 0.01");
	owr.flush();
	String ver = ird.readLine().trim();
	if(!ver.equals("TJL EAI FREEWRL 0.01")) {
		throw new Exception(
			"Wrong EAI connection version '"+ver+"'!"
		);
	}
	// Now we are ready to put / get requests.
	inputter = new Thread(this);
	inputter.setDaemon(true);
	inputter.start();
	reqno=42;
	obsno=4269;
	results = new Hashtable();
	eventouts = new Hashtable();
  };

  // Thread to run to get inputs.
  public void run() {
  	String str = "";
  	while(true) {
		System.out.println("WAITING INPUT");
		try {
			str = ird.readLine().trim();
		System.out.println("GOT INPUT "+str);
		if(str.equals("RE")) {
			String reqid = ird.readLine().trim();
			int n = new Integer(ird.readLine().trim()).intValue();
			String []p = new String[n];
			for(int i=0; i<n; i++) {
				p[i] = ird.readLine().trim();
				System.out.println("READ INPUT "+p[i]);
			}
			synchronized(this) {
				results.put(reqid, p);
				notifyAll();
			}
		} else if(str.equals("EV")) {
			String lid = ird.readLine().trim();
			String val = ird.readLine().trim();
			// We mustn't block here ; the observer might
			// try to send an event and that would freeze us
			// We must make a new thread
			// If this turns out too slow, we can make
			// one extra thread to do this.
			EventOut eo = (EventOut)eventouts.get(lid);
			try {
				eo.value__set(val);
			} catch (Exception e) {
				System.err.println("INVLID FIELD "+e.toString());
			}
			Thread notifier = new Thread(eo);
			notifier.start();
		} else {
			System.err.println("WEIRD! Invalid communication");
			// Not implemented yet
		}
		} catch(IOException e) {
			System.err.println("Exception! "+e.toString());
		}
	}
  }

  private synchronized String[] do__request(String []req) {
	String reqid = String.valueOf(reqno++);
	owr.println(reqid);
	for(int i=0; i<req.length; i++) {
		System.out.println("SENDING EVENT LINE: "+req[i]);
		owr.println(req[i]);
	}
	System.out.println("WAITING\n");
	owr.flush();
	while(results.get(reqid) == null) {
		try {
			wait();
		} catch (InterruptedException e) {
			System.err.println("WaitException! "+e.toString());
		}
	}
	System.out.println("WAITED\n");
	return (String[]) results.remove(reqid);
  }

  public EventIn get__eventin(String id, String name) {
  	String req = "GI "+id+" "+name;
	String res[] = this.do__request(new String[]{req});
	if(res[0].equals("SFColor")) {
		return new EventInSFColor(this,id,name);
	} else {
		System.out.println("Bad eventin type :(");
		return null;
	}
  }

  // Synchronized because we create new observer
  public synchronized EventOut get__eventout(String id, String name) {
  	String req = "GO "+id+" "+name;
	String res[] = this.do__request(new String[]{req});
	EventOut eo;
	if(res[0].equals("SFColor")) {
		eo = new EventOutSFColor();
	} else if(res[0].equals("SFBool")) {
		eo =  new EventOutSFBool();
	} else if(res[0].equals("SFTime")) {
		eo =  new EventOutSFTime();
	} else {
		System.out.println("Bad eventout type :(");
		return null;
	}
	try {
		eo.value__set(res[1]);
	} catch (Exception e) {
		System.err.println("INVLID FIELD "+e.toString());
	}
	String lid = String.valueOf(obsno++);
	eventouts.put(lid,eo);
	this.do__request(new String[]{"RL "+id+" "+name+" "+lid});
	return eo;
  }

  public void finalize() {
  };

  public void send__eventin(String node, String field, String val) {
  	String req = "SE "+node+" "+field;
	String res[] = this.do__request(new String[]{req,val});
  }

  // Get the "name" and "version" of the VRML browser (browser-specific)
  public String        getName() { return ""; }
  public String        getVersion() { return ""; }

  // Get the current velocity of the bound viewpoint in meters/sec,
  // if available, or 0.0 if not
  public float         getCurrentSpeed() { return 0.0F; }

  // Get the current frame rate of the browser, or 0.0 if not available
  public float         getCurrentFrameRate() { return 0.0F; }

  // Get the URL for the root of the current world, or an empty string
  // if not available
  public String        getWorldURL() { return ""; }

  // Replace the current world with the passed array of nodes
  public void          replaceWorld(Node[] nodes) { }

  // Load the given URL with the passed parameters (as described
  // in the Anchor node)
  public void          loadURL(String[] url, String[] parameter)
  	{ }

  // Set the description of the current world in a browser-specific
  // manner. To clear the description, pass an empty string as argument
  public void          setDescription(String description) { }

  // Parse STRING into a VRML scene and return the list of root
  // nodes for the resulting scene
  public Node[]        createVrmlFromString(String vrmlSyntax)
       throws InvalidVrmlException { return new Node[] {}; }

  // Tells the browser to load a VRML scene from the passed URL or
  // URLs. After the scene is loaded, an event is sent to the MFNode
  // eventIn in node NODE named by the EVENT argument
  public void          createVrmlFromURL(String[] url,
                                         Node node,
                                         String event) { }

  // Get a DEFed node by name. Nodes given names in the root scene
  // graph must be made available to this method. DEFed nodes in inlines,
  // as well as DEFed nodes returned from createVrmlFromString/URL, may
  // or may not be made available to this method, depending on the
  // browser's implementation
  public Node          getNode(String name)
       throws InvalidNodeException
	{	
		String req = "GN "+name;
		String id[] = this.do__request(new String[]{req});
		return new Node(this,id[0]); 
	} 

  // Add and delete, respectively, a route between the specified eventOut
  // and eventIn of the given nodes
  public void          addRoute(Node fromNode, String fromEventOut,
                                Node toNode, String toEventIn)
       throws IllegalArgumentException { }
  public void          deleteRoute(Node fromNode, String fromEventOut,
                                   Node toNode, String toEventIn)
       throws IllegalArgumentException { }

  // begin and end an update cycle
  public void          beginUpdate() { }
  public void          endUpdate() { }

  // called after the scene is loaded, before the first event is processed
  public void initialize() { }

  // called just before the scene is unloaded
  public void shutdown() { }
}
