package com.example.common;

import java.awt.*;
import java.util.*;

/**
 *  This class provides fixed layout.  Each component should be added
 *  with a constraint.  The constraint is the (x, y) position in characters.
 *  (0, 0) is the upper left.  This class is provided for green screen
 *  emulation.  Those screens typically had 80 columns and 24 rows.  We
 *  can handle a few more of each here, but not a lot more.
 */
public class CharacterLayout implements LayoutManager2 {
  Rectangle boundingBox;
  Vector    components;
  Vector    constraints;

/**
 *  This is the constructor.  It does nothing fancy.
 */
  public CharacterLayout() {
    boundingBox = new Rectangle(0, 0, 0, 0);
    components  = new Vector();
    constraints = new Vector();
  }

/**
 *  Do not add components without constraints.  If you do, the JVM will
 *  call this method.  It places the component at the upper left.
 *  Use a constraint so that {@link #addLayoutComponent(Component, Object)}
 *  below is called instead.
 *
 *  @param name discarded
 *  @param comp the component to be added at 0, 0
 */
  public void addLayoutComponent(String name, Component comp) {
    addLayoutComponent(comp, new Point(0, 0));
  }

/**
 *  Called by the JVM when the container should be redrawn.  Use validate()
 *  on the container with this layout manager to obtain a refresh.
 *
 *  @param parent ignored
 */
  public void layoutContainer(Container parent) {
    Component comp;

    for (int i = 0; i < components.size(); i++) {
      comp = (Component)components.elementAt(i);
      Dimension preferredSize = comp.getPreferredSize();
      Point     location      = (Point)constraints.elementAt(i);
      comp.setBounds(new Rectangle(location, preferredSize));
    }
  }

/**
 *  Gives the size needed for the components on the container using this
 *  layout manager.
 *
 *  @param parent ignored
 *
 *  @return the size needed to layout the components currently managed
 */
  public Dimension minimumLayoutSize(Container parent) {
    return boundingBox.getSize();
  }

/**
 *  The same as minimumLayoutSize.  Gives the size needed for the components
 *  currently managed.
 *
 *  @param parent ignored
 *
 *  @return the size needed to layout the components currently managed
 */
  public Dimension preferredLayoutSize(Container parent) {
    return boundingBox.getSize();
  }

/**
 *  The same as minimumLayoutSize.  Gives the size needed for the components
 *  currently managed.
 *
 *  @param parent ignored
 *
 *  @return the size needed to layout the components currently managed
 */
  public Dimension maximumLayoutSize(Container parent) {
    return boundingBox.getSize();
  }

/**
 *  Removes the given component so that it will no longer be displayed
 *  nor contribute to the size of the container.
 *
 *  @param comp the component to be removed
 */
  public void removeLayoutComponent(Component comp) {
    int compPosition = components.indexOf(comp, 0);
    components .removeElementAt(compPosition);
    constraints.removeElementAt(compPosition);
    recalculateBoundingBox();
  }

/**
 *  Called by add(Component, (Point)Object) to add components with
 *  constraints to the layout.
 *
 *  @param comp the component to be added
 *  @param constraint a Point giving the (x, y) position of the component
 *  in characters (0, 0) is upper left, x increases to the right, y
 *  increases down.
 */
  public void addLayoutComponent(Component comp, Object constraint) {
    if (constraint == null) {
      constraint = new Point(0, 0);
    }
    FontMetrics fontMetrics   = comp.getFontMetrics(comp.getFont());

// We could:
// add a little fudge to the x coordinate to make slashes in dates more visible
// But only
// at the cost of alignment problems for pages dominated by literal text

    ((Point)constraint).x    *= fontMetrics.charWidth('m');
    ((Point)constraint).y    *= fontMetrics.getHeight() + 7;
    Rectangle newBoundingBox =
              new Rectangle((Point)constraint, comp.getPreferredSize());
    boundingBox              = boundingBox.union(newBoundingBox);
    components.add(comp);
    constraints.add(constraint);
  }

/*
 *  Used when components are removed from the layout.  Discards current
 *  bounding box and makes a new one with the components which are left.
 */
  private void recalculateBoundingBox() {
    if (components.size() == 0) {
      boundingBox = new Rectangle(0, 0, 0, 0);
    }
    Rectangle newBox = new Rectangle((Point)constraints.elementAt(0),
                   ((Component)components.elementAt(0)).getPreferredSize());

    for (int i = 1; i < components.size(); i++) {
      newBox = newBox.union(new Rectangle(
        (Point)constraints.elementAt(i),
        ((Component)components.elementAt(i)).getPreferredSize()
      ) );
    }
    boundingBox = newBox;
  }

/**
 *  Unimplemented, but required by LayoutManager2 interface.
 *
 *  @param target ignored
 *
 *  @return 0.5f
 */
  public float getLayoutAlignmentX(Container target) {
    return 0.5f;
  }

/**
 *  Unimplemented, but required by LayoutManager2 interface.
 *
 *  @param target ignored
 *
 *  @return 0.5f
 */
  public float getLayoutAlignmentY(Container target) {
    return 0.5f;
  }

/**
 *  Unimplemented, but required by LayoutManager2 interface.
 *
 *  @param target ignored
 */
  public void invalidateLayout(Container target) {
  }
}
