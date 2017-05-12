//package pt.v1.tea.testapp;

class MainProgram {

    public static void main(String[] args) {
        try {
            // Refactored from a rvalue if condition
            // at t_tea/15_recursive_if_refactor.tea line 1
            TeaUnkownType refactoring_variable_0;
            // Refactored from a multi-statements if condition
            // at t_tea/15_recursive_if_refactor.tea line 1
            Boolean refactoring_variable_1;
            {
                System.out.println("if1");
                refactoring_variable_1 = (System.out.println("if1"));
            }
            if (refactoring_variable_1) {
                // Refactored from a rvalue if condition
                // at t_tea/15_recursive_if_refactor.tea line 1
                TeaUnkownType refactoring_variable_2;
                // Refactored from a multi-statements if condition
                // at t_tea/15_recursive_if_refactor.tea line 1
                Boolean refactoring_variable_3;
                {
                    System.out.println("if2");
                    refactoring_variable_3 = (System.out.println("if2"));
                }
                if (refactoring_variable_3) {
                    System.out.println("then2");
                    return refactoring_variable_2 = (System.out.println("then2"));
                } else {
                    System.out.println("else2");
                    return refactoring_variable_2 = (System.out.println("else2"));
                }
                return refactoring_variable_0 = (refactoring_variable_2);
            } else {
                System.out.println("else 1");
                return refactoring_variable_0 = (System.out.println("else 1"));
            }
            System.out.println((refactoring_variable_0));
        } catch(Exception e) {
            System.out.println(e.getMessage());
        }
    }

}
