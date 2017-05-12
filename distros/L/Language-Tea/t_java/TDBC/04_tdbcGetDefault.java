//package pt.v1.tea.testapp;

class MainProgram {

    public static void main(String[] args) {
        try {
            // define a [tdbc-get-default]
            TDBC.tdbcSetDefault("XOTAs", "cromo", "abcs");
            List_60_String_62_ a = (TDBC.tdbcGetDefault());
            System.out.println((a.size()));
for (TeaUnknownType b : a) {
                if ((b != null)) {
                    System.out.println(b);
                }
            }
        } catch(Exception e) {
            System.out.println(e.getMessage());
        }
    }

}
