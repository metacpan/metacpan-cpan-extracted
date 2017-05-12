//package pt.v1.tea.testapp;

class MainProgram {

    public static void main(String[] args) {
        try {
            Integer a = new Integer(2);
            System.out.println((a != null));
        } catch(Exception e) {
            System.out.println(e.getMessage());
        }
    }

}
