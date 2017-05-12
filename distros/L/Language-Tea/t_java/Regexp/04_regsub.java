//package pt.v1.tea.testapp;

class MainProgram {

    public static void main(String[] args) {
        try {
            String a = "ola pessoal... td em cima?";
            System.out.println((Regexp.regsub(" ( .* )  ( em cima )  ( . ) ", "$1bom$3", a)));
        } catch(Exception e) {
            System.out.println(e.getMessage());
        }
    }

}
