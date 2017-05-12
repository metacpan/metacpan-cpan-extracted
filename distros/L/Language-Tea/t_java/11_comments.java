//package pt.v1.tea.testapp;

class MainProgram {

    public static void main(String[] args) {
        try {
            (new Integer(1) + new Integer(1));   //  this is a comment in a statement
            //  this is a comment before a statement
            (new Integer(1) + new Integer(1));
            //  this is a comment
            //  and another comment
        } catch(Exception e) {
            System.out.println(e.getMessage());
        }
    }

}
