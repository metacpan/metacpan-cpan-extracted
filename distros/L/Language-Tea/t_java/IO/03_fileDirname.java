//package pt.v1.tea.testapp;

class MainProgram {

    public static void main(String[] args) {
        try {
            System.out.println((IO.fileDirName("/BEATCH.tea")));
        } catch(Exception e) {
            System.out.println(e.getMessage());
        }
    }

}
