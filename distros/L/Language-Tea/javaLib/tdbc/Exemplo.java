// -----------------------------------------------------------------------------
// ConnectionExample.java
// -----------------------------------------------------------------------------

/*
 * =============================================================================
 * Copyright (c) 1998-2007 Jeffrey M. Hunter. All rights reserved.
 * 
 * All source code and material located at the Internet address of
 * http://www.idevelopment.info is the copyright of Jeffrey M. Hunter and
 * is protected under copyright laws of the United States. This source code may
 * not be hosted on any other site without my express, prior, written
 * permission. Application to host any of the material elsewhere can be made by
 * contacting me at jhunter@idevelopment.info.
 *
 * I have made every effort and taken great care in making sure that the source
 * code and other content included on my web site is technically accurate, but I
 * disclaim any and all responsibility for any loss, damage or destruction of
 * data or any other property which may arise from relying on it. I will in no
 * case be liable for any monetary damages arising from such loss, damage or
 * destruction.
 * 
 * As with any code, ensure to test this code in a development environment 
 * before attempting to run it in production.
 * =============================================================================
 */
 
import java.sql.DriverManager;
import java.sql.Connection;
import java.sql.Statement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.Properties;

/**
 * -----------------------------------------------------------------------------
 * The following class provides an example of using JDBC to connect to an
 * Oracle database. The one phase of JDBC that is the most difficult and 
 * hard to achieve portability, is when connecting. This phase requires
 * that the Java database application specify driver-specific information that
 * JDBC requires in the form of a database URL.
 * 
 * If you run into problems while trying to simply make a connection, check
 * if they match any of the following:
 * 
 *    Connection fails with the message "Class no found"
 *    --------------------------------------------------
 *    This message usually results from not having the JDBC driver in your
 *    CLASSPATH. Ensure that if you are including *.zip and *.jar in your
 *    CLASSPATH, that your enter them explicity. If you put all of your *.class
 *    files and the ojdbc14.jar file containing the Oracle-JDBC driver into
 *    /u02/lib, your CLASSPATH should read /u02/lib:/u02/lib/ojdbc14.jar.
 *  
 *    Connection fails with the message "Driver no found"
 *    ---------------------------------------------------
 *    In this case, you did not register the JDBC driver with the DriverManager
 *    class. This example application describes several ways to register a
 *    JDBC driver. Sometimes developers using the Class.forName() method of
 *    registering a JDBC driver encounter an inconsistency between the JDBC
 *    specification and some JVM implementations. You should thus use the
 *    Class.forName().netInstance() method as a workaround.
 * 
 * When attempting to make a database connection, your application must first
 * request a java.sql.Connection implementation from the DriverManager. You will
 * also use a database URL and whatever properties your JDBC driver requires
 * (generally a user ID and password). The DriverManager in turn will search
 * through all of the known java.sql.Driver implementations for the one that
 * connects with the URL you provided. If it exhausts all the implementations
 * without finding a match, it throws an exception back to your application.
 * 
 * Once a Driver recognizes your URL, it creates a database connection using
 * the properties you specified. It then provides the DriverManager with a 
 * java.sql.Connection implementation representing that database connection. The
 * DriverManager then passes that Connection object back to the application.
 * 
 * At this point, you may be wondering how the JDBC DriverManager learns about
 * a new driver implementation. The DriverManager actually keeps a list of
 * classes that implement that java.sql.Driver interface. Something needs to 
 * register the Driver implementation for any potential database drivers it
 * might require with the DriverManager. JDBC requires a Driver class to
 * register itself with the DriverManager when it is initiated. The act of
 * instantiating a Driver class thus enters it in the DriverManager's list.
 * 
 * This class (ConnectionExample) provides three ways to register a driver.
 * -----------------------------------------------------------------------------
 * @version 1.0
 * @author  Jeffrey M. Hunter  (jhunter@idevelopment.info)
 * @author  http://www.idevelopment.info
 * -----------------------------------------------------------------------------
 */

public class ConnectionExample {

    final String driverClass        = "oracle.jdbc.driver.OracleDriver";
    final String connectionURLThin  = "jdbc:oracle:thin:@jeffreyh3:1521:CUSTDB";
    final String connectionURLOCI   = "jdbc:oracle:oci8:@CUSTDB_JEFFREYH3";
    final String userID             = "scott";
    final String userPassword       = "tiger";
    final String queryString        = "SELECT" +
                                      "    user " +
                                      "  , TO_CHAR(sysdate, 'DD-MON-YYYY HH24:MI:SS') " +
                                      "FROM dual";

