import java.io.File;
import java.io.IOException;
import java.io.PrintWriter;
import java.io.StringWriter;
import java.lang.reflect.Constructor;
import java.lang.reflect.Field;
import java.lang.reflect.Method;
import java.lang.reflect.Modifier;
import java.net.URI;
import java.net.URL;
import java.net.URISyntaxException;
import java.util.ArrayList;
import java.util.Collections;
import java.util.Enumeration;
import java.util.HashMap;
import java.util.Iterator;
import java.util.List;
import java.util.Map;
import java.util.jar.JarEntry;
import java.util.jar.JarFile;

/**
 * I built this class to perform the introspection necessary to generate the
 * packages.yml file, which is then used by package-generator.pl to generate
 * each of the wrapper objects for the JCR classes.
 *
 * Copyright 2006 Andrew Sterling Hanenkamp (hanenkamp@cpan.org).  All Rights
 * Reserved.
 *
 * This module is free software; you can redistribute it and/or modify it under
 * the same terms as Perl.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE.
 *
 * @author Andrew Sterling Hanenkamp (hanenkamp@cpan.org)
 */
public class JCRPackageGenerator {

    /**
     * Print the usage message.
     */
    public static void usage() {
        System.err.println("usage: java [options] " + JCRPackageGenerator.class.getName() + " perl-blib-directory");
    }

    /**
     * Print an error message and then the usage message.
     *
     * @param message the error message to display
     */
    public static void usage(String message) {
        System.err.println("error: " + message);
        System.err.println();
        usage();
    }

    /**
     * Loads a {@link JarFile} object for the JCR library.
     *
     * @return an object representing the JCR library's JAR file.
     * @throws URISyntaxException if an error occurs parsing the JAR file's path
     * as discovered from the class loader
     * @throws IOException if an error occurs locating and creating the JAR file
     * object
     */
    public static JarFile getJCRJar() throws URISyntaxException, IOException {
        ClassLoader loader = JCRPackageGenerator.class.getClassLoader();
        URL repositoryURL = loader.getResource("javax/jcr/Repository.class");
        String repositoryPath = repositoryURL.getPath();
        int splitAt = repositoryPath.indexOf('!');
        URI jarURI = new URI(repositoryPath.substring(0, splitAt));
        JarFile jarFile = new JarFile(new File(jarURI));
        return jarFile;
    }

    /**
     * Reads all the class files found in the JCR JAR file and returns the
     * classes found in a list. Any class file found in the same JAR file as
     * {@link javax.jcr.Repository} will be returned.
     *
     * @param jarFile the JAR file object returned by {@link #getJCRJar()}
     * @return a {@link List} of {@link String}s, each containing the fully
     * qualified name of a Java class found in the JCR JAR
     */
    public static List getJCRClasses(JarFile jarFile) {
        List jcrClasses = new ArrayList();

        Enumeration entries = jarFile.entries();
        while (entries.hasMoreElements()) {
            JarEntry entry = (JarEntry) entries.nextElement();
            String entryName = entry.getName();

            if (entryName.matches(".*?\\.class$")) {
                String className 
                    = entryName.replaceAll("\\.class$", "")
                               .replaceAll("/", ".");
                jcrClasses.add(className);
            }
        }

        return jcrClasses;
    }

    /**
     * This method outputs a class' type name in a more friently format. If the
     * class represents an array type, it is printed as "Array:innerType" rather
     * than "[LinnerType;".
     *
     * @param clazz the {@link Class} to turn into a a {@link String}
     * @return a {@link String} containing the fully qualified type name with
     * array types abstracted as described above
     */
    public static String classAsString(Class clazz) {
        if (clazz.isArray()) {
            return "Array:" + classAsString(clazz.getComponentType());
        }

        else {
            return clazz.getName();
        }
    }

    /**
     * Takes a list of signatures and converts that into the YAML needed to
     * describe the return types and parameters. This method isn't currently
     * used, but I've left it because it might be used in the future.
     *
     * Output is sent to standard out.
     *
     * @param methodList a {@link List} containing {@link List}s containing
     * {@link Class} types. These represent all of the possible method
     * signatures of a given method name. The first element of the nested list
     * is the return type. The rest of the elements (if any) represent the
     * paraemter types.
     */
    public static void generateParametersConfig(List methodList) {
        Iterator methodIter = methodList.iterator();
        while (methodIter.hasNext()) {
            List signatureList = (List) methodIter.next();

            System.out.println("       -");
            
            Iterator signatureIter = signatureList.iterator();
            while (signatureIter.hasNext()) {
                Class parameter = (Class) signatureIter.next();
                System.out.println("         - " + classAsString(parameter));
            }
        }
    }

