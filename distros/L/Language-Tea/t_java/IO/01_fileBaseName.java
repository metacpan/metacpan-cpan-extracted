//package pt.v1.tea.testapp;

class MainProgram {

    public static void main(String[] args) {
        try {
            String e = "t_tea/IO/fileBaseName.tea";
            System.out.println((IO.fileBaseName(e)));
            System.out.println((IO.fileBaseName("t_tea/IO/fileBaseName.tea")));
        } catch(Exception e) {
            System.out.println(e.getMessage());
        }
    }

}
