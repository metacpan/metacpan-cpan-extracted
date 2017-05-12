
public class sleeper
{
	public static final void main( String[] args )
	{
		int duration = 5;
	
		System.out.println( "sleeper" );

		if( args.length > 0 )
		{
			try
			{
				duration = Integer.parseInt( args[0] );
			}
			catch( NumberFormatException nfe )
			{
				System.err.println( "duration must be an integer : " + args[0] );
				return;
			}
		}
		
		System.out.println( "sleeping " + duration + " seconds" );

		try
		{
			Thread.sleep( duration * 1000 );
		}
		catch( InterruptedException ie ) { /* NOP */ }

		System.out.println( "exiting" );

		return;
	}
}

