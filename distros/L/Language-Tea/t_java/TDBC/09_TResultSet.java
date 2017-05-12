//package pt.v1.tea.testapp;

class MainProgram {

    public static void main(String[] args) {
        try {
            Connection a = (TDBC.tdbcConstructor("uma.base.de.dados", "user", "pass"));
            Statement stat = (a.createStatement());
            ResultSet rSet = (stat.executeQuery("Select * from xotas"));
            Integer a1 = (rSet.getMetaData().getColumnCount());
            String a2 = (rSet.getMetaData().getColumnName(new Integer(1)));
            java_46_sql_46_Date a3 = (rSet.getDate("OLA"));
            Double a4 = ((double)rSet.getFloat(new Integer(4)));
            Integer a5 = (rSet.getInt(new Integer(3)));
            String a6 = (rSet.getString("IO"));
            Boolean a7 = (rSet.isLast());
            Boolean a8 = (TDBC.tdbcHasRows(rSet));
            Boolean a9 = (rSet.relative(new Integer(8)));
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
