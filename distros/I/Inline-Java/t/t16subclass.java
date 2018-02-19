class Lower
{
	int a;
    public Lower(int p)
    {
		a= p;
	}
	public String outPrintValues() {
		return ("a = "+ this.a);
	}

}

public class t16subclass extends Lower {
	private int b;

	public t16subclass(int p, int q) {
		super(p);
		this.b = q;
	}

	public int getHigherValues() {
		return this.b;
	}
	public String printValues() {
		return "a = "+ this.a + "\nb = " + b;
	}
}