    /**
     * The following method provides an example of how to connect to a database
     * by registering the JDBC driver using the DriverManager class. This method
     * requires you to hardcode the loading of a Driver implementation in
     * your application. this alternative is the least desirable since it
     * requires a rewrite and recompile if your database or database driver
     * changes.
     */
    public void driverManager() {

        Connection con = null;
        Statement stmt = null;
        ResultSet rset = null;

        try {

            System.out.print("\n");
            System.out.print("+-------------------------------+\n");
            System.out.print("| USING DriverManager CLASS     |\n");
            System.out.print("+-------------------------------+\n");
            System.out.print("\n");

            System.out.print("  Loading JDBC Driver  -> " + driverClass + "\n");
            DriverManager.registerDriver(new oracle.jdbc.driver.OracleDriver());

            System.out.print("  Connecting to        -> " + connectionURLThin + "\n");
            con = DriverManager.getConnection(connectionURLThin, userID, userPassword);
            System.out.print("  Connected as         -> " + userID + "\n");

            System.out.print("  Creating Statement...\n");
            stmt = con.createStatement ();

            System.out.print("  Opening ResultsSet...\n");
            rset = stmt.executeQuery(queryString);

            while (rset.next()) {
                System.out.println("  Results...");
                System.out.println("      User             -> " + rset.getString(1));
                System.out.println("      Sysdate          -> " + rset.getString(2));
            }

            System.out.print("  Closing ResultSet...\n");
            rset.close();

            System.out.print("  Closing Statement...\n");
            stmt.close();

        } catch (SQLException e) {

            e.printStackTrace();
    
            if (con != null) {
                try {
                    con.rollback();
                } catch (SQLException e1) {
                    e1.printStackTrace();
                }
            }

        } finally {

            if (con != null) {
                try {
                    System.out.print("  Closing down all connections...\n\n");
                    con.close();
                } catch (SQLException e) {
                    e.printStackTrace();
                }
            }

        }

    }


    /**
     * The following method provides an example of how to connect to a database
     * by registering the JDBC driver using the jdbc.drivers property. The
     * DriverManager will load all classes listed in this property
     * automatically. This alternative works well for applications with a 
     * command-line interface, but might not be so useful in GUI applications
     * and applets. This is because you can specify properties at the command
     * line.
     */
    public void jdbcDriversProperty() {

        Connection con = null;
        Statement stmt = null;
        ResultSet rset = null;

        try {

            System.out.print("\n");
            System.out.print("+-------------------------------+\n");
            System.out.print("| USING jdbc.drivers PROPERTY   |\n");
            System.out.print("+-------------------------------+\n");
            System.out.print("\n");

            System.out.print("  Loading JDBC Driver  -> " + driverClass + "\n");
            System.setProperty("jdbc.drivers", driverClass);

            System.out.print("  Connecting to        -> " + connectionURLThin + "\n");
            con = DriverManager.getConnection(connectionURLThin, userID, userPassword);
            System.out.print("  Connected as         -> " + userID + "\n");

            System.out.print("  Creating Statement...\n");
            stmt = con.createStatement ();

            System.out.print("  Opening ResultsSet...\n");
            rset = stmt.executeQuery(queryString);

            while (rset.next()) {
                System.out.println("  Results...");
                System.out.println("      User             -> " + rset.getString(1));
                System.out.println("      Sysdate          -> " + rset.getString(2));
            }

            System.out.print("  Closing ResultSet...\n");
            rset.close();

            System.out.print("  Closing Statement...\n");
            stmt.close();

        } catch (SQLException e) {

            e.printStackTrace();

            if (con != null) {
                try {
                    con.rollback();
                } catch (SQLException e1) {
                    e1.printStackTrace();
                }
            }


        } finally {

            if (con != null) {
                try {
                    System.out.print("  Closing down all connections...\n\n");
                    con.close();
                } catch (SQLException e) {
                    e.printStackTrace();
                }
            }

        }

    }


