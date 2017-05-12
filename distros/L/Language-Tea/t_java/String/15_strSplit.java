//package pt.v1.tea.testapp;

class MainProgram {

    public static void main(String[] args) {
        try {
            String b = "soal!adasdsda!aAsadadsada!adas!";
            TeaUnkownType c;
            c = (b.split("!"));
        } catch(Exception e) {
            System.out.println(e.getMessage());
        }
    }

}
