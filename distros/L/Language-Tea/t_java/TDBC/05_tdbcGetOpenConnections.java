//package pt.v1.tea.testapp;

class MainProgram {

    public static void main(String[] args) {
        try {
            TDBC.tdbcSetDefault("XOTAs", "cromo", "abcs");
            System.out.println((TDBC.tdbcGetOpenConnectionsCount()));
        } catch(Exception e) {
            System.out.println(e.getMessage());
        }
    }

}
