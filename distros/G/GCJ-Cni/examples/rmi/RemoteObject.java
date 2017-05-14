import java.rmi.*;
import java.rmi.server.*;

public class RemoteObject extends UnicastRemoteObject implements RemoteInterface {
  private String message;
  public RemoteObject (String msg) throws RemoteException {
    message = msg;
  }
  public SomeBean getMessage() throws RemoteException {
    SomeBean bean = new SomeBean();
    bean.setValue(message);
    return bean;
  }
}
