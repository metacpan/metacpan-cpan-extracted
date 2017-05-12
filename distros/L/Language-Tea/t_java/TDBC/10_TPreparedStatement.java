//package pt.v1.tea.testapp;

class MainProgram {

    public static void main(String[] args) {
        try {
            Connection a = (TDBC.tdbcConstructor("uma.base.de.dados", "user", "pass"));
            PreparedStatement b = (a.prepareStatement("ola"));
            Boolean ff = (b.execute());
            ResultSet c = (b.executeQuery());
            TDBC.tdbcSetDate(b, new Integer(2), (TDBC.tdbcDateConstructor(new Integer(2008), new Integer(12), new Integer(22))));
            b.setFloat(new Integer(1), new Double(33.3));
            b.setInt(new Integer(4), new Integer(11));
            b.setString(new Integer(5), "OLA");
            Integer d = (b.executeUpdate());
        } catch(Exception e) {
            System.out.println(e.getMessage());
        }
    }

}
