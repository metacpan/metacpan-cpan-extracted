//package pt.v1.tea.testapp;

class MainProgram {

    public static void main(String[] args) {
        try {
            BufferedReader in = (new BufferedReader (new InputStreamReader( (new URL("http://www.google.com")).openStream())));
            TeaUnkownType s = null;
            Integer i = new Integer(1);
            while ((s = (in.readLine())) != null) {
                System.out.println("Line " + i + ": " + s);
                ++i;
            }
            in.close();
        } catch(Exception e) {
            System.out.println(e.getMessage());
        }
    }

}
