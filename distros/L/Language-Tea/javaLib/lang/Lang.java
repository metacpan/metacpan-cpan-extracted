package javaLib.lang;

import java.io.InputStream;
import java.io.IOException;


public class Lang implements IMappable{

    public Lang(){
    }

    public static void system(String string) {
        InputStream pipedOut = null;
        try {
            Process aProcess = Runtime.getRuntime().exec(string);
            aProcess.waitFor();

            pipedOut = aProcess.getInputStream();
            byte buffer[] = new byte[2048];
            int read = pipedOut.read(buffer);
            // Replace following code with your intends processing tools
            while(read >= 0) {
                System.out.write(buffer, 0, read);
                
                read = pipedOut.read(buffer);
            }
        } catch (IOException e) {
            e.printStackTrace();
        } catch (InterruptedException ie) {
            ie.printStackTrace();
        } finally {
            if(pipedOut != null) {
                try {
                    pipedOut.close();
                } catch (IOException e) {
                }
            }
        }
    }
    

    public static void error(String message) {
        System.out.println("\n\nProblems: " + message + "\n\n");
        System.exit(1);
    }

}
