package com.example.common;

import java.awt.*;
import java.util.*;

/**
 *  For all those who have had enough of the GridBagLayout, this class
 *  provides pixel control.  This hurts resizing.  When adding a component
 *  pass in a point (x, y) which will be the upper left pixel of the component.
 *
 *  The CharacterLayout class is similar, but it uses characters rather
 *  than pixels.  It is more convenient for emulating legacy green screens.
 */
public class PixelLayout implements LayoutManager2 {
  Rectangle boundingBox;
  Vector    components;
  Vector    constraints;

/**
 *  Standard constructor.
 */
  public PixelLayout() {
    boundingBox = new Rectangle(0, 0, 0, 0);
    components  = new Vector();
    constraints = new Vector();
  }

  public void addLayoutComponent(String name, Component comp) {
    addLayoutComponent(comp, new Point(0, 0));
  }
  public void layoutContainer(Container parent) {
    Component comp;

    for (int i = 0; i < components.size(); i++) {
      comp = (Component)components.elementAt(i);
      Dimension preferredSize = comp.getPreferredSize();
      Point     location      = (Point)constraints.elementAt(i);
      comp.setBounds(new Rectangle(location, preferredSize));
    }
  }
  public Dimension minimumLayoutSize(Container parent) {
    return boundingBox.getSize();
  }
  public Dimension preferredLayoutSize(Container parent) {
    return boundingBox.getSize();
  }
  public Dimension maximumLayoutSize(Container parent) {
    return boundingBox.getSize();
  }
  public void removeLayoutComponent(Component comp) {
    int compPosition = components.indexOf(comp, 0);
    components .removeElementAt(compPosition);
    constraints.removeElementAt(compPosition);
    recalculateBoundingBox();
  }

  public void addLayoutComponent(Component comp, Object constraint) {
    if (constraint == null) {
      constraint = new Point(0, 0);
    }
    Rectangle newBoundingBox =
              new Rectangle((Point)constraint, comp.getPreferredSize());
    boundingBox              = boundingBox.union(newBoundingBox);
    components.add(comp);
    constraints.add(constraint);
  }

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

// unused methods required by interface
  public float getLayoutAlignmentX(Container target) {
    return 0.5f;
  }
  public float getLayoutAlignmentY(Container target) {
    return 0.5f;
  }
  public void invalidateLayout(Container target) {
  }
}
