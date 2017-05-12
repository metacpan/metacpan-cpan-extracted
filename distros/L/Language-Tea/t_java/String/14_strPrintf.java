//package pt.v1.tea.testapp;

class MainProgram {

    public static void main(String[] args) {
        try {
            String b = "soal";
            Integer c = new Integer(12);
            System.out.println((String.format("ola %s, %d", b, c)));
        } catch(Exception e) {
            System.out.println(e.getMessage());
        }
    }

}
