package vrml.node; 
import java.util.Hashtable;
import vrml.Field;
import vrml.ConstField;

//
// This is the general Node class
// 
public abstract class Node extends vrml.BaseNode
{ 
   Hashtable fields;
   // Get an EventIn by name. Return value is write-only.
   //   Throws an InvalidEventInException if eventInName isn't a valid
   //   eventIn name for a node of this type.
   public final Field getEventIn(String eventInName) {
	return (Field)fields.get(eventInName);
   }

   // Get an EventOut by name. Return value is read-only.
   //   Throws an InvalidEventOutException if eventOutName isn't a valid
   //   eventOut name for a node of this type.
   public final ConstField getEventOut(String eventOutName) {
	return (ConstField)fields.get(eventOutName);
   }

   // Get an exposed field by name. 
   //   Throws an InvalidExposedFieldException if exposedFieldName isn't a valid
   //   exposedField name for a node of this type.
   public final Field getExposedField(String exposedFieldName) {
	return (Field)fields.get(exposedFieldName);
   }

   public String toString() { return ""; }   // This overrides a method in Object
}


