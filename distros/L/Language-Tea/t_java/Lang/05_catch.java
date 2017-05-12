//package pt.v1.tea.testapp;

class MainProgram {

    public static void main(String[] args) {
        try {
            TeaUnkownType a;
            TeaUnkownType b;
            TeaUnkownType c;
            try {
                return c = ((new Integer(1) + new Integer(2)));
            } catch(Exception e) {
                a = e.getMessage();
                b = e.getStackTrace().toString();
            };
        } catch(Exception e) {
            System.out.println(e.getMessage());
        }
    }

}
