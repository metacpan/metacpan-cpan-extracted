//package pt.v1.tea.testapp;

class MainProgram {

    public static void main(String[] args) {
        try {
            (new File("testiiiii")).mkdirs();
        } catch(Exception e) {
            System.out.println(e.getMessage());
        }
    }

}
