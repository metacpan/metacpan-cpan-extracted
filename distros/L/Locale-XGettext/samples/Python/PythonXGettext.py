class PythonXGettext:
    def __init__(self, xgettext):
        self.xgettext = xgettext

    def readFile(self, filename):
        with open(filename) as f:
            lineno = 0
            for line in f:
                # You don't have to check that the line is empty.  The
                # PO header gets added after input has been processed.
                lineno = lineno + 1
                reference = "%s:%u" % (str(filename)[2:-1], ++lineno)
                self.xgettext.addEntry({'msgid': line, 'reference': reference})

    # Optional methods.
    
    # This method gets called right after all input files have been
    # processed and before the PO entries are sorted.  That means that you
    # can add more entries here.
    #
    # In this example we don't add any strings here but rather abuse the
    # method for showing advanced stuff like getting option values or
    # interpreting keywords.  Invoke the extractor with the option
    # "--test-binding" in order to see this in action.  */
    def extractFromNonFiles(self):
        if self.xgettext.option('test_binding') is None:
                return

        print("Keywords:")

        keywords = self.xgettext.keywords()
        for keyword, definition in keywords.items():
                if isinstance(keyword, bytes):
                    keyword = keyword.decode()
                print("function: " + keyword)

                context = definition.context()
                if isinstance(context, bytes):
                    context = context.decode()
                if context is not None:
                    print("  message context: argument#" + context)
                else:
                    print("  message context: [none]")

                sg = definition.singular() 
                if isinstance(sg, bytes):
                    sg = sg.decode()
                print("  singular form: argument#" + sg)

                pl = definition.plural()
                if isinstance(pl, bytes):
                    pl = pl.decode()

                if pl != 0:
                    print("  plural form: argument#" + pl)
                else:
                    print("  plural form: [none]")

                comment = definition.comment()
                if comment is None:
                    comment = "[none]"
                elif isinstance(comment, bytes):
                    comment = comment.decode()
                
                print("  automatic comment: " + comment)

        # Extracting the valid flags is left as an exercise to
        # the reader.  File a bug report if you cannot find yourself
        # how to do it.

        return

    # Describe the type of input files.
    def fileInformation(self):
        return "Input files are plain text files and are converted into one PO entry\nfor every non-empty line."
    
    # Return an array with the default keywords.  This is only used if the
    # method canKeywords() (see below) returns a truth value.  For the lines
    # extractor you would rather return None or an empty hash.
    def defaultKeywords(self):
        return [
                   'gettext:1', 
                   'ngettext:1,2',
                   'pgettext:1c,2',
                   'npgettext:1c,2,3' 
        ]               

    # You can add more language specific options here.  It is your
    # responsibility that the option names do not conflict with those of the
    # wrapper.
    def languageSpecificOptions(self):
        return [
                   [
                       [
                       # The option specification for Getopt::Long.  If you would
                       # expect a string argument, you would have to specify
                       # "test-binding=s" here, see 
                       # http://search.cpan.org/~jv/Getopt-Long/lib/Getopt/Long.pm 
                       # for details!
                       'test-binding',
                       
                       #  The "name" of the option variable.  This is the argument
                       # to option().
                       'test_binding',
                       
                       # The option as displayed in the usage description.  The
                       # leading four spaces compensate for the missing short
                       # option.
                       '    --test-binding',
                       
                       # The explanation of the option in the usage description.
                       'print additional information for testing the language binding'
                       ]
                   ]
               ]

    # Does the program honor the option -a, --extract-all?  The default
    # implementation returns false.
    def canExtractAll(self):
        return
    
    # Does the program honor the option -k, --keyword?  The default
    # implementation returns true.
    def canKeywords(self):
        return 1
    
    # Does the program honor the option --flag?  The default
    # implementation returns true.
    def canFlags(self):
        return 1
