import java.io.*;
import java.net.URL;
import java.net.HttpURLConnection;
import java.lang.Runtime;
import java.lang.Process;
import java.util.*;

/* http://commons.apache.org/proper/commons-codec/download_codec.cgi */
import org.apache.commons.codec.binary.Base64;

/* http://json.org/java/ */
import org.json.JSONArray;
import org.json.JSONObject;

public class Sendmail {

    static final String addresser = "envelope-sender@example.jp";
    static final String recipient = "envelope-recipient@example.org";
    static final String emailbody = "メール本文です。";
    static final String authinfo  = "haineko:kijitora";

    public static void main( String args[] ) {

        // Get the result of hostname(1) for EHLO
        String greetings = "";
        try {
            String[] gethostname = { "hostname" };
            ProcessBuilder procbuilder = new ProcessBuilder( gethostname );
            Process p = procbuilder.start();

            InputStream is = p.getInputStream();
            BufferedReader br = new BufferedReader( new InputStreamReader(is) );

            String line;
            while( (line = br.readLine()) != null ) {
                greetings = line;
            }
            is.close();
            int ret = p.waitFor();

        } catch ( Exception e ) {
            greetings = "[127.0.0.1]";
        }


        String mimeencoded = null;
        String hainekoauth = System.getenv( "HAINEKO_AUTH" );
        String hainekoarg1 = ( args.length > 0 ) ? args[0] : "";

        if( ( hainekoauth != null && hainekoauth.length() > 0 ) ||
            ( hainekoarg1 != null && hainekoarg1.length() > 0 ) ) {

            try {
                //byte[] b1 = authinfo.getBytes
                byte[] b1 = authinfo.getBytes();
                byte[] b2 = Base64.encodeBase64( b1 );
                mimeencoded = new String( b2 );

            } catch ( Exception ee ) {
                mimeencoded = "";
                ee.printStackTrace(System.err);
            }
        }


        String[] recipients = { recipient };

        JSONObject emaildata1 = new JSONObject();
        JSONObject mailheader = new JSONObject();

        mailheader.put( "replyto", addresser );
        mailheader.put( "from", "キジトラ <" + addresser + ">" );
        mailheader.put( "charset", "UTF-8" );
        mailheader.put( "subject", "テストメール" );

        emaildata1.put( "ehlo", greetings );
        emaildata1.put( "body", emailbody );
        emaildata1.put( "mail", addresser );
        emaildata1.put( "rcpt", recipients );
        emaildata1.put( "header", mailheader );

        try {
            URL hainekohost = new URL( "http://127.0.0.1:2794/submit" );
            HttpURLConnection httpconn = ( HttpURLConnection ) hainekohost.openConnection();

            httpconn.setRequestMethod( "POST" );
            httpconn.setDoOutput( true );
            httpconn.setRequestProperty( "Content-Type", "application/json" );

            if( mimeencoded != null && mimeencoded.length() > 0 ) {
                httpconn.setRequestProperty( "Authorization", "Basic " + mimeencoded );
            }

            httpconn.connect();

            PrintWriter wbuff = new PrintWriter( new BufferedWriter(
                                    new OutputStreamWriter( httpconn.getOutputStream() ,"utf-8" ) )
                                );
            wbuff.print( emaildata1.toString() );
            wbuff.close();

             BufferedReader rbuff;
            try {
                rbuff = new BufferedReader( new InputStreamReader(
                            httpconn.getInputStream(), "UTF-8" )
                        );

            } catch( Exception ee ) {
                System.out.println( 
                        httpconn.getResponseCode() + " " +
                        httpconn.getResponseMessage()
                );
	            rbuff = new BufferedReader( new InputStreamReader(
                            httpconn.getErrorStream(), "UTF-8" )
                        );
            }

            String line;
            while( ( line = rbuff.readLine() ) != null ) {
                System.out.println( line );
            }

            rbuff.close();
            httpconn.disconnect(); 
            System.exit(0);

        } catch( Exception e ) {

            e.printStackTrace(System.err);
            System.exit(1);
        }
    }
}

