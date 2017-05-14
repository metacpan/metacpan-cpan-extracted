import java.util.Iterator;

public class ArgumentArray {

	private ObjectWrapper[] array = null;
	private int index = 0;
	
	public ArgumentArray ( int size ) {
		array = new ObjectWrapper[size];
	}

	public void addElement ( ObjectWrapper element ) {
		array[index++] = element;
	}

	public Iterator getIterator (  ) {
		return new ArgumentArrayIterator();
	}

	public int getSize() {
		return array.length;
	}

	class ArgumentArrayIterator implements Iterator {

		int curIndex = 0;
		
		public boolean hasNext() {
			if ( curIndex == array.length ) {
				return false;
			}
			return true;
		}

		public Object next() {
			if ( hasNext() ) {
				return array[curIndex++];
			} else {
				return null;
			}
		}
		
		public void remove() {
		}

	}

}
