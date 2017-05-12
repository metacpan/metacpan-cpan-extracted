//package pt.v1.tea.testapp;

class MainProgram {

    public static void main(String[] args) {
        try {
            // Refactored from a multi-statements if condition
            // at t_tea/03_if_longcode_code line 1
            Boolean refactoring_variable_0;
            {
                System.out.println("inside if");   //  comentario
                refactoring_variable_0 = (true);
            }
            if (refactoring_variable_0) {
                System.out.println("ok");
            }
        } catch(Exception e) {
            System.out.println(e.getMessage());
        }
    }

}
