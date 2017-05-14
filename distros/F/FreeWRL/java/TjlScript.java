import java.lang.reflect.*;
import java.io.*;
import java.util.Hashtable;
import java.util.Vector;
import java.util.Stack;
import vrml.*;
import vrml.node.*;

public final class TjlScript {
	static Stack touched = new Stack();
	static PrintWriter out;
	static LineNumberReader in;
	public static void add_touched(TjlBinding b) {
		System.err.println("add_touched\n");
		touched.push(b);
	}
	public static void send_touched(String reqid) {
		System.err.println("send_touched\n");
		while(!touched.empty()) {
			System.err.println("send_touched one\n");
			TjlBinding b = (TjlBinding)touched.pop();
			BaseNode n = b.node();
			String f = b.field();
			String nodeid = n._get_nodeid();
			out.println("SENDEVENT");
			out.println(nodeid);
			out.println(f);
			String v = ((Script)n).getEventOut(f).toString();
			out.println(v);
		}
		out.println("FINISHED");
		out.println(reqid);
		out.flush();
	}
	public static void main (String argv[]) 
  	  throws ClassNotFoundException,
		NoSuchMethodException,
		InstantiationException,
		IllegalAccessException,
		InvocationTargetException,
		Exception,
		Throwable
	 {
		out = new PrintWriter(new FileOutputStream(".javapipej"));
		in = new LineNumberReader(
			new InputStreamReader(
			new FileInputStream(".javapipep")));
	 	Hashtable scripts = new Hashtable();
		String dirname = argv[0];
//		out.println("Hello World!\n");
//		Class mr = Class.forName("MuchRed");
//		Constructor mrc = mr.getConstructor(
//			new Class[] {});
//		Script c = (Script)mrc.newInstance(new Class[] {});
//		c.eventsProcessed();
//		out.println("Goodbye World!\n");
		try {
		String ver = in.readLine().trim();
		System.err.println("Got a line:'"+ver+"'");
		// Stupid handshake - just make sure about protocol.
		// Change this often between versions.
		if(!ver.equals("TJL XXX PERL-JAVA 0.00")) {
			throw new Exception(
				"Wrong script version '"+ver+"'!"
			);
		}
		System.err.println("Sending a line:'"+ver+"'");
		out.println("TJL XXX JAVA-PERL 0.00");
		System.err.println("Sent a line:'"+ver+"'");
		out.flush();
		String dir = in.readLine().trim();
		System.err.println("GOT DIRl a line:'"+dir+"'");
		TjlClassLoader tl = new TjlClassLoader(dir,
			dir.getClass().getClassLoader());
		out.flush();
		while(true) {
			String cmd = in.readLine();
			System.err.println("got ");
			System.err.println("--- "+cmd);
			cmd = cmd.trim();
			String nodeid =	in.readLine().trim();
			if(cmd.equals("NEWSCRIPT")) {
				String url = in.readLine().trim();
				System.err.println("NEWSCRIPT");
				Constructor mrc = tl.loadFile(url).
					getConstructor(new Class[0]);
				System.err.println("GOt constructor");
				Script s = (Script)mrc.newInstance(
						new Class[0]);
				s._set_nodeid(nodeid);
				System.err.println("GOt instance");
				scripts.put(nodeid,s);
				int nfields = 
					new Integer(in.readLine().trim()).intValue(); 
				for(int i=0; i<nfields; i++) {
					System.err.println("GOt fieldid");
					String fkind = in.readLine().trim();
					String ftype = in.readLine().trim();
					String fname = in.readLine().trim();
					vrml.Field fval = null;
					String cname = "vrml.field."+ftype;
					System.err.println("CONS FIELD "+cname);
					Class[] tmp = new Class[1];
					tmp[0] = Class.forName("java.lang.String");
					Constructor cons = 
						Class.forName(cname).
						 getConstructor(tmp);
					System.err.println("GOt fieldcons");
					Object[] tmpo = new Object[1]; 
					if(fkind.equals("field")) {
						String fs = in.readLine().trim();
						tmpo[0] = fs;
					} else {
						tmpo[0] = null;
					}
					try {
						fval = (vrml.Field)cons.newInstance(tmpo);
					} catch(InvocationTargetException e) {
						throw e.getTargetException();
					}
					if(fkind.equals("eventOut")) {
						fval.bind_to(new TjlBinding(
							s, fname));
					}
					s.add_field(fkind,ftype,fname,fval);
				}
			} else if(cmd.equals("SETFIELD")) {
			} else if(cmd.equals("INITIALIZE")) {
				Script s = (Script)scripts.get(nodeid);
				String reqid = in.readLine().trim();
				s.initialize();
				send_touched(reqid);
			} else if(cmd.equals("EVENTSPROCESSED")) {
				Script s = (Script)scripts.get(nodeid);
				String reqid = in.readLine().trim();
				s.eventsProcessed();
				send_touched(reqid);
			} else if(cmd.equals("SENDEVENT")) {
				Script s = (Script)scripts.get(nodeid);
				String reqid = in.readLine().trim();
				String fname = in.readLine().trim();
				String ftype = "vrml.field.Const" +
					s.get_field_type(fname);
				String fs = in.readLine().trim();
				Class tmpc[] = new Class[1];
				tmpc[0] = Class.forName("java.lang.String");
				Constructor cons = 
					Class.forName(ftype).
					 getConstructor(tmpc);
				ConstField fval;
				Object[] tmpo = new Object[1]; 
				tmpo[0] = fs;
				try {
				fval = (vrml.ConstField)cons.newInstance(
					tmpo
				) ;
				} catch(InvocationTargetException e) {
					throw e.getTargetException();
				}
				double timestamp = new 
				    Double(in.readLine().trim()).doubleValue();
				Event ev = new Event(
					fname, 
					timestamp,
					fval
				);
				s.processEvent(ev);
				send_touched(reqid);
			} else {
				throw new Exception("Invalid command '"
						+ cmd + "'");
			}
		}
		} catch(IOException e) {
			System.err.println(e);
			throw new Exception("Io error");
		}
		
	}
}
