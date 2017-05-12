import java.util.* ;
import java.lang.reflect.* ;


public class InlineJavaUserClassLink {
	public InlineJavaUserClassLink(){
	}


	public Object invoke(Method m, Object o, Object p[]) throws IllegalAccessException, IllegalArgumentException, InvocationTargetException {
		return m.invoke(o, p) ;
	}


	public Object get(Field f, Object o) throws IllegalAccessException, IllegalArgumentException {
		return f.get(o) ;
	}


	public void set(Field f, Object o, Object p) throws IllegalAccessException, IllegalArgumentException {
		f.set(o, p) ;
	}


	public Object array_get(Object o, Integer idx){
		return Array.get(o, idx.intValue()) ;
	}


	public void array_set(Object o, Integer idx, Object elem) throws IllegalArgumentException {
		Array.set(o, idx.intValue(), elem) ;
	}


	public Object create(Class p, Object args[], Class proto[]) throws NoSuchMethodException, InstantiationException, IllegalAccessException, IllegalArgumentException, InvocationTargetException {
		// This will allow usage of the default no-arg constructor
		if (proto.length == 0){
			return p.newInstance() ;
		}
		else{
			Constructor con = (Constructor)p.getConstructor(proto) ;
			return con.newInstance(args) ;
		}
	}
}
