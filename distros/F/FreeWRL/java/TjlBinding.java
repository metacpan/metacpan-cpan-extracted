package vrml;
import TjlScript;

public class TjlBinding {
	BaseNode node;
	String field;
	public TjlBinding(BaseNode n, String f) {
		node = n; field = f;
	}
	public void invoke() {
		TjlScript.add_touched(this);
	};
	public BaseNode node() {return node;}
	public String field() {return field;}
}
