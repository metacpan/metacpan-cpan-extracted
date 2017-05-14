import java.rmi.*;
public interface RemoteInterface extends Remote {
	public SomeBean getMessage() throws RemoteException;
}
