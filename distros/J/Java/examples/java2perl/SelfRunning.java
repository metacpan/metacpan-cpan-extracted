/*
 * See self_run.pl for how this gets called from Perl
 *
 * It gets compiled like:
 *	
 *	javac -classpath .:/path/to/JavaServer/JavaServer.jar SelfRunning.java
 *
 * & JavaServer gets started like
 *
 *	java -cp /path/to/JavaServer/JavaServer.jar:/path/to/SelfRunning.class JavaServer
 *
 */

public class SelfRunning {

    Callback p;
    public String perl_code = "package SelfRunning; sub toUp { my $var = shift;  print \"In SelfRunning::toUp - got $var!\n\";  uc $var; } sub toLo { lc shift; } 1;";

	/* 
	 * This class gets instantiated by Perl
	 */
    public SelfRunning(Callback p)
   {
        this.p=p;
    }

	/* 
	 * Have at it
	 */
    public void go()
	{
		// First load up our stuff
		p.eval(perl_code);

		// Let's call 'em!

		String test = "tEsT";

		String up = p.eval("&SelfRunning::toUp("+test+")");
		String down = p.eval("&SelfRunning::toLo("+test+")");

		System.out.println("Original: "+test);
		System.out.println("Upper Case: "+up);
		System.out.println("Lower Case: "+down);

      }
}

