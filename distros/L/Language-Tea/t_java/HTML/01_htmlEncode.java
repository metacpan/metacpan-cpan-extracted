//package pt.v1.tea.testapp;

class MainProgram {

    public static void main(String[] args) {
        try {
            String a = "<p>YOOOOHHHH<p>";
            System.out.println(((new java.net.URLEncoder()).encode(a)));
        } catch(Exception e) {
            System.out.println(e.getMessage());
        }
    }

}
