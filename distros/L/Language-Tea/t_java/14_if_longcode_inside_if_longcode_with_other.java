//package pt.v1.tea.testapp;

class MainProgram {

    public static void main(String[] args) {
        try {
            // Refactored from a multi-statements if condition
            // at t_tea/14_if_longcode_inside_if_longcode_with_other line 1
            Boolean refactoring_variable_0;
            {
                System.out.println("if1");
                refactoring_variable_0 = (true);
            }
            if (refactoring_variable_0) {
                // Refactored from a multi-statements if condition
                // at t_tea/14_if_longcode_inside_if_longcode_with_other line 1
                Boolean refactoring_variable_1;
                {
                    System.out.println("if2");
                    refactoring_variable_1 = (true);
                }
                if (refactoring_variable_1) {
                    true;
                } else {
                    false;
                }
            } else {
                false;
            }
            System.out.println("other1");
            System.out.println("other2");
            System.out.println("other3");
            //  just to make sure the refactorer doesnt break
            //  the visit_prefix code
        } catch(Exception e) {
            System.out.println(e.getMessage());
        }
    }

}
