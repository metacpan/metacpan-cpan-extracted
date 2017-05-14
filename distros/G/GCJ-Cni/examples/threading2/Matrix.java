public class Matrix {
	private int[][] matrix;
	private int rows;
	private int cols;

	public Matrix ( int numRows, int numCols ) {
		matrix = new int[numRows][numCols];
		rows = numRows;
		cols = numCols;
	}

	public void set ( int row, int col, int val ) {
		matrix[row][col] = val;
	}

	public int get ( int row, int col ) {
		return matrix[row][col];
	}
	
	public Matrix multiply ( Matrix times ) {
		Thread[] threads = new Thread[this.rows * times.getCols()];
		Matrix result = new Matrix(this.rows, times.getCols());
		int curThread = 0;
		if ( this.getCols() != times.getRows() ) {
			throw new IllegalArgumentException("Rows of this must match cols of that");
		}
		for ( int i = 0; i < rows; i++ ) {
			for ( int j = 0; j < times.getCols(); j++ ) {
				ArrayMultiplier multiplier = new ArrayMultiplier(this, times, result, i, j);
				multiplier.start();
				threads[curThread++] = multiplier;
			}
		}
		for ( int i = 0; i < threads.length; i++ ) {
			try {
				threads[i].join();
			} catch ( InterruptedException e ) {
				e.printStackTrace();
			}
		}
		return result;
	}

	public int getRows ( ) {
		return rows;
	}

	public int getCols ( ) {
		return cols;
	}

	public void print ( ) {
		for ( int i = 0; i < rows; i++ ) {
			for ( int j = 0; j < cols; j++ ) {
				System.out.print(matrix[i][j] + " ");
			}
			System.out.println();
		}
	}

	private class ArrayMultiplier extends Thread {
		private Matrix a;
		private Matrix b;
		private Matrix result;
		private int row;
		private int col;
		
		public ArrayMultiplier ( Matrix a, Matrix b, Matrix result, int row, int col ) {
			this.a = a;
			this.b = b;
			this.row = row;
			this.col = col;
			this.result = result;
		}

		public void run ( ) {
			int sum = 0;
			for ( int i = 0; i < a.getCols(); i++ ) {
				sum += (a.matrix[row][i] * b.matrix[i][col]);
			}
			result.set(row, col, sum);
		}

	}

	private static void populate ( Matrix a ) {
		for ( int i = 0; i < a.getRows(); i++ ) {
			for ( int j = 0; j < a.getCols(); j++ ) {
				a.set(i, j, i*j);
			}
		}
	}

	public static void main ( String[] args ) {
		Matrix a = new Matrix(10, 10);
		populate(a);
		Matrix b = new Matrix(10, 10);
		populate(b);
		Matrix result = a.multiply(b);
		result.print();
	}

}
