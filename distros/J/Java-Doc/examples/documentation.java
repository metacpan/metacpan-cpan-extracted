/*------------------------------------------------------------------------------
Draw text to fill a fractional area of a canvas, justifying remaining space
Philip R Brenan at gmail dot com, © Appa Apps Ltd Inc on 2017.10.07 at 21:39:18
------------------------------------------------------------------------------*/
package com.appaapps;
import android.graphics.*;

public class LayoutText                                                         //C Draw text to fill a fractional area of a canvas, justifying remaining space
 {private static RectF drawArea = new RectF(), textArea = new RectF();          // Preallocated areas
  private static Path  textPath = new Path();                                   // Path of text

  public static void draw                                                       //M Draw text to fill a fractional area of a canvas, justifying remaining space
   (final Canvas canvas,                                                        //P Canvas to draw on
    final String text,                                                          //P Text to draw
    final float x,                                                              //P Area to draw text in expressed as fractions of the canvas: left   x
    final float y,                                                              //P Area to draw text in expressed as fractions of the canvas: top    y
    final float X,                                                              //P Area to draw text in expressed as fractions of the canvas: right  x
    final float Y,                                                              //P Area to draw text in expressed as fractions of the canvas: bottom y
    final int justX,                                                            //P Justification in x: -1=left,   0=center, +1=right
    final int justY,                                                            //P Justification in y: +1=bottom, 0=center, -1=top
    final Paint paintF,                                                         //P Character paint for foreground - setTextSize(128) or some other reasonable size that Android is capable of drawing text at in a hardware layer. The text will be scaled independently before it is drawn to get an optimal fit in the drawing area
    final Paint paintB                                                          //P Optional character paint for background or null. Both foreground and background text paints must have the same textSize. The foreground is painted last over the background which is painted first.
   )

   {if (paintB != null && paintF.getTextSize() != paintB.getTextSize())         // Check  the text size in each paint matches
     {say("Different text sizes in supplied paints, using foreground ",
          " size in both paints");
      paintB.setTextSize(paintF.getTextSize());                                 // Equalize the paint text sizes if different
     }

    if (true)                                                                   // Draw area dimensions
     {final float w = canvas.getWidth(), h = canvas.getHeight();                // Canvas dimensions
      drawArea.set(x*w, y*h, X*w, Y*h);                                         // Draw area
     }

    paintF.getTextPath(text, 0, text.length(), 0, 0, textPath);                 // Layout text with foreground paint
    textPath.computeBounds(textArea, true);                                     // Text bounds

    final float
      Aw = textArea.width(), Ah = textArea.height(),                            // Dimensions of text
      aw = drawArea.width(), ah = drawArea.height(),                            // Dimensions of draw area
      A  = Aw * Ah,                                                             // Area of the incoming text
      a  = aw * ah,                                                             // Area of the screen to be filled with the text
      S  = (float)Math.sqrt(a / A),                                             // The scaled factor to apply to the  text
      n  = max((float)Math.floor(ah / S / Ah), 1f),                             // The number of lines - at least one
      s  = min(ah / n / Ah, aw * n / Aw),                                       // Scale now we know the number of lines
      d  = Aw / n,                                                              // The movement along the text for each line
      dx = n == 1 ? aw - Aw * s : 0,                                            // Maximum x adjust - which only occurs if we have just one line
      dy = ah - Ah * s * n;                                                     // Maximum y adjust

//    say("AAAA ", " Aw=", Aw, " Ah=", Ah,                                      // Debug scaling
//                 " aw=", aw, " ah=", ah,
//                 " A=",  A , " a=",  a, " S=", S, " n=",  n, " s=", s,
//                 " d=", d,   " dx=", dx, " dy=", dy, " ta="+textArea);
//
    canvas.save();
    canvas.clipRect(drawArea);                                                  // Clip drawing area
    canvas.translate                                                            // Move to top left corner of drawing area
     (drawArea.left + (justX < 0 ? 0 : justX > 0 ? dx : dx / 2f)                // Distribute remaining space in x
                    - textArea.left * s,                                        // Offset in x to start of first character
      drawArea.top  + (justY < 0 ? 0 : justY > 0 ? dy : dy / 2f)                // Distribute the remaining space in y
                    - textArea.bottom * s                                       // Offset in y to start of first character
     );
    canvas.scale(s, s);                                                         // Scale
    canvas.translate(0, Ah);                                                    // Down one line

    for(int i = 0; i < n; ++i)                                                  // Draw each line
     {if (paintB != null) canvas.drawText(text, 0, 0, paintB);                  // Text background
      canvas.drawText(text, 0, 0, paintF);                                      // Text foreground
      canvas.translate(-d, Ah);                                                 // Down one line and back
     }

    canvas.restore();
   }

  private static void say(Object...O) {final StringBuilder b = new StringBuilder(); for(Object o: O) b.append(o.toString()); System.err.print(b.toString()+"\n");}
  private static float max(float a, float b) {if (a > b) return a; return b;}
  private static float min(float a, float b) {if (a < b) return a; return b;}
 } //C LayoutText
