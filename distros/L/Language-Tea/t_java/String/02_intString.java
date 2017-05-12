//package pt.v1.tea.testapp;

class MainProgram {

    public static void main(String[] args) {
        try {
            Integer a = new Integer(12);
            System.out.println(a);
            String b = (a.toString());
            System.out.println(b);
        } catch(Exception e) {
            System.out.println(e.getMessage());
        }
    }

}
