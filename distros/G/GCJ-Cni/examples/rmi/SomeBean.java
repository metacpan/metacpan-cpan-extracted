import java.io.*;

public class SomeBean implements Serializable {

	private String value;

	public SomeBean() {
	}

	public void setValue ( String _value ) {
		value = _value;
	}

	public String getValue ( ) {
		return value;
	}

}
