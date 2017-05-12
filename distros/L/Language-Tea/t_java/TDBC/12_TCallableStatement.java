//package pt.v1.tea.testapp;

class MainProgram {

    public static void main(String[] args) {
        try {
            Connection a = (TDBC.tdbcConstructor("uma.base.de.dados", "user", "pass"));
            CallableStatement b = (a.prepareCall("ola"));
            TeaUnkownType c;
            TeaUnkownType d;
            TeaUnkownType e;
            TeaUnkownType f;
            b.registerOutParameter(new Integer(1), Types.DATE);
            b.registerOutParameter(new Integer(2), Types.INTEGER);
            b.registerOutParameter(new Integer(3), Types.DOUBLE);
            b.registerOutParameter(new Integer(4), Types.VARCHAR);
            Date c = b.getDate(new Integer(1));
            Integer d = b.getInt(new Integer(2));
            Double e = b.getDouble(new Integer(3));
            String f = b.getString(new Integer(4));
        } catch(Exception e) {
            System.out.println(e.getMessage());
        }
    }

}
