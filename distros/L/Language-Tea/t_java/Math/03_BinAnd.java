//package pt.v1.tea.testapp;

class MainProgram {

    public static void main(String[] args) {
        try {
            System.out.println(((new Integer(2) & new Integer(3) & new Integer(1))));
        } catch(Exception e) {
            System.out.println(e.getMessage());
        }
    }

}
