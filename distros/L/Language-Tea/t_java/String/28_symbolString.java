//package pt.v1.tea.testapp;

class MainProgram {

    public static void main(String[] args) {
        try {
            String abcd = "asdadsa";
            System.out.println((new String(abcd)));
        } catch(Exception e) {
            System.out.println(e.getMessage());
        }
    }

}
