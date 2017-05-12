//package pt.v1.tea.testapp;

class MainProgram {

    public static void main(String[] args) {
        try {
            (new Integer(1) | new Integer(2) | new Integer(3) | new Integer(4));
        } catch(Exception e) {
            System.out.println(e.getMessage());
        }
    }

}
