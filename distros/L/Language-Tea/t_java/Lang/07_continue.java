//package pt.v1.tea.testapp;

class MainProgram {

    public static void main(String[] args) {
        try {
            while (((new Integer(1) < new Integer(2)))) {
                continue;
                System.out.println("tou ca dentro");
            }
        } catch(Exception e) {
            System.out.println(e.getMessage());
        }
    }

}
