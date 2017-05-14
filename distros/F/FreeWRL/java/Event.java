package vrml;


public class Event implements Cloneable 
{
   String name;
   double timestamp;
   ConstField value;

   public Event(String name2, double timestamp2, ConstField value2) {
	name=name2;
	timestamp = timestamp2;
	value = value2;
   }
   
 
  // Spec
   
   public String getName() { return name; }
   public double getTimeStamp() { return timestamp; }
   public ConstField getValue() { return value; }
   public Object clone() { return new Event(name,timestamp,value); }

   public String toString() { return ""; }   // This overrides a method in Object
}


