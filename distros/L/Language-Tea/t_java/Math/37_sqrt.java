//package pt.v1.tea.testapp;

class MainProgram {

    public static void main(String[] args) {
        try {
            Math.sqrt(new Integer(9));
        } catch(Exception e) {
            System.out.println(e.getMessage());
        }
    }

}
