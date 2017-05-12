package javaLib.string;

public class Str {

    public Str(){
    }

    public static int strCmp(String a, String b) {
        if (a.compareTo(b) > 0)
            return 1;
        if (a.compareTo(b) < 0)
            return -1;
        return 0;
    }


    public static String strJoin(String[] strings, String delimiter) {
        String aux = strings[0];
        for (int i = 1; i < strings.length; ++i)
            aux = aux + delimiter + strings[i];
        return aux;
    }


    public static Boolean strLess(String a, String b) {
        if (strCmp(a,b) < 0)
            return new Boolean(true);
        return new Boolean(false);
    }
    
    public static Boolean strLessOrEqual(String a, String b) {
        if (strCmp(a,b) <= 0)
            return new Boolean(true);
        return new Boolean(false);
    }

    public static Boolean strEqual(String a, String b) {
        if (strCmp(a,b) == 0)
            return new Boolean(true);
        return new Boolean(false);
    }
    
    public static Boolean strGreater(String a, String b) {
        if (strCmp(a,b) > 0)
            return new Boolean(true);
        return new Boolean(false);
    }

    public static Boolean strGreaterOrEqual(String a, String b) {
        if (strCmp(a,b) >= 0)
            return new Boolean(true);
        return new Boolean(false);
    }
}
