//package pt.v1.tea.testapp;

class MainProgram {

    public static void main(String[] args) {
        try {
            Double a = new Double(12.44);
            System.out.println(a);
            String b = (a.toString());
            System.out.println(b);
        } catch(Exception e) {
            System.out.println(e.getMessage());
        }
    }

}
