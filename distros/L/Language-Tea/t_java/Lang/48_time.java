//package pt.v1.tea.testapp;

class MainProgram {

    public static void main(String[] args) {
        try {
            for (int i = 0; i < new Integer(4); ++i) {
                return System.out.println("ola");
            }
            ;
        } catch(Exception e) {
            System.out.println(e.getMessage());
        }
    }

}
