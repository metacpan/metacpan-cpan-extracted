package javaLib.util;

import java.util.Hashtable;
import java.util.ArrayList;
import java.util.Enumeration;

import java.util.Vector;

public class Util{

    public static ArrayList getElements(Hashtable hash){
        ArrayList arr = new ArrayList();
        for (Enumeration e = hash.elements() ; e.hasMoreElements() ;) 
            arr.add(e.nextElement());
        return arr;
    }
    
    public static ArrayList getKeys(Hashtable hash){
        ArrayList arr = new ArrayList();
        for (Enumeration e = hash.keys() ; e.hasMoreElements() ;) 
            arr.add(e.nextElement());
        return arr;
    }

    public static void append(Vector vec, Object[] obj) {
        for (Object i : obj) 
            vec.add(i);
    }
 
    public static Vector getElements(Vector vec){
        return vec;
    }
    
    public static Vector init(Vector vec, Object[] obj){
        vec.clear();
        for (Object o : obj)
            vec.add(o);
        return vec;
    }
 
    
    public static Object pop(Vector vec){
        Object o = vec.lastElement();
        vec.remove(vec.size()-1);
        return o;
    }
}
