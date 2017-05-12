//package pt.v1.tea.testapp;

class MainProgram {

    public static void main(String[] args) {
        try {
            Connection a = (TDBC.tdbcConstructor("uma.base.de.dados", "user", "pass"));
            a.commit();
            TDBC.tdbcConnect(a,"AH ETAL");
            PreparedStatement b1 = (a.prepareStatement("ola"));
            CallableStatement b2 = (a.prepareCall("ola"));
            a.rollback();
            a.setAutoCommit(true);
            Statement stat = (a.createStatement());
            Boolean a1 = (stat.execute("select * from xotas"));
            Integer a2 = (stat.getFetchSize());
            Boolean a3 = (stat.getMoreResults());
            ResultSet a4 = (stat.getResultSet());
            stat.setFetchSize(new Integer(3));
            Integer a6 = (stat.executeUpdate("ah e tal update * coiso"));
            ResultSet rSet = (stat.executeQuery("Select * from xotas"));
            while (rSet.next()) {
                System.out.println((rSet.getString(new Integer(1))));
            }
            rSet.close();
            stat.close();
            a.close();
        } catch(Exception e) {
            System.out.println(e.getMessage());
        }
    }

}
