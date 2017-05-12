//package pt.v1.tea.testapp;

class MainProgram {

    public static void main(String[] args) {
        try {
            System.out.println(((new File("../../t_tea/IO/07_fileIsRegular.tea")).isFile()));
        } catch(Exception e) {
            System.out.println(e.getMessage());
        }
    }

}
