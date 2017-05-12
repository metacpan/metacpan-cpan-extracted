//package pt.v1.tea.testapp;

class MainProgram {

    public static void main(String[] args) {
        try {
            String a = "Ola pessoal";
            String b = "Ala pessoali";
            System.out.println((Str.strLessOrEqual(a, b)));
        } catch(Exception e) {
            System.out.println(e.getMessage());
        }
    }

}
