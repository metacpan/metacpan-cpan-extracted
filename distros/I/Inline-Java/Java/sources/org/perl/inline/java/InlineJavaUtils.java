package org.perl.inline.java ;

import java.util.* ;


/*
	Creates a string representing a method signature
*/
class InlineJavaUtils { 
	private static int debug = 0 ;


	public synchronized static void set_debug(int d){
		debug = d ;
	}


	public static int get_debug(){
		return debug ;
	}


	static String CreateSignature(Class param[]){
		return CreateSignature(param, ", ") ;
	}


	static String CreateSignature(Class param[], String del){
		StringBuffer ret = new StringBuffer() ;
		for (int i = 0 ; i < param.length ; i++){
			if (i > 0){
				ret.append(del) ;
			}
			ret.append(param[i].getName()) ;
		}

		return "(" + ret.toString() + ")" ;
	}


	synchronized static void debug(int level, String s) {
		if ((debug > 0)&&(debug >= level)){
			StringBuffer sb = new StringBuffer() ;
			for (int i = 0 ; i < level ; i++){
				sb.append(" ") ;
			}
			System.err.println("[java][" + level + "]" + sb.toString() + s) ;
			System.err.flush() ;
		}
	}


	static void Fatal(String msg){
		System.err.println(msg) ;
		System.err.flush() ;
		System.exit(1) ;
	}


	static boolean ReverseMembers() {
		String v = System.getProperty("java.version") ;
		boolean no_rev = ((v.startsWith("1.2"))||(v.startsWith("1.3"))) ;

		return (! no_rev) ;
	}



	/* 
		Base64 stuff. This section conatins code by Christian d'Heureuse that is
		licended under the LGPL. Used by permission:

		From: Christian d'Heureuse <chdh@inventec.ch>
		To: Patrick LeBoutillier <patrick.leboutillier@gmail.com>
		Date: Aug 11, 2005 4:45 AM
		Subject: Re: Base64Coder

		> I was wondering if you can grant me permission to include your
		> code in my project.

		Yes, I grant you permission to include the Base64Coder class in your
		project.

		*
		* A Base64 Encoder/Decoder.
		*
		* This class is used to encode and decode data in Base64 format
		* as described in RFC 1521.
		*
		* <p>
		* Copyright 2003: Christian d'Heureuse, Inventec Informatik AG, Switzerland.<br>
		* License: This is "Open Source" software and released under the <a href="http://www.gnu.org/licenses/lgpl.html" target="_top">GNU/LGPL</a> license.
		* It is provided "as is" without warranty of any kind. Please contact the author for other licensing arrangements.<br>
		* Home page: <a href="http://www.source-code.biz" target="_top">www.source-code.biz</a><br>
		*
		* <p>
		* Version history:<br>
		* 2003-07-22 Christian d'Heureuse (chdh): Module created.<br>
		* 2005-08-11 chdh: Lincense changed from GPL to LGPL.
		*
	*/

	// Mapping table from 6-bit nibbles to Base64 characters.
	private static char[] map1 = new char[64];
	static {
		int i=0;
		for (char c='A'; c<='Z'; c++) map1[i++] = c;
		for (char c='a'; c<='z'; c++) map1[i++] = c;
		for (char c='0'; c<='9'; c++) map1[i++] = c;
		map1[i++] = '+'; map1[i++] = '/'; 
	}

	// Mapping table from Base64 characters to 6-bit nibbles.
	private static byte[] map2 = new byte[128];
	static {
		for (int i=0; i<map2.length; i++) map2[i] = -1;
		for (int i=0; i<64; i++) map2[map1[i]] = (byte)i; 
	}


	public static char[] EncodeBase64(byte[] in){
		int iLen = in.length;
		int oDataLen = (iLen*4+2)/3;       // output length without padding
		int oLen = ((iLen+2)/3)*4;         // output length including padding
		char[] out = new char[oLen];
		int ip = 0;
		int op = 0;
		while (ip < iLen) {
			int i0 = in[ip++] & 0xff;
			int i1 = ip < iLen ? in[ip++] & 0xff : 0;
			int i2 = ip < iLen ? in[ip++] & 0xff : 0;
			int o0 = i0 >>> 2;
			int o1 = ((i0 &   3) << 4) | (i1 >>> 4);
			int o2 = ((i1 & 0xf) << 2) | (i2 >>> 6);
			int o3 = i2 & 0x3F;
			out[op++] = map1[o0];
			out[op++] = map1[o1];
			out[op] = op < oDataLen ? map1[o2] : '='; op++;
			out[op] = op < oDataLen ? map1[o3] : '='; op++; 
		}
		return out; 
	}


	public static byte[] DecodeBase64(char[] in){
		int iLen = in.length;
		if (iLen%4 != 0) throw new IllegalArgumentException ("Length of Base64 encoded input string is not a multiple of 4.");
		while (iLen > 0 && in[iLen-1] == '=') iLen--;
		int oLen = (iLen*3) / 4;
		byte[] out = new byte[oLen];
		int ip = 0;
		int op = 0;
		while (ip < iLen) {
			int i0 = in[ip++];
			int i1 = in[ip++];
			int i2 = ip < iLen ? in[ip++] : 'A';
			int i3 = ip < iLen ? in[ip++] : 'A';
			if (i0 > 127 || i1 > 127 || i2 > 127 || i3 > 127)
				throw new IllegalArgumentException ("Illegal character in Base64 encoded data.");
			int b0 = map2[i0];
			int b1 = map2[i1];
			int b2 = map2[i2];
			int b3 = map2[i3];
			if (b0 < 0 || b1 < 0 || b2 < 0 || b3 < 0)
				throw new IllegalArgumentException ("Illegal character in Base64 encoded data.");
			int o0 = ( b0       <<2) | (b1>>>4);
			int o1 = ((b1 & 0xf)<<4) | (b2>>>2);
			int o2 = ((b2 &   3)<<6) |  b3;
			out[op++] = (byte)o0;
			if (op<oLen) out[op++] = (byte)o1;
			if (op<oLen) out[op++] = (byte)o2; 
		}
		return out; 
	}
}
