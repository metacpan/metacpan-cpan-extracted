//package pt.v1.tea.testapp;

class MainProgram {

    public static void main(String[] args) {
        try {
            Integer a = new Integer(2);
            Integer b = a;
            System.out.println((a == b));
            a = new Integer(33);
            System.out.println((a == b));
        } catch(Exception e) {
            System.out.println(e.getMessage());
        }
    }

}
