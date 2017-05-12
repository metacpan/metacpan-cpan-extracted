//package pt.v1.tea.testapp;

class MainProgram {

    public static void main(String[] args) {
        try {
            if (((TDBC.tdbcCloseAllConnections()) != null)) {
                System.out.println((TDBC.tdbcCloseAllConnections()));
            }
        } catch(Exception e) {
            System.out.println(e.getMessage());
        }
    }

}
