//package pt.v1.tea.testapp;

class MainProgram {

    public static void main(String[] args) {
        try {
            String a = "At  { 0} on  { 1}, there was  { 1} on planet  { 2,number,integer}.";
            System.out.println((MessageFormat.format(a, "alaaaa", "disturbance on the force", new Integer(12))));
        } catch(Exception e) {
            System.out.println(e.getMessage());
        }
    }

}
