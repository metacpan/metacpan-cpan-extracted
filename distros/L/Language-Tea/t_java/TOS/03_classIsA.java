//package pt.v1.tea.testapp;

class MainProgram {

    public static void main(String[] args) {
        try {
            System.out.println((Triangulo instanceof teste));
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
        return System.out.println("olaaaaaa");
    }

}
