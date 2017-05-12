//package pt.v1.tea.testapp;

class MainProgram {

    public static void main(String[] args) {
        try {
            TeaUnkownType a;
            a = new Integer(1);
            System.out.println(a);
        } catch(Exception e) {
            System.out.println(e.getMessage());
        }
    }

}
