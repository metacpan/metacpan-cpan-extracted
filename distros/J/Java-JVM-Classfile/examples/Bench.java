class Bench {
    public static void main (String args[]) {
	int q = 1;
	int w = 1;
	int i = 1;
	int j = 1;
	while(q < 10) {
	    w = 1;
	    while(w < 10) {
		System.out.print(q + ", " + w + "\n");
		i++;
		j += i * 2;
		w++;
	    }
	    q++;
	}
    }
}

