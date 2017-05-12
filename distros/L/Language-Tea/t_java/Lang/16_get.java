//package pt.v1.tea.testapp;

class MainProgram {

    public static void main(String[] args) {
        try {
            Double a = new Double(123.3);
            String b = "ah e tal";
            System.out.println((a));
            System.out.println((b));
        } catch(Exception e) {
            System.out.println(e.getMessage());
        }
    }

}
