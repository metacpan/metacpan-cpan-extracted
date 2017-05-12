//package pt.v1.tea.testapp;

class MainProgram {

    public static void main(String[] args) {
        try {
            Vector a = new Vector();
            a.add(new Integer(1));
            a.add(new Integer(2));
            a.add(new Integer(3));
            System.out.println("primeiro " + (a.size()));
            TeaUnknownType b = (a.get(a.size() - 1));
            System.out.println("length " + (b.size()));
for (TeaUnknownType o : b) {
                System.out.println("foreach " + o);
            }
            System.out.println((a.size()));
        } catch(Exception e) {
            System.out.println(e.getMessage());
        }
    }

}
