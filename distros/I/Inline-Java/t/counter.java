class counter {
	static private int global_i = 0 ;
	private int i = 0 ;

	public counter(){
	}

	static public int gincr(){
		global_i++ ;
		return global_i ;
	}

	public int incr(){
		i++ ;
		return i ;
	}
}


