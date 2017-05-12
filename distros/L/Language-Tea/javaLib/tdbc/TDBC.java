package javaLib.tdbc;

import java.sql.*;
import java.util.*;
import java.text.SimpleDateFormat;

public class TDBC{
    private static String url                   = null;
    private static String user                  = null;
    private static String pass                  = null;
    private static List<Connection> connections = null;

    public TDBC(){
    }

    public static List <String> tdbcSetDefault(String Url, String Usr, String Pass){
        List<String> aux = new ArrayList<String>();
        aux.add(url);
        aux.add(user);
        aux.add(pass);

        url     = Url;
        user    = Usr;
        pass    = Pass;

        return aux;
    }

    public static Integer tdbcCloseAllConnections(){
        try{
            for (Connection a : connections)
                a.close();
        }catch(Exception e){
        }
        if (connections == null)
           return null;
        return new Integer(connections.size());
    }

    public static Connection tdbcConnection(){
        try{
            Connection aux = DriverManager.getConnection(url,user,pass);  
            connections.add(aux);
            return aux;
        }catch(Exception e){
            System.out.println(e.getMessage());
        }

        return null;
    }

    public static List <String> tdbcGetDefault(){
        List<String> aux = new ArrayList<String>();
        aux.add(url);
        aux.add(user);
        aux.add(pass);

        return aux;
    }

    public static Integer tdbcGetOpenConnectionsCount(){
        if (connections != null)
            return new Integer(connections.size());
        return 0;
    }

    public static void tdbcRegisterDriver(String driver){
        try{
            Class.forName(driver).newInstance(); 
        }catch(Exception e){
            System.out.println("could not load class '" + e.getMessage() + "'");
        }
    }


    /*
     *              HERE STARTS THE OBJECT IMPLEMENTATION
     *
     *
    */
    
    // TConnection Constructors 
    public static Connection tdbcConstructor(){    
        return null;
    }
    public static Connection tdbcConstructor(String Url){    
        return tdbcConnect(null, Url);
    }
    public static Connection tdbcConstructor(String Url, String User, String Pass){    
        return tdbcConnect(null, Url, User, Pass);
    }
    // END OF TConnection Constructors
                                      
    // tdbcConnect
    public static Connection tdbcConnect(Connection conn, String Url){    
        try{
            if(conn != null && !conn.isClosed())
                conn.close();
            conn = DriverManager.getConnection(Url);   
            return conn;
        }catch(Exception e){
            System.out.println(e);
        }
        return null;
    }        
    public static Connection tdbcConnect(Connection conn, String Url, String User, String Pass){    
        try{
            if(conn != null && !conn.isClosed())
                conn.close();
            conn = DriverManager.getConnection(Url);   
            return conn;
        }catch(Exception e){
            System.out.println(e);
        }
        return null;
    }
    // END OF TDBCCONNECT

    public static Boolean tdbcHasRows(ResultSet rs){
        try{
            int aux = rs.getRow();
            boolean aux2 = rs.first();
            rs.absolute(aux);
            return aux2;
        }catch(Exception e){
            System.out.println(e);
        }
        return false;
    }

    public static Integer tdbcCompareDates (java.util.Date invocant, java.util.Date otherObj) {
        if (invocant.compareTo(otherObj) < 0)
            return -1;
        else if (invocant.compareTo(otherObj) > 0)
            return 1;
        else return 0;
    }

    public static Integer tdbcGetMonth(java.util.Date invocant) {
        return invocant.getMonth() + 1 ;
    }
    
    public static Integer tdbcGetYear(java.util.Date invocant) {
        return invocant.getYear() + 1900 ;
    }
    
    
    public static java.util.Date tdbcDateConstructor() {
        return new  java.util.Date(); 
    }
    
    public static java.util.Date tdbcDateConstructor(int year, int month, int day, int hour, int minute, int second) {
        return new  java.util.Date(year - 1900, month - 1, day, hour, minute, second); 
    }
    public static java.util.Date tdbcDateConstructor(int year, int month, int day) { 
        return new  java.util.Date(year - 1900, month - 1, day);
    }
    public static java.util.Date tdbcDateConstructor(String date){
        java.util.Date a = new java.util.Date(date);
        a.setYear(a.getYear() - 1900);
        if (a.getMonth() != 0)
         a.setMonth(a.getMonth() -1);
        else a.setMonth(11);
        return a;
    }
    public static java.util.Date tdbcDateConstructor(java.util.Date date){
        return (java.util.Date)date.clone();
    }

    public static void tdbcSetDate(java.util.Date date, int year, int month, int day, int hour, int minute, int second) {
        date.setYear(year - 1900);
        date.setMonth(month - 1);
        date.setDate(day);
        date.setHours(hour);
        date.setMinutes(minute);
        date.setSeconds(second);
    }
    
    public static void tdbcSetDate(java.util.Date date, int year, int month, int day) { 
        date.setYear(year - 1900);
        date.setMonth(month - 1);
        date.setDate(day);
        date.setHours(0);
        date.setMinutes(0);
        date.setSeconds(0);
    }

    public static void tdbcSetDate(java.util.Date date, java.util.Date obj) {
        date.setYear(obj.getYear());
        date.setMonth(obj.getMonth());
        date.setDate(obj.getDate());
        date.setHours(obj.getHours());
        date.setMinutes(obj.getMinutes());
        date.setSeconds(obj.getSeconds());
    }

    public static void tdbcSetDate(java.util.Date date, String s) {
        java.util.Date obj = new java.util.Date(date.parse(s));

        date.setYear(obj.getYear());
        date.setMonth(obj.getMonth());
        date.setDate(obj.getDate());
        date.setHours(obj.getHours());
        date.setMinutes(obj.getMinutes());
        date.setSeconds(obj.getSeconds());
    }

    public static void tdbcSetTime(java.util.Date date, int hour, int minute, int second){
        date.setHours(hour);
        date.setMinutes(minute);
        date.setSeconds(second); 
    }

}
