//package pt.v1.tea.testapp;

class MainProgram {

    public static void main(String[] args) {
        try {
            Triangulo tri1 = (new Triangulo(new Integer(2), new Integer(2)));
            System.out.println("\nTeste de uma classe:\nUm triangulo com 2 de base e 2 de altura tem " + (tri1.getArea()) + " de area");
            Class e = (Triangulo.getClass().getSuperclass());
            e obj = (new e());
            System.out.println((obj.test()));
        } catch(Exception e) {
            System.out.println(e.getMessage());
        }
    }

}
public class Triangulo extends teste {
    private unknownType _altura;
    private unknownType _base;

//###########################################################################
//########################### END OF PRIVATE MEMBERS ########################
//###########################################################################

    public TeaUnknownType getArea() {
        return (((_altura * _base)) / new Integer(2));
    }

    public Triangulo(a, b) {
        _altura = a;
        _base = b;
    }

    public void setDimensoes(a, b) {
        _altura = a;
        _base = b;
    }

}
public class teste {

//###########################################################################
//########################### END OF PRIVATE MEMBERS ########################
//###########################################################################

    public void test() {
        return System.out.println("tou dentro do metodo");
    }

}
