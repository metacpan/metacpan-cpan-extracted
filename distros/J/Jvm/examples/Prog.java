// Ident = $Id: Prog.java,v 1.2 2000/09/24 03:28:02 yw Exp $ 

import java.io.*;

public class Prog {
	int m_i;
	String m_s;
	public static byte s_bID = 0;
	public static String s_id= "This is from Java!";
	public static PrintStream s_out=null;

	public Prog() {
		System.out.println("Inside Java: void()!" );
	}

	public Prog(Prog g) {
		System.out.println("Inside Java: test pass obj");
		System.out.println("Inside Java: " + g.m_i);
		System.out.println("Inside Java: "  + g.m_s);
	}

	public Prog(int i, String s) {
		m_i = i;
		m_s = s;
		System.out.println("Inside Java: " + i +"," + s);
	}

	public boolean test_obj_boolean() {
		System.out.println("Inside Java");
		return false;
	}

	public boolean test_obj_boolean(int i, String s) {
		System.out.println("Inside Java: args " + i +"," + s);
		System.out.println("Inside Java: instances " + m_i +"," + m_s);
		return false;
	}

	public Prog(String s) {}

	public static int test_int() {
		System.out.println("Inside Java: Enter Prog::test_int()!!!!");
		return 99;
	}
	public static boolean test_boolean(boolean b, int i, String str) {
		System.out.println("Inside java: " + b + "," + i + "," + str);
		return false;
	}
	public static String test_string() {
		return "Inside Java: Hello Perl! :)";
	}
	public void test() {
	}

	public static void dump(Object o) {
		System.out.println(o);
	}

	public String toString() {
		return "Dump Prog() class: " + m_i + ", " + m_s + "," + s_id;
	}
	public static String s_toString() {
		return "Inside java: This is static toString() method!\n";
	}

	public static void getArray(String[] in) {
		for(int i=0; i< in.length; i++) {
			System.out.println("Input[" + i + "]=" + in[i]);
		}
	}
	public static String[] staticRetStrArray() {
		String[] b= new String[5];
		for(int i=0; i<5; i++) b[i]=new String("Hello "+i+"!");
		return b;
	}
	public String[] retStrArray() {
		String[] s= new String[5];
		for(int i=0; i<5; i++) s[i]=new String("Hello "+i+"!!");
		return s;
	}

	public static void main(String[] arg) {
	    System.out.println("Hello world!");
	}
}
