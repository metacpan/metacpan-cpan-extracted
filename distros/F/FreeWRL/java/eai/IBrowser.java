// Copyright (C) 1998 Tuomas J. Lukka
// DISTRIBUTED WITH NO WARRANTY, EXPRESS OR IMPLIED.
// See the GNU Library General Public License (file COPYING in the distribution)
// for conditions of use and redistribution.

package vrml.external;
import vrml.external.exception.*;


// Specification of the External Interface for a VRML browser.
// taken directly from the EAI spec

public interface IBrowser {
  // Get the "name" and "version" of the VRML browser (browser-specific)
  public String        getName();
  public String        getVersion();

  // Get the current velocity of the bound viewpoint in meters/sec,
  // if available, or 0.0 if not
  public float         getCurrentSpeed();

  // Get the current frame rate of the browser, or 0.0 if not available
  public float         getCurrentFrameRate();

  // Get the URL for the root of the current world, or an empty string
  // if not available
  public String        getWorldURL();

  // Replace the current world with the passed array of nodes
  public void          replaceWorld(Node[] nodes)
       throws IllegalArgumentException;

  // Load the given URL with the passed parameters (as described
  // in the Anchor node)
  public void          loadURL(String[] url, String[] parameter);

  // Set the description of the current world in a browser-specific
  // manner. To clear the description, pass an empty string as argument
  public void          setDescription(String description);

  // Parse STRING into a VRML scene and return the list of root
  // nodes for the resulting scene
  public Node[]        createVrmlFromString(String vrmlSyntax)
       throws InvalidVrmlException;

  // Tells the browser to load a VRML scene from the passed URL or
  // URLs. After the scene is loaded, an event is sent to the MFNode
  // eventIn in node NODE named by the EVENT argument
  public void          createVrmlFromURL(String[] url,
                                         Node node,
                                         String event);

  // Get a DEFed node by name. Nodes given names in the root scene
  // graph must be made available to this method. DEFed nodes in inlines,
  // as well as DEFed nodes returned from createVrmlFromString/URL, may
  // or may not be made available to this method, depending on the
  // browser's implementation
  public Node          getNode(String name)
       throws InvalidNodeException;

  // Add and delete, respectively, a route between the specified eventOut
  // and eventIn of the given nodes
  public void          addRoute(Node fromNode, String fromEventOut,
                                Node toNode, String toEventIn)
       throws IllegalArgumentException;
  public void          deleteRoute(Node fromNode, String fromEventOut,
                                   Node toNode, String toEventIn)
       throws IllegalArgumentException;

  // begin and end an update cycle
  public void          beginUpdate();
  public void          endUpdate();

  // called after the scene is loaded, before the first event is processed
  public void initialize();

  // called just before the scene is unloaded
  public void shutdown();
}


