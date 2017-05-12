//package pt.v1.tea.testapp;

class MainProgram {

    public static void main(String[] args) {
        try {
            BufferedWriter out = (new BufferedWriter (new FileWriter("file.txt", ((new Integer(1) < new Integer(2))))));
            out.write("ailo");
            out.newLine();
            out.write("Yellow");
            out.newLine();
            out.close();
        } catch(Exception e) {
            System.out.println(e.getMessage());
        }
    }

}
