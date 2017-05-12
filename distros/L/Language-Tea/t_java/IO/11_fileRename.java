//package pt.v1.tea.testapp;

class MainProgram {

    public static void main(String[] args) {
        try {
            (new File("teste.txt")).renameTo(new File("testiiii.txt"));
        } catch(Exception e) {
            System.out.println(e.getMessage());
        }
    }

}
