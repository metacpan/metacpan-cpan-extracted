//package pt.v1.tea.testapp;

class MainProgram {

    public static void main(String[] args) {
        try {
            Integer a = new Integer(2);
            // echo [apply square $a]
            square(a);
        } catch(Exception e) {
            System.out.println(e.getMessage());
        }
    }



    public static TeaUnknownType square(x) {
        System.out.println(((x * x)));
        return return ;
    }
}
