/*
 * See simple.pl for how this gets called from Perl
 */

public class perljava {
    Callback p;

	/* 
	 * This class gets instantiated by Perl
	 */
    public perljava(Callback p){
        this.p=p;
    }

	/* 
	 * This function gets called by Perl
	 */
    public String doSomeJavaCode(){
        return("Welcome "+
               p.eval("$global_hash->{'name'}")+
               "!\n"
              );
    }
}

