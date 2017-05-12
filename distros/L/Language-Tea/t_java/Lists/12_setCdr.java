//package pt.v1.tea.testapp;

class MainProgram {

    public static void main(String[] args) {
        try {
            Vector a = new Vector();
            a.add(new Integer(1));
            a.add(new Integer(2));
            a.add(new Integer(3));
            System.out.println(((a.get(a.size() - 1)).get(new Integer(1))));
            a.set(a.size()-1, new Integer(44));
            System.out.println((a.get(a.size() - 1)));
        } catch(Exception e) {
            System.out.println(e.getMessage());
        }
    }

}
