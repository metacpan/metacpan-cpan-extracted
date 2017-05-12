//package pt.v1.tea.testapp;

class MainProgram {

    public static void main(String[] args) {
        try {
            String a = "OLB";
            String b = "OLA";
            System.out.println((Str.strCmp(a, b)));
        } catch(Exception e) {
            System.out.println(e.getMessage());
        }
    }

}
