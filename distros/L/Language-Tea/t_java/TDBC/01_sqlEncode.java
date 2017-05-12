//package pt.v1.tea.testapp;

class MainProgram {

    public static void main(String[] args) {
        try {
            String a = "select * from tabela where tabela.campo = 'ah e tal'";
            String b = (a);
            System.out.println(b);
        } catch(Exception e) {
            System.out.println(e.getMessage());
        }
    }

}
