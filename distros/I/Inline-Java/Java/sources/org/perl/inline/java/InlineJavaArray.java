package org.perl.inline.java ;

import java.util.* ;
import java.lang.reflect.Array ;


class InlineJavaArray {
	private InlineJavaClass ijc ;


	InlineJavaArray(InlineJavaClass _ijc){
		ijc = _ijc ;
	}


	Object CreateArray(Class c, StringTokenizer st) throws InlineJavaException {
		StringBuffer sb = new StringBuffer(st.nextToken()) ;
		sb.replace(0, 1, "") ;
		sb.replace(sb.length() - 1, sb.length(), "") ;

		StringTokenizer st2 = new StringTokenizer(sb.toString(), ",") ;
		ArrayList al = new ArrayList() ;
		while (st2.hasMoreTokens()){
			al.add(al.size(), st2.nextToken()) ;
		}

		int size = al.size() ;
		int dims[] = new int[size] ;
		for (int i = 0 ; i < size ; i++){
			dims[i] = Integer.parseInt((String)al.get(i)) ;
			InlineJavaUtils.debug(4, "array dimension: " + (String)al.get(i)) ;
		}

		Object array = null ;
		try {
			array = Array.newInstance(c, dims) ;

			ArrayList args = new ArrayList() ;
			while (st.hasMoreTokens()){
				args.add(args.size(), st.nextToken()) ;
			}

			// Now we need to fill it. Since we have an arbitrary number
			// of dimensions, we can do this recursively.

			PopulateArray(array, c, dims, args) ;
		}
		catch (IllegalArgumentException e){
			throw new InlineJavaException("Arguments to array constructor for class " + c.getName() + " are incompatible: " + e.getMessage()) ;
		}

		return array ;
	}


	void PopulateArray (Object array, Class elem, int dims[], ArrayList args) throws InlineJavaException {
		if (dims.length > 1){
			int nb_args = args.size() ;
			int nb_sub_dims = dims[0] ;
			int nb_args_per_sub_dim = nb_args / nb_sub_dims ;

			int sub_dims[] = new int[dims.length - 1] ;
			for (int i = 1 ; i < dims.length ; i++){
				sub_dims[i - 1] = dims[i] ;
			}
	
			for (int i = 0 ; i < nb_sub_dims ; i++){
				// We want the args from i*nb_args_per_sub_dim -> 
				ArrayList sub_args = new ArrayList() ; 
				for (int j = (i * nb_args_per_sub_dim) ; j < ((i + 1) * nb_args_per_sub_dim) ; j++){
					sub_args.add(sub_args.size(), (String)args.get(j)) ;
				}
				PopulateArray(((Object [])array)[i], elem, sub_dims, sub_args) ;
			}
		}
		else{
			String msg = "In creation of array of " + elem.getName() + ": " ;
			try {
				for (int i = 0 ; i < dims[0] ; i++){
					String arg = (String)args.get(i) ;

					Object o = ijc.CastArgument(elem, arg) ;
					Array.set(array, i, o) ;
					if (o != null){
						InlineJavaUtils.debug(4, "setting array element " + String.valueOf(i) + " to " + o.toString()) ;
					}
					else{
						InlineJavaUtils.debug(4, "setting array element " + String.valueOf(i) + " to " + o) ;
					}
		 		}
			}
			catch (InlineJavaCastException e){
				throw new InlineJavaCastException(msg + e.getMessage()) ;
			}
			catch (InlineJavaException e){
				throw new InlineJavaException(msg + e.getMessage()) ;
			}
		}
	}
}
