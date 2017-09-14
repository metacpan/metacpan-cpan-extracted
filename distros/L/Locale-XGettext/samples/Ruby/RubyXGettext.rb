# Helper function.  Check whether a Perl scalar evaluates to true.
def ptruthy(str)
    if str == 0 || str == '' || str == '0' || str == nil
        return false
    else
        return true
    end
end

class RubyXGettext
    def initialize(xgettext)
        # The hash xgettext contains 'Proc' objects for every method of
        # the 'Locale::XGettext' API.  The Perl wrapper also injects
        # a Ruby (instance) method into this class for every method
        # available from Perl.  For example, the method 'addEntry()'
        # looks like this:
        #
        # def addEntry()
        #     @xgettext['addEntry'].call(*args)
        # end
        # 
        # As a result, this Ruby class behaves as if it was subclassed
        # directly from the Perl class 'Inline::XGettext'.
        @xgettext = xgettext
    end

    def readFile(filename)
        # You don't have to check that the line is empty.  The
        # PO header gets added after input has been processed.
        lineno = 0
        File.readlines(filename).each do |line|
            lineno = lineno + 1
            reference = "#{filename}:#{lineno}"
            self.addEntry({'msgid': line, 'reference': reference})
        end 
    end

    # Optional methods.
    
    # This method gets called right after all input files have been
    # processed and before the PO entries are sorted.  That means that you
    # can add more entries here.
    #
    # In this example we don't add any strings here but rather abuse the
    # method for showing advanced stuff like getting option values or
    # interpreting keywords.  Invoke the extractor with the option
    # "--test-binding" in order to see this in action.  */
    def extractFromNonFiles()
        if !ptruthy self.option("test_binding")
            return self
        end

        puts "Keywords:"

        keywords = self.keywords
        keywords.each do |keyword, definition|
            puts "function: #{keyword}"
            
            if definition['context'] == nil
                puts "  message context: [none]"
            else
                puts "  message context: argument ##{definition['context']}"
            end

            singular = definition['singular']

            puts "  singular form: #{definition['singular']}"

            if definition['plural'] != 0
                puts "  plural form: #{definition['plural']}"
            else
                puts "  plural form: [none]"
            end
        
            # Try --keyword=hello:1c,2,3,'"Hello, world!"' to see an
            # automatic comment.
            puts "  automatic comment: #{definition['comment']}"
        end
    end

    # Describe the type of input files.
    def fileInformation()
        return "Input files are plain text files and are converted into one PO entry\nfor every non-empty line."
    end

    # Return an array with the default keywords.  This is only used if the
    # method canKeywords() (see below) returns a truth value.  For the lines
    # extractor you would rather return None or an empty hash.
    def defaultKeywords()
        return [
                   'gettext:1', 
                   'ngettext:1,2',
                   'pgettext:1c,2',
                   'npgettext:1c,2,3' 
        ] 
    end

    # You can add more language specific options here.  It is your
    # responsibility that the option names do not conflict with those of the
    # wrapper.
    def languageSpecificOptions()
        return [
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
    end

    # Does the program honor the option -a, --extract-all?  The default
    # implementation returns false.
    def canExtractAll()
        return 0
    end
    
    # Does the program honor the option -k, --keyword?  The default
    # implementation returns true.
    def canKeywords()
        return 1
    end
    
    # Does the program honor the option --flag?  The default
    # implementation returns true.
    def canFlags()
        return 1
    end
end
