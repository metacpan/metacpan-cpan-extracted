//package pt.v1.tea.testapp;

class MainProgram {

    public static void main(String[] args) {
        try {
for (TeaUnknownType fileName : (IO.glob(".", ".*"))) {
                System.out.println(fileName);
            }
        } catch(Exception e) {
            System.out.println(e.getMessage());
        }
    }

}
