package vrml;
import java.lang.Cloneable;

public abstract class Field implements Cloneable
{
   TjlBinding tb[] = {};
   public Field() {} // tb = new TjlBinding[] {};}
   public abstract Object clone();

   public void bind_to(TjlBinding b) {
	tb = new TjlBinding[1]; tb[0] = b;
   }
   protected void value_touched() {
	for(int i=0; i<tb.length; i++) 
		tb[i].invoke();
   }
}


