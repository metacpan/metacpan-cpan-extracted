// $Id: ackermann.java,v 1.5 2001/11/17 17:20:39 doug Exp $
// http://www.bagley.org/~doug/shootout/

public class Ackermann {
    public static void main(String[] args) {
	int num = 5;
	System.out.println("Ack(3," + num + "): " + Ack(3, num));
    }
    public static int Ack(int m, int n) {
	return (m == 0) ? (n + 1) : ((n == 0) ? Ack(m-1, 1) :
				     Ack(m-1, Ack(m, n - 1)));
    }
}
