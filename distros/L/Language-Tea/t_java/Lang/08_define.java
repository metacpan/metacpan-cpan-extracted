//package pt.v1.tea.testapp;

class MainProgram {

    public static void main(String[] args) {
        try {
            Double pi = new Double(3.141516);
        } catch(Exception e) {
            System.out.println(e.getMessage());
        }
    }



    public static TeaUnknownType square(x) {
        return (x * x);
    }


    public static TeaUnknownType lineEcho(argList) {
for (TeaUnknownType arg : argList) {
            System.out.println(arg);
        }
    }
}
