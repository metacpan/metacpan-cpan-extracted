// Taken from the VRML97 spec, slightly altered.

import vrml.*;
import vrml.field.*;
import vrml.node.*;

public class MuchRed extends Script {
    // Declare field(s)
    private SFColor currentColor;

    // Declare eventOut
    private SFBool isRed;

    // buffer for  SFColor.getValue().
    private float colorBuff[] = new float[3];

    public void initialize(){
       currentColor = (SFColor) getField("currentColor");
       isRed = (SFBool) getEventOut("isRed");
    }

    public void processEvent(Event e){
        // This method is called when a colorIn event is received
        currentColor.setValue((ConstSFColor)e.getValue());
    }

    public void eventsProcessed(){
        currentColor.getValue(colorBuff);
        if (colorBuff[0] >= 0.5) // if red is at or above 50%
            isRed.setValue(true);
	else
	    isRed.setValue(false);
    }
}
