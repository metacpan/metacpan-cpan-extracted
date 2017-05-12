//package pt.v1.tea.testapp;

class MainProgram {

    public static void main(String[] args) {
        try {
            String a = "eu sou muita mau";
            Pattern b = (Pattern.compile(".*sou.*"));
            String c = ".*sou.*";
            System.out.println((Regexp.matches(".*sou.*",a)));
            System.out.println((Regexp.matches(c,a)));
        } catch(Exception e) {
            System.out.println(e.getMessage());
        }
    }

}
