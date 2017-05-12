public class Features implements Runnable {
    private static int cnt;
    private Object target;

    public Features(Object target) {
        this.target = target;
    }

    public void run() {
        java.util.Date date = new java.util.Date();
        try {
            date = (java.util.Date) target;
        } catch (ClassCastException e) {
            e.printStackTrace();
        } finally {
            System.err.println();
        }
    }
}
