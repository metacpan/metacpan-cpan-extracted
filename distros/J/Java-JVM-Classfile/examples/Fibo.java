// $Id: fibo.java,v 1.2 2000/12/24 19:10:50 doug Exp $
// http://www.bagley.org/~doug/shootout/

public class Fibo {
    public static void main(String args[]) {
	int N = 10;
	System.out.println(fib(N));
    }
    public static int fib(int n) {
	if (n < 2) return(1);
	return( fib(n-2) + fib(n-1) );
    }
}
