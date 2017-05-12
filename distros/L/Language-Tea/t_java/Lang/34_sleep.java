//package pt.v1.tea.testapp;

class MainProgram {

    public static void main(String[] args) {
        try {
            try {
                Thread.sleep(new Integer(3000));
            } catch(Exception e) {
                System.out.println(e.getMessage());
            };
            System.out.println("ah e tal");
        } catch(Exception e) {
            System.out.println(e.getMessage());
        }
    }

}
