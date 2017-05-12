//package pt.v1.tea.testapp;

class MainProgram {

    public static void main(String[] args) {
        try {
            if (((new Integer(1) > new Integer(2)))) {
                System.out.println("ola");
                System.out.println("tonho");
            } else {
                System.out.println("botarde");
                System.out.println("xico");
            }
        } catch(Exception e) {
            System.out.println(e.getMessage());
        }
    }

}
