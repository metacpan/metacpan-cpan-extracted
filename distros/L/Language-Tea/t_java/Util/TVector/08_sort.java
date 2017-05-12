//package pt.v1.tea.testapp;

class MainProgram {

    public static void main(String[] args) {
        try {
            java.util.Vector a = (new java.util.Vector());
            Util.append(a, new Object[] {new Integer(4), new Integer(1), new Integer(32), new Integer(2)});
            System.out.println((a.get(new Integer(0))));
            System.out.println((a.get(new Integer(1))));
            System.out.println((a.get(new Integer(2))));
            System.out.println((a.get(new Integer(3))));
            System.out.println();
            Collections.sort(a, new Comparer());
            System.out.println((a.get(new Integer(0))));
            System.out.println((a.get(new Integer(1))));
            System.out.println((a.get(new Integer(2))));
            System.out.println((a.get(new Integer(3))));
        } catch(Exception e) {
            System.out.println(e.getMessage());
        }
    }



    public static void so(a, c) {
        return System.out.println(experiencia);
    }
}


class Comparer implements Comparator {
    public int compare(Integer a1, Integer  b) {
        if (((a1 > b))) {
            return _45_1;
        }
        if (((a1 < b))) {
            return new Integer(1);
        }
        return return new Integer(0);
    }
}
