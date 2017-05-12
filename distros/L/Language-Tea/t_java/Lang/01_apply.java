//package pt.v1.tea.testapp;

class MainProgram {

    public static void main(String[] args) {
        try {
            Integer a = new Integer(2);
            square(a);
        } catch(Exception e) {
            System.out.println(e.getMessage());
        }
    }



    public static void square(x) {
        return System.out.println(((x * x)));
    }
}
