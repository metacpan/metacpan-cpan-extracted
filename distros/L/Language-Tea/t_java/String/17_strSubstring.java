//package pt.v1.tea.testapp;

class MainProgram {

    public static void main(String[] args) {
        try {
            String b = "soal";
            String c = "o";
            System.out.println((b.substring(new Integer(1), new Integer(2))));
        } catch(Exception e) {
            System.out.println(e.getMessage());
        }
    }

}
