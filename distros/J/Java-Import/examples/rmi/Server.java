import java.rmi.*;

public class Server {
	public static void main (String[] argv) {
		try {
			Naming.rebind ("Hello", new RemoteObject("Hello Perl!"));
			System.out.println ("Hello Server is ready.");
		} catch (Exception e) {
			System.out.println ("Hello Server failed: " + e);
		}
	}
}
