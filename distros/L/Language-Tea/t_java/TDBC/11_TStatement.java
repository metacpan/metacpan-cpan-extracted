//package pt.v1.tea.testapp;

class MainProgram {

    public static void main(String[] args) {
        try {
            Connection a = (TDBC.tdbcConstructor("uma.base.de.dados", "user", "pass"));
            Statement b = (a.createStatement());
            Boolean c = (b.execute("select * fromo qq coisa"));
            Integer d = (b.getFetchSize());
            Boolean e = (b.getMoreResults());
            ResultSet f = (b.getResultSet());
            ResultSet g = (b.executeQuery("select * from xotas"));
            b.setFetchSize(new Integer(12));
            Integer i = (b.executeUpdate("update * "));
            b.close();
        } catch(Exception e) {
            System.out.println(e.getMessage());
        }
    }

}
