package vrml;
import vrml.Browser;


// This is the general BaseNode class
// 
public abstract class BaseNode 
{
   String nodetype;
   String nodeid;  // id for communication
   private Browser browser;
   public final void _set_nodeid(String s) {nodeid = s;}
   public final String _get_nodeid() {return nodeid;}
   // Returns the type of the node.  If the node is a prototype
   // it returns the name of the prototype.
   public String getType() { return nodetype; }

   // Get the Browser that this node is contained in.
   public Browser getBrowser() { return browser; }
}

