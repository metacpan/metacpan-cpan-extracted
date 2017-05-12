//package pt.v1.tea.testapp;

class MainProgram {

    public static void main(String[] args) {
        try {
            Math.ceil(new Double(29.3));
        } catch(Exception e) {
            System.out.println(e.getMessage());
        }
    }

}
