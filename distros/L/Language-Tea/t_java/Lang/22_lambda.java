//package pt.v1.tea.testapp;

class MainProgram {

    public static void main(String[] args) {
        try {
            TeaUnknownType rect4 = (areaRectangulo(new Integer(4)));
            TeaUnknownType rect6 = (areaRectangulo(new Integer(6)));
            System.out.println(("\nE agora um bocadinho de de closures:\n A area do rectangulo com um comprimento de 4 e largura de 6 " + ((rect4(new Integer(6))).toString())));
            System.out.println(("\nE agora um bocadinho de de closures:\n A area do rectangulo com um comprimento de 6 e largura de 6 " + ((rect6(new Integer(6))).toString())));
        } catch(Exception e) {
            System.out.println(e.getMessage());
        }
    }



    public static TeaUnknownType areaRectangulo(comprimento) {
        return lambda((largura), {
                          return (comprimento * largura);
                      }
                     );
    }
}
