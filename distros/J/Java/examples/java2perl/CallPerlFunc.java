/*
 * See call_perl_func.pl for how this gets called from Perl
 */

public class CallPerlFunc {

    Callback p;

	/* 
	 * This class gets instantiated by Perl
	 */
    public CallPerlFunc(Callback p){
        this.p=p;
    }

	/* 
	 * This function gets called by Perl
 	 *	& in turn calls a function in that perl script
	 */
    public String makeUpperCase(String in){
        return("Upper case "+
               p.eval("&make_upper_case("+in+")")
              );
    }
}

