import java.lang.reflect.*;
import java.io.*;
import java.util.Hashtable;
import java.util.Vector;
import java.util.Stack;
import vrml.*;
import vrml.node.*;

public final class TjlClassLoader extends ClassLoader {
	String dirname;
	ClassLoader def;
	static Hashtable cache=new Hashtable();
	public TjlClassLoader(String d,
		ClassLoader deleg) {  // dir must end in '/'
		dirname = d;
		def = deleg;
	}
	public synchronized Class loadClass(String name,boolean resolve) 
		throws ClassFormatError,ClassNotFoundException {
			// delegate
			System.err.println("LOADING CLASS '"+name+"'");
			if(resolve) {
				System.err.println("SHOULD RESOLVE");
			}
			// Class c = def.loadClass(name);
			Class c = findSystemClass(name);
			System.err.println("LOADED CLASS '"+name+"'");
			return c;
			// throw new ClassFormatError("Can't load with Tjl..");
	}
	public Class loadFile(String name) throws 
		FileNotFoundException,IOException  {
		System.err.println("LOADING SCRIPT '"+name+"'");
		Class c = (Class)cache.get(name);
		if(c==null) {
			String n = dirname + name;
			System.err.println("LOADING FILE '"+name+"'");
			File f = new File(n);
			System.err.println(f.length());
			byte []data = new byte[(int)f.length()];
			FileInputStream fis = new FileInputStream(f);
			int l = fis.read(data);
			if(l != (int)f.length()) {
				throw new IOException("Couldn't read all");
			}
			// System.err.write(data,0,data.length);
			c = defineClass(data,0,data.length);
			System.err.println("Finished loading");
			cache.put(name,c);
		}
		return c;
	}
}



