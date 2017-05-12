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
        } catch(Exception e) {
            System.out.println(e.getMessage());
        }
    }

}
