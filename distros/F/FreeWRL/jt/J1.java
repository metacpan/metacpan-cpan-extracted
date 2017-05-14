import java.lang.Math.*;
import vrml.*;
import vrml.field.*;
import vrml.node.*;

public class J1 extends Script {
	private SFColor color;
	private float fraction;
	public void initialize() {
		color = (SFColor) getEventOut("color");
	}
	public void processEvent(Event e) {
		fraction = ((ConstSFFloat)e.getValue()).getValue();
	}
	public void eventsProcessed() {
		double f = fraction*Math.PI;
		color.setValue(
			(float)(0.5*Math.sin(f*2)+0.5),
			(float)(0.5*Math.sin(f*3)+0.5),
			(float)(0.5*Math.sin(f*5)+0.5)
		);
	}
}
