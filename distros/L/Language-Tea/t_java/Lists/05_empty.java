//package pt.v1.tea.testapp;

class MainProgram {

    public static void main(String[] args) {
        try {
            Vector a = new Vector();
            a.add(new Integer(1));
            System.out.println((a.isEmpty()));
        } catch(Exception e) {
            System.out.println(e.getMessage());
        }
    }

}
