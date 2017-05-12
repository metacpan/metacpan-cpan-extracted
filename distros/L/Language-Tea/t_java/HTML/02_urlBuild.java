//package pt.v1.tea.testapp;

class MainProgram {

    public static void main(String[] args) {
        try {
            String a = "chave";
            String v = "valor";
            System.out.println((new String("www.google.com"+ "?" + a + "=" + v)));
        } catch(Exception e) {
            System.out.println(e.getMessage());
        }
    }

}
