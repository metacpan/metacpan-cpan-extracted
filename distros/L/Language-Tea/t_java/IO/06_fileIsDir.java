//package pt.v1.tea.testapp;

class MainProgram {

    public static void main(String[] args) {
        try {
            System.out.println(((new File("../IO")).isDirectory()));
        } catch(Exception e) {
            System.out.println(e.getMessage());
        }
    }

}
