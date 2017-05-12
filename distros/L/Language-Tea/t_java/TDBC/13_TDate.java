//package pt.v1.tea.testapp;

class MainProgram {

    public static void main(String[] args) {
        try {
            java.util.Date a = (TDBC.tdbcDateConstructor(new Integer(2008), new Integer(11), new Integer(3), new Integer(12), new Integer(43), new Integer(55)));
            java.util.Date b = (TDBC.tdbcDateConstructor());
            Boolean m = (b.after(a));
            System.out.println("b e depois de a?? " + m);
            Boolean n = (b.before(a));
            System.out.println("ou sera antes? " + n);
            Integer o = (TDBC.tdbcCompareDates(b, a));
            System.out.println("comparacao" + o);
            String c = ((new SimpleDateFormat("yyyy.MM.dd G 'at' HH:mm:ss z")).format(b));
            System.out.println("b tem esta data " + c);
            Integer d = (b.getDate());
            System.out.println("dia " + d);
            Integer e = (b.getDay());
            System.out.println("dia da semana " + e);
            Integer f = (b.getHours());
            System.out.println("hora " + f);
            Integer g = (b.getMinutes());
            System.out.println("minuto " + g);
            Integer h = (b.getSeconds());
            System.out.println("segundo " + h);
            Integer i = (TDBC.tdbcGetMonth(b));
            System.out.println("mes " + i);
            Integer j = (TDBC.tdbcGetYear(b));
            System.out.println("ano " + j);
            Boolean k = (!b.equals(a));
            System.out.println("sera k b n e igual a a " + k);
            Boolean l = (b.equals(b));
            System.out.println("b sera igual a b " + l);
            TDBC.tdbcSetDate(b, new Integer(2007), new Integer(9), new Integer(7));
            System.out.println("b tem esta data " + ((new SimpleDateFormat("yyyy.MM.dd G 'at' HH:mm:ss z")).format(b)));
            TDBC.tdbcSetTime(b, new Integer(11), new Integer(0), new Integer(0));
            System.out.println("b tem esta data " + ((new SimpleDateFormat("yyyy.MM.dd G 'at' HH:mm:ss z")).format(b)));
        } catch(Exception e) {
            System.out.println(e.getMessage());
        }
    }

}
