package org.perl.inline.java ;

import java.io.* ;
import java.net.* ;
import java.util.* ;


class InlineJavaServerThread extends Thread {
	private InlineJavaServer ijs ;
	private Socket client ;
	private BufferedReader br ;
	private BufferedWriter bw ;
	private InlineJavaUserClassLoader ijucl ;


	InlineJavaServerThread(String name, InlineJavaServer _ijs, Socket _client, InlineJavaUserClassLoader _ijucl) throws IOException {
		super(name) ;
		client = _client ;
		ijs = _ijs ;
		ijucl = _ijucl ;

		InputStreamReader ir = new InputStreamReader(client.getInputStream()) ;
		OutputStreamWriter or = new OutputStreamWriter(client.getOutputStream()) ;
		br = new BufferedReader(ir) ;
		bw = new BufferedWriter(or) ;
	}


	BufferedReader GetReader(){
		return br ;
	}


	BufferedWriter GetWriter(){
		return bw ;
	}

	
	InlineJavaUserClassLoader GetUserClassLoader(){
		return ijucl ;
	}


	public void run(){
		try {
			ijs.AddThread(this) ;

			while (true){
				String cmd = br.readLine() ;

				String resp = ijs.ProcessCommand(cmd) ;
				if (resp != null){
					bw.write(resp) ;
					bw.flush() ;
				}
				else {
					client.close() ;
					break ;
				}
			}
		}
		catch (IOException e){
			System.err.println("IO error: " + e.getMessage()) ;
		}
		finally {
			ijs.RemoveThread(this) ;
		}
	}
}
