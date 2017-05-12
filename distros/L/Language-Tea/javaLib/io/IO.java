package javaLib.io;

import java.io.InputStream;
import java.io.File;
import java.io.FilenameFilter;
import java.io.FileReader;
import java.io.FileWriter;
import java.io.IOException;
import java.util.regex.*;

public class IO implements FilenameFilter{
    // Stuff related with FilenameFilter implementation
    // needed to convert tea.io.glob function
    private String pattern;

    public IO() {
    	pattern = "";
    }

    public IO(String pat) {
        this.pattern = pat;
    }

    // FilenameFilter implementation
    public boolean accept (File dir, String name) {
        // Create a pattern to match
        Pattern p = Pattern.compile(pattern);
        // Create a matcher with name
        Matcher m = p.matcher(name);
        return m.find();
    }

    // Translaction of tea.io.glob function
    public static String[] glob(String directory, String name) {
        IO filter = new IO(name);
        File dir = new File(directory);
        return dir.list(filter);
    }
                     // END OF TEA.IO.GLOB Translaction

    public static String fileBaseName(String fileName) {
        try{
            for(int i = fileName.length() - 1; i >= 0; i--) {
                if (fileName.charAt(i) == '/')
                    return fileName.substring(i+1);
            }
        }catch(IndexOutOfBoundsException e){
            System.out.println(e.getMessage());    
        }
        return fileName;
    }

    public static Boolean fileCopy(String source, String dest) {
        try{
            FileReader in = new FileReader(new File(source));
            FileWriter out = new FileWriter(new File(dest));
            int c;

            while ((c = in.read()) != -1)
                out.write(c);

            in.close();
            out.close();
        } catch (Exception e) {
            System.out.println(e.getMessage());
            return new Boolean(false);
        }
        return new Boolean(true);
    }

    public static String fileDirName(String fileName) {
        try{
            for(int i = fileName.length() - 1; i >= 0; i--) {
                if (fileName.charAt(i) == '/')
                    return fileName.substring(0, i-1);
            }
            return "/";
        }catch(IndexOutOfBoundsException e){
            System.out.println(e.getMessage());    
        }
        return null;
    }

    public static String fileExtension(String fileName) {
        try{
            for(int i = fileName.length() - 1; i >= 0; i--) {
                if (fileName.charAt(i) == '.')
                    return fileName.substring(i+1);
            }
        }catch(IndexOutOfBoundsException e){
            System.out.println(e.getMessage());    
        }
        return "";
    }

    public static String fileJoin(String[] filePaths) {
        String result = filePaths[0];
        for (int i=1; i < filePaths.length; ++i)
            result += File.separator + filePaths[i];
        return result;
    }

    public static boolean fileUnlinkRecursive(File dir) {
        if (dir.isDirectory()) {
            String[] children = dir.list();
            for (int i=0; i<children.length; i++) {
                boolean success = (new File(dir, children[i])).delete();
                if (!success) {
                    return false;
                }
            }
        }
        // The directory is now empty so now it can be smoked
        return dir.delete();
    }

}
