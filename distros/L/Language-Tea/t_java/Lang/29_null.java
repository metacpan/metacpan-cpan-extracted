//package pt.v1.tea.testapp;

class MainProgram {

    public static void main(String[] args) {
        try {
            TeaUnkownType a;
            System.out.println((a != null));
            System.out.println((a == null));
        } catch(Exception e) {
            System.out.println(e.getMessage());
        }
    }

}