    /**
     * The following method provides an example of how to connect to a database
     * by registering the JDBC driver using the Class.forName() method. This
     * complex expression is a tool for dynamically creating an instance of
     * a class when you have some variable representing the class name. Because
     * a JDBC driver is required to register itself whenever its static
     * initializer is called, this expression has the net effect of registering
     * your driver for you. 
     *
     *      NOTE: When using Class.forName("classname"), the JVM is supposed to
     *            be sufficient. Unfortunately, some Java virtual machines do
     *            not actuall call the static intitializer until an instance of
     *            a class is created. As a result, newInstance() should be 
     *            called to guarantee that the static initializer is run for
     *            all virtual machines.
     *
     * This method is by far the BEST in that it does not require hardcoded 
     * class names and it runs well in all Java environments. In real-world
     * applications, you should use this method along with a properties file
     * from which you load the name of the driver.
     * 
     */
    public void classForName() {

        Connection con = null;
        Statement stmt = null;
        ResultSet rset = null;
            
        try {

            System.out.print("\n");
            System.out.print("+-------------------------------+\n");
            System.out.print("| USING Class.forName()         |\n");
            System.out.print("+-------------------------------+\n");
            System.out.print("\n");


            System.out.print("  Loading JDBC Driver  -> " + driverClass + "\n");
            Class.forName(driverClass).newInstance();

            System.out.print("  Connecting to        -> " + connectionURLThin + "\n");
            con = DriverManager.getConnection(connectionURLThin, userID, userPassword);
            System.out.print("  Connected as         -> " + userID + "\n");

            System.out.print("  Creating Statement...\n");
            stmt = con.createStatement ();

            System.out.print("  Opening ResultsSet...\n");
            rset = stmt.executeQuery(queryString);

            while (rset.next()) {
                System.out.println("  Results...");
                System.out.println("      User             -> " + rset.getString(1));
                System.out.println("      Sysdate          -> " + rset.getString(2));
            }

            System.out.print("  Closing ResultSet...\n");
            rset.close();

            System.out.print("  Closing Statement...\n");
            stmt.close();

        } catch (ClassNotFoundException e) {

            e.printStackTrace();
        
        } catch (InstantiationException e) {

            e.printStackTrace();

        } catch (IllegalAccessException e) {

            e.printStackTrace();

        } catch (SQLException e) {

            e.printStackTrace();

            if (con != null) {
                try {
                    con.rollback();
                } catch (SQLException e1) {
                    e1.printStackTrace();
                }
            }

        } finally {

            if (con != null) {
                try {
                    System.out.print("  Closing down all connections...\n\n");
                    con.close();
                } catch (SQLException e) {
                    e.printStackTrace();
                }
            }

        }

    }


    /**
     * The following method provides an example of how to connect to a database
     * using the OCI JDBC Driver.
     * 
     */
    public void jdbcOCIDriver() {

        Connection con = null;
        Statement stmt = null;
        ResultSet rset = null;
            
        try {

            System.out.print("\n");
            System.out.print("+-------------------------------+\n");
            System.out.print("| USING OCI Driver              |\n");
            System.out.print("+-------------------------------+\n");
            System.out.print("\n");


            System.out.print("  Loading JDBC Driver  -> " + driverClass + "\n");
            Class.forName(driverClass).newInstance();

            System.out.print("  Connecting to        -> " + connectionURLOCI + "\n");
            con = DriverManager.getConnection(connectionURLOCI, userID, userPassword);
            System.out.print("  Connected as         -> " + userID + "\n");

            System.out.print("  Creating Statement...\n");
            stmt = con.createStatement ();

            System.out.print("  Opening ResultsSet...\n");
            rset = stmt.executeQuery(queryString);

            while (rset.next()) {
                System.out.println("  Results...");
                System.out.println("      User             -> " + rset.getString(1));
                System.out.println("      Sysdate          -> " + rset.getString(2));
            }

            System.out.print("  Closing ResultSet...\n");
            rset.close();

            System.out.print("  Closing Statement...\n");
            stmt.close();

        } catch (ClassNotFoundException e) {

            e.printStackTrace();
        
        } catch (InstantiationException e) {

            e.printStackTrace();

        } catch (IllegalAccessException e) {

            e.printStackTrace();

        } catch (SQLException e) {

            e.printStackTrace();

            if (con != null) {
                try {
                    con.rollback();
                } catch (SQLException e1) {
                    e1.printStackTrace();
                }
            }

        } finally {

            if (con != null) {
                try {
                    System.out.print("  Closing down all connections...\n\n");
                    con.close();
                } catch (SQLException e) {
                    e.printStackTrace();
                }
            }

        }

    }


    /**
     * Sole entry point to the class and application.
     * @param args Array of String arguments.
     * @exception java.lang.InterruptedException
     *            Thrown from the Thread class.
     */
    public static void main(String[] args)
            throws java.lang.InterruptedException {

        ConnectionExample conExample = new ConnectionExample();

        conExample.classForName();

        Thread.sleep(5000);
        
        conExample.jdbcDriversProperty();

        Thread.sleep(5000);
        
        conExample.driverManager();
        
        Thread.sleep(5000);

        conExample.jdbcOCIDriver();

    }

}

