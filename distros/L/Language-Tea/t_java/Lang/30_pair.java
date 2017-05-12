//package pt.v1.tea.testapp;

class MainProgram {

    public static void main(String[] args) {
        try {
            Vector a = new Vector();
            a.add(new Integer(2));
            a.add(new Integer(3));
            Integer b = new Integer(2);
            System.out.println((pair_63_(a)));
            System.out.println((pair_63_(b)));
        } catch(Exception e) {
            System.out.println(e.getMessage());
        }
    }

}
