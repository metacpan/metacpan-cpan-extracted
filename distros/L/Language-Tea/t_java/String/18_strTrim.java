//package pt.v1.tea.testapp;

class MainProgram {

    public static void main(String[] args) {
        try {
            String b = "     soal\nasdasdasda             \n asdas            ";
            String c = "o";
            System.out.println((b.trim()));
        } catch(Exception e) {
            System.out.println(e.getMessage());
        }
    }

}
