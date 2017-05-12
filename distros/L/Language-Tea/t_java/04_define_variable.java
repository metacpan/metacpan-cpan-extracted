//package pt.v1.tea.testapp;

class MainProgram {

    public static void main(String[] args) {
        try {
            Integer myvar = ((new Integer(1) + new Integer(1)));
        } catch(Exception e) {
            System.out.println(e.getMessage());
        }
    }

}
