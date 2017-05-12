//package pt.v1.tea.testapp;

class MainProgram {

    public static void main(String[] args) {
        try {
            //  argv e uma lista q contem todos os parametros
            //  passados na linha de comandos
            //  verificar se a lista esta vazia ou nao
            if ((return !argv.isEmpty())) {
                //  converter o primeiro parametro para 'inteiro'
                Integer numero = (new Integer((argv.get(new Integer(0)))));
                if ((numero < new Integer(0))) {
                    System.out.println("menor q zero");
                    System.out.println(" e tall");
                    System.out.println("RMELOSOSAOADSODAIDOSAID");
                } else if ((numero > new Integer(0))) {
                    System.out.println("maior q zero");
                } else {
                    // default  ( funciona como o 'default:' no switch em 'c/c++' )
                    System.out.println("zero");
                }
                //  para o caso da lista estar vazia
            } else {
                System.out.println("Quero pelo menos um parametro!");
            }
        } catch(Exception e) {
            System.out.println(e.getMessage());
        }
    }

}
