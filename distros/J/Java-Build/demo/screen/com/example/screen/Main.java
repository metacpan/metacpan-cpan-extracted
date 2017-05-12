package com.example.screen;
import com.example.common.*;
import java.io.BufferedReader;
import java.io.FileReader;
import java.awt.Container;
import java.awt.Point;
import java.awt.event.WindowAdapter;
import java.awt.event.WindowEvent;
import java.util.StringTokenizer;
import javax.swing.JFrame;

public class Main extends JFrame {

    public Main(String file, boolean pixels) throws Exception {
        Container      pane = getContentPane();

        if (pixels) { pane.setLayout(new PixelLayout());     }
        else        { pane.setLayout(new CharacterLayout()); }

        FileReader     fr   = new FileReader(file);
        BufferedReader br   = new BufferedReader(fr);
        String         line;

        while ((line = br.readLine()) != null) {
            StringTokenizer st   = new StringTokenizer(line, " ");
            String          xstr = st.nextToken();
            String          ystr = st.nextToken();
            int             x    = new Integer(xstr).intValue();
            int             y    = new Integer(ystr).intValue();
            String          text = line.substring(
                xstr.length() + ystr.length() + 2
            );
            ExampleLabel    lab  = new ExampleLabel(text);
            pane.add(lab, new Point(x, y));
        }

        br.close();
        fr.close();

        pack();
        show();

        addWindowListener(new closer());
    }

    private class closer extends WindowAdapter {
        public void windowClosing(WindowEvent we) {
            System.exit(0);
        }
    }

    public static void main(String[] args) throws Exception {
        Main m;
        if (args[0].startsWith("p")) { m = new Main(args[0], true);  }
        else                         { m = new Main(args[0], false); }
    }
}
