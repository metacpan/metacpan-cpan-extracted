import java.rmi.*;

public class Client {

	private RemoteInterface hello;
	
	public Client ( ) {
	}

	//public void connect ( String connectString ) {
	public void connect ( ) {
		try {
			hello = (RemoteInterface) Naming.lookup("//localhost/Hello");
		} catch ( Exception e ) {
			System.out.println("Client exception: " + e);
		}
	}

	public SomeBean getBeanFromServer ( ) {
		try {
			return hello.getMessage();
		} catch ( Exception e ) {
			System.out.println("Client exception: " + e);
		}
		return null;
	}

	public static void main ( String[] args ) {
		Client client = new Client();
		client.connect();
		SomeBean msg = client.getBeanFromServer();
		System.out.println(msg.getValue());
	}
}
