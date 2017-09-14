import java.io.*;
import java.util.*;
import org.perl.inline.java.*;

class JavaXGettext extends InlineJavaPerlCaller {
    public JavaXGettext() throws InlineJavaException {
    }

    /* This method gets called for every input file found.  It is supposed
     * to parse the file, extract the PO entries and add them.
     */
    public void readFile(String filename) 
            throws InlineJavaException, InlineJavaPerlException,
                   FileNotFoundException, IOException {
        BufferedReader r = new BufferedReader(new FileReader(filename));
        int lineno = 0;

        for(String line; (line = r.readLine()) != null; ) {
            ++lineno;

            if (line.equals(""))
                continue;
            CallPerlStaticMethod("Locale::XGettext::Callbacks", 
                                 "addEntry", 
                                 new Object [] {
                                     "msgid", line + "\n",
                                     "reference", filename + ':' + lineno,
                                 }, 
                                 Integer.class);
        }
    }
    
    /* All of the following methods are optional.  You do not have to
     * implement them.  */
    
    /* This method gets called right after all input files have been
     * processed and before the PO entries are sorted.  That means that you
     * can add more entries here.
     *
     * In this example we don't add any strings here but rather abuse the
     * method for showing advanced stuff like getting option values or
     * interpreting keywords.  Invoke the extractor with the option
     * "--test-binding" in order to see this in action.  */
    public void extractFromNonFiles() throws InlineJavaException,
                                             InlineJavaPerlException {
        /* Check whether --test-binding was specified.  */
        Object test = CallPerlStaticMethod("Locale::XGettext::Callbacks",
                                            "option",
                                            new Object [] {
                                                "test_binding"
                                            });
        if (test != null) {
            JavaXGettextKeywords keywords = (JavaXGettextKeywords)
                    CallPerlStaticMethod("Locale::XGettext::Callbacks",
                            "keywords", new Object[] {});

            Iterator it = keywords.entrySet().iterator();
            while (it.hasNext()) {
                Map.Entry kv = (Map.Entry) it.next();

                String function = (String) kv.getKey();
                JavaXGettextKeyword keyword = (JavaXGettextKeyword) kv.getValue();

                System.out.println("function: " + function);

                Integer context = keyword.context();
                if (context != null) {
                    System.out.println("  message context: argument #" + context);
                } else {
                    System.out.println("  message context: [none]");
                }

                System.out.println("  singular form: " + keyword.singular());
                if (keyword.plural() > 0) {
                    System.out.println("  plural form: " + keyword.plural());
                } else {
                    System.out.println("  plural form: [none]");
                }

                String comment = keyword.comment();
                System.out.println("  automatic comment: " + comment);
            }
        }
    }

    /* The following methods can also be implemented as class methods.  */

    /*
     * Return an array of arrays with the default keywords of this language.
     */
    public String[] defaultKeywords() {
        return new String[] {
                "gettext:1",
                "ngettext:1,2",
                "pgettext:1c,2",
                "npgettext:1c,2,3"
        };
    }
    
    /* Implement this method if you want to describe the type of input
     * files.  */
    public String fileInformation() {
        return "Input files are plain text files and are converted into one"
                + " PO entry\nfor every non-empty line.";
    }
    
    /* You can add more language specific options here.  It is your
     * responsibility that the option names do not conflict with those of the
     * wrapper.
     */
    public String[][] languageSpecificOptions() {
        return new String[][] {
            {
                /* The option specification for Getopt::Long.  If you would
                 * expect a string argument, you would have to specify
                 * "test-binding=s" here, see 
                 * http://search.cpan.org/~jv/Getopt-Long/lib/Getopt/Long.pm 
                 * for details!
                 */
                   "test-binding",
                   
                   /* The "name" of the option variable.  This is the argument
                    * to getOption().
                    */
                   "test_binding", 
                   
                   /* The option as displayed in the usage description.  The
                    * leading four spaces compensate for the missing short
                    * option.
                    */
                   "    --test-binding",
                   
                   /* The explanation of the option in the usage information.  */
                "print additional information for testing the language binding"
            }
            /* Add more option specifications here.  */
        };
    }
    
    /* Does the program honor the option -a, --extract-all?  The default
     * implementation returns false.
     */
    public boolean canExtractAll() {
        return false;
    }
    
    /* Does the program honor the option -k, --keyword?  The default
     * implementation returns true.
     */
    public boolean canKeywords() {
        return false;
    }
    
    /* Does the program honor the option --flag?  The default implementation 
     * returns true.
     */
    public boolean canFlags() {
        return false;
    }
       
}

/**
 * The Java equivalent of the Perl class Locale::XGettext::Util::Keyword.
 */
class JavaXGettextKeyword {
    String function;
    int singular;
    int plural; 
    Integer context;
    String comment;

    /**
     * Create one keyword definition.
     *
     * All indices used here are 1-based not 0-based!
     *
     * @param function              the name of the method
     * @param singular              the index of the argument containing the
     *                              singular form
     * @param plural                the index of the argument containing the
     *                              plural form or null
     * @param context               the index of the argument containing the
     *                              message context or null
     * @param comment               an automatic comment or null
     * @throws InlineJavaException  thrown for invalid usages
     */
    public JavaXGettextKeyword(String function, Integer singular, Integer plural,
                               Integer context, String comment)
            throws InlineJavaException {
        this.function = function;
        if (singular < 1)
            throw new InlineJavaException("Singular must always be defined");
        this.singular = singular;
        this.plural = plural;
        if (context > 0)
            this.context = context;
        if (comment != null)
            this.comment = comment;
    }

    /**
     * The name of the function.
     *
     * @return  the function name
     */
    public String function() {
        return this.function;
    }

    /**
     * Return the singular form.  This is guaranteed to be greater than zero!!
     *
     * @return      index of the singular
     */
    public Integer singular() {
        return this.singular;
    }

    /**
     * Return the plural form or 0 if there is no such form.
     *
     * @return      index of the plural
     */
    public Integer plural() {
        return this.plural;
    }

    /**
     * Argument for the message context.
     *
     * @return      index of the message context argument or null
     */
    public Integer context() {
        return this.context;
    }

    public String comment() {
        return this.comment;
    }
}

/* This is just here so that Perl knows about the class.  */
class JavaXGettextKeywords extends HashMap {
    public JavaXGettextKeywords() {

    }
}
