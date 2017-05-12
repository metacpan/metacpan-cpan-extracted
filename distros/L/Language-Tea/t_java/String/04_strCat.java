//package pt.v1.tea.testapp;

class MainProgram {

    public static void main(String[] args) {
        try {
            String a = "SUKAS";
            String b = (a + " muito");
            System.out.println(b);
        } catch(Exception e) {
            System.out.println(e.getMessage());
        }
    }

}
