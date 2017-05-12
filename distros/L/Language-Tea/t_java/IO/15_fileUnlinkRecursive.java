//package pt.v1.tea.testapp;

class MainProgram {

    public static void main(String[] args) {
        try {
            IO.fileUnlinkRecursive(new File("teste"));
        } catch(Exception e) {
            System.out.println(e.getMessage());
        }
    }

}
