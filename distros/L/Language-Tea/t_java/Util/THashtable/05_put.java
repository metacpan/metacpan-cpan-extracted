//package pt.v1.tea.testapp;

class MainProgram {

    public static void main(String[] args) {
        try {
            java.util.Hashtable a = (new java.util.Hashtable());
            String b = "oii";
            a.put(new Integer(1), new Integer(2));
            a.put("a", new Integer(3));
            a.put(new Integer(1), new Integer(44));
            a.put(b, new Integer(11));
            System.out.println((a.get("a")));
            Integer len = ((Util.getElements(a)).size());
            System.out.println(len);
            a.put(new Integer(34), new Integer(44));
            len = ((Util.getElements(a)).size());
            System.out.println(len);
        } catch(Exception e) {
            System.out.println(e.getMessage());
        }
    }

}
