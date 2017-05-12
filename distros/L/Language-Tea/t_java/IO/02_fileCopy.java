//package pt.v1.tea.testapp;

class MainProgram {

    public static void main(String[] args) {
        try {
            IO.fileCopy("02_fileCopy.tea", "teste.tea");
        } catch(Exception e) {
            System.out.println(e.getMessage());
        }
    }

}
