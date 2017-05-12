
public class LongMath
{
    public static long addEm(long a, long b) { return a+b; }

    public static void main(String args[])
    {
        long a = 2147483648l;
        long b = 2147483648l;
        // java int range -2147483648 to 2147483647
        long sum = addEm(a,b);
        System.out.println(sum);
    }
}