    /**
     * Creates the YAML required to represent each method and it's return type.
     *
     * Output is sent to standard out.
     *
     * @param methods the array of methods to output
     */
    public static void generateMethodsConfig(Method[] methods) {
        Map staticMethods = new HashMap();
        Map instanceMethods = new HashMap();

        for (int i = 0; i < methods.length; ++i) {
            Method thisMethod = methods[i];

            // Skip some of the mundane
            String name = thisMethod.getName();
            if ("hashCode".equals(name)) {
                continue;
            }
            else if ("getClass".equals(name)) {
                continue;
            }
            else if ("equals".equals(name)) {
                continue;
            }
            else if ("wait".equals(name)) {
                continue;
            }
            else if ("notify".equals(name)) {
                continue;
            }
            else if ("notifyAll".equals(name)) {
                continue;
            }

            Map methodMap = (thisMethod.getModifiers() & Modifier.STATIC) > 0
                ? staticMethods : instanceMethods;

            List methodList = methodMap.containsKey(thisMethod.getName())
                ? (List) methodMap.get(thisMethod.getName())
                : new ArrayList();

            List signatureList = new ArrayList();
            signatureList.add(thisMethod.getReturnType());
            Collections.addAll(signatureList, thisMethod.getParameterTypes());

            methodList.add(signatureList);

            methodMap.put(thisMethod.getName(), methodList);
        }

        if (!staticMethods.isEmpty()) {
            System.out.println("    static:");
            Iterator iter = staticMethods.entrySet().iterator();
            while (iter.hasNext()) {
                Map.Entry entry = (Map.Entry) iter.next();

                System.out.println("      " + entry.getKey() + ": " +
                        classAsString((Class) ((List) ((List) entry.getValue()).get(0)).get(0)));
//                generateParametersConfig((List) entry.getValue());
            }
        }

        if (!instanceMethods.isEmpty()) {
            System.out.println("    instance:");
            Iterator iter = instanceMethods.entrySet().iterator();
            while (iter.hasNext()) {
                Map.Entry entry = (Map.Entry) iter.next();

                System.out.println("      " + entry.getKey() + ": " +
                        classAsString((Class) ((List) ((List) entry.getValue()).get(0)).get(0)));
//                generateParametersConfig((List) entry.getValue());
            }
        }
    }

    /**
     * Generates the YAML configuration required to generate Perl wrapper
     * packages for each JCR class.
     *
     * All output is sent to standard out.
     *
     * @param classes this is the list of classes returned by {@link
     * getJCRClasses(JarFile)}
     * @throws ClassNotFoundException if an error occurs instantiating one of
     * the classes in the given list
     */
    public static void generateJCRForPerlConfig(List classes) 
            throws ClassNotFoundException {
        System.out.println("---");

        Iterator classIter = classes.iterator();
        while (classIter.hasNext()) {
            String className = (String) classIter.next();
            Class clazz = Class.forName(className);

            System.out.println(className + ":");

            if (clazz.getSuperclass() != null 
                    || clazz.getInterfaces().length > 0) {

                System.out.println("  isa:");
                if (clazz.getSuperclass() != null) {
                    System.out.println("   - " + 
                            classAsString(clazz.getSuperclass()));
                }
                
                Class[] interfaces = clazz.getInterfaces();
                for (int i = 0; i < interfaces.length; ++i) {
                    System.out.println("   - " +
                            classAsString(interfaces[i]));
                }
            }

            if (clazz.getConstructors().length > 0) {
                System.out.println("  has_constructors: 1");
            }
            else {
                System.out.println("  has_constructors: 0");
            }

            Field[] fields = clazz.getFields();
            if (fields.length > 0) {
                System.out.println("  static_fields:");
                for (int i = 0; i < fields.length; ++i) {
                    System.out.println("   - " + fields[i].getName());
                }
            }

            
            System.out.println("  methods:");
            generateMethodsConfig(clazz.getMethods());

            System.out.println();
        }
    }

    /**
     * Main program: finds the JAR file, extracts the list of classes, and
     * generates the YAML file containing information about the classes found.
     *
     * @param args unused
     * @throws IOException see {@link #getJCRJar()}
     * @throws URISyntaxException see {@link #getJCRJar()}
     * @throws ClassNotFoundException see {@link #getJCRClasses(JarFile)}
     */
    public static void main(String[] args) throws IOException, 
           URISyntaxException, ClassNotFoundException {

        // Load the classes
        JarFile jcrJar  = getJCRJar();
        List jcrClasses = getJCRClasses(jcrJar);

        // Generate the configuration
        generateJCRForPerlConfig(jcrClasses);
    }
}
