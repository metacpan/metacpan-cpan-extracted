//package pt.v1.tea.testapp;

class MainProgram {

    public static void main(String[] args) {
        try {
            (new Integer(9) / new Integer(3));
        } catch(Exception e) {
            System.out.println(e.getMessage());
        }
    }

}
