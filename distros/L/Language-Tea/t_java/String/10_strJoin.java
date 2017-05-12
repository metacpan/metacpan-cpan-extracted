("Ola", b, c, b)//package pt.v1.tea.testapp;

class MainProgram {

    public static void main(String[] args) {
        try {
            String a = "pessoal";
            String b = "soal";
            String c = "AHHHHHHHHHHH";
            System.out.println((Str.join(new String[] {"Ola", b, c, b}, "|")));
        } catch(Exception e) {
            System.out.println(e.getMessage());
        }
    }

}
