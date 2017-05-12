package com.example.common;

import java.awt.*;
import javax.swing.*;

/**
 *  This class is a Jlabel with monospaced font, fixed width,
 *  and highlighting.
 */
public class ExampleLabel extends JLabel {
  boolean underscored;
  boolean highlighted;
  int     width;
  static  Color HIGHLIGHT = Color.black;

/**
 *  Builds a new label with the given text.
 *
 *  @param string the new text for the label
 */
  public ExampleLabel(String string) {
    super(string);
    width = string.length();
  }

/**
 *  Puts the text on the screen.
 *
 *  @param g standard
 */
  public void paintComponent(Graphics g) {
    Dimension d = getSize();
    Color original = g.getColor();
    if (highlighted) {
      g.setColor(HIGHLIGHT);
      g.fillRect(0, 0, d.width, d.height);
      g.setColor(original);
    }
    g.drawString(getText(), 0, d.height - 2);
    if (underscored) {
      g.drawLine(0, d.height - 2, d.width, d.height - 2);
    }
  }

/**
 *  Allows the caller to turn underscoring on.
 *
 *  @param underscore true turns underscore on, false turns it off
 *
 */
  public void setUnderscored(boolean underscore) {
    underscored = underscore;
  }

/**
 *  Allows the caller to turn highlighting on.
 *
 *  @param highlight true turns highlight on, false turns it off
 *
 */
  public void setHighlighted(boolean highlight) {
    highlighted = highlight;
  }

/**
 *  Allows the caller to changed the decorations (underscoring and
 *  highlighting).
 *
 *  @param decorations a string of single character decorations: NONE
 *  turns off decorations, H turns on highlighting, U turns on underscoring
 */
  public void setDecorations(String decorations) {
    int len = decorations.length();
    if ((len == 0) || decorations.equalsIgnoreCase("none")) {
      underscored = highlighted = false;
      return;
    }
    highlighted = false;
    underscored = false;
    for (int i = 0; i < len; i++) {
      switch(decorations.charAt(i)) {
        case 'H': case 'h':
	  highlighted = true;
	  break;
	case 'U': case 'u':
	  underscored = true;
	  break;
      }
    }
//    setText("Text testing");
    repaint();
  }

/**
 *  @return the width of the label in characters
 */
  public int getColumns() {
    return width;
  }

  private int columnWidth = 0;
  private int rowHeight   = 0;

/**
 *  Gives the width of this label in pixels.
 *
 *  @return the number of horizontal pixels this label needs
 */
  public int getColumnWidth() {
    if (columnWidth == 0) {
      FontMetrics metrics = getFontMetrics(getFont());
      columnWidth = metrics.charWidth('m');
    }
    return columnWidth;
  }

/**
 *  Gives the height of this label in pixels.
 *
 *  @return the number of vertical pixels this label needs
 */
  public int getRowHeight() {
    if (rowHeight == 0) {
      FontMetrics metrics = getFontMetrics(getFont());
      rowHeight = metrics.getHeight();
    }
    return rowHeight;
  }

/**
 *  Required by ExampleComponent interface, simply gives current text.
 *
 *  @return the text on the label at present
 */
  public String getTextForBuffer() {
    return getText();
  }

/**
 *  Changes the text displayed by this field.  The string will be forced to
 *  the width in characters of the field.  Short strings will be padded,
 *  long ones with be truncated.
 *  
 *  @param text the new text to use, will be forced to the proper size
 */
  public void setText(String text) {
    if (width == 0) {
      super.setText(text);
      return;
    }
    if (text.length() < width) {
      byte[] pad = new byte[width - text.length()];
      for (int i = 0; i < pad.length; i++) {
        pad[i] = ' ';
      }
      String padding = new String(pad);
      super.setText(text + padding);
    }
    else if (text.length() > width) {
      super.setText(text.substring(0, width));
    }
    else {
      super.setText(text);
    }
  }

/**
 *  Gives the width and height of this label in pixels.
 *  @return the Dimension of this label in pixels
 */
  public Dimension getPreferredSize() {
    synchronized (getTreeLock()) {
      Dimension size = super.getPreferredSize();
      if (getColumns() != 0) {
        size.width = (int)Math.round(getColumns() * getColumnWidth()
                                + .5 * getColumnWidth()
                     );
      }
      return size;
    }
  }

/**
 *  Gives the preferred size.  ExampleLabels do not resize.
 *  @return the Dimension of this label in pixels
 */
  public Dimension getMinimumSize() {
    return getPreferredSize();
  }
/**
 *  Gives the preferred size.  ExampleLabels do not resize.
 *  @return the Dimension of this label in pixels
 */
  public Dimension getMaximumSize() {
    return getPreferredSize();
  }


/**
 *  Required by ExampleComponent interface, always gives "ExampleLabel".
 *  @return "ExampleLabel"
 */
  public String getName() {
    return "ExampleLabel";
  }
}
