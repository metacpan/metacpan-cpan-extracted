//package pt.v1.tea.testapp;

class MainProgram {

    public static void main(String[] args) {
        try {
            String a = "teste";
            String b = "";
            System.out.println((a.equals("")));
            System.out.println((b.equals("")));
        } catch(Exception e) {
            System.out.println(e.getMessage());
        }
    }

}
