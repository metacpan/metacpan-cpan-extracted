//package pt.v1.tea.testapp;

class MainProgram {

    public static void main(String[] args) {
        try {
            Vector a = new Vector();
            a.add(new Integer(1));
            a.add(new Integer(2));
            a.add(new Integer(3));
            System.out.println((a.size()));
            Vector b = ((Vector)a.clone();VAR.add(0, (new Integer(0))););
            System.out.println(((b.get(new Integer(0))).get(0)));
            System.out.println((b.size()));
        } catch(Exception e) {
            System.out.println(e.getMessage());
        }
    }

}
