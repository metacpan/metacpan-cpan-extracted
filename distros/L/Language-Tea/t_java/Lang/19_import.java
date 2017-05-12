//package pt.v1.tea.testapp;

class MainProgram {

    public static void main(String[] args) {
        try {
            import("18_if.tea");
        } catch(Exception e) {
            System.out.println(e.getMessage());
        }
    }

}
