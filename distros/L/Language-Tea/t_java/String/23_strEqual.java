//package pt.v1.tea.testapp;

class MainProgram {

    public static void main(String[] args) {
        try {
            String a = "Ola pessoal";
            String b = "Ola pessoal";
            System.out.println((Str.strEqual(a, b)));
        } catch(Exception e) {
            System.out.println(e.getMessage());
        }
    }

}
