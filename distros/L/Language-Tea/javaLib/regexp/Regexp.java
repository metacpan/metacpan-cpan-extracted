package javaLib.regexp;

import java.util.regex.*;
import java.util.*;


public class Regexp{

    public Regexp(){
    }


    public static boolean matches (String pat, String phrase) {
        Pattern p = Pattern.compile(pat);
        Matcher m = p.matcher(phrase);
        return m.find();
    }
    
    public static boolean matches (Pattern p, String phrase) {
        Matcher m = p.matcher(phrase);
        return m.find();
    }
    
    
    public static List<String> regexp (Pattern p, String phrase) {
        // Create a matcher with an input string
        Matcher m = p.matcher(phrase);
        boolean result = m.find();
        List<String> matchList = new ArrayList<String>();
        while(result) {
            matchList.add(m.group());
            result = m.find();
        }  
        return matchList;
    }

    public static List<String> regexp (String pat, String phrase) {
        Pattern p = Pattern.compile(pat);
        // Create a matcher with an input string
        Matcher m = p.matcher(phrase);
        boolean result = m.find();
        List<String> matchList = new ArrayList<String>();
        while(result) {
            matchList.add(m.group());
            result = m.find();
        }  
        return matchList;
    }

    public static String regsub(String regex, String substitution, String input) {
	// Create a pattern to match cat
        Pattern p = Pattern.compile(regex);
        // Create a matcher with an input string
        Matcher m = p.matcher(input);
        StringBuffer sb = new StringBuffer();
        boolean result = m.find();
        // Loop through and create a new String 
        // with the replacements
        while(result) {
            m.appendReplacement(sb, substitution);
            result = m.find();
        }
        // Add the last segment of input to 
        // the new String
        m.appendTail(sb);
        return sb.toString();
    }


}
