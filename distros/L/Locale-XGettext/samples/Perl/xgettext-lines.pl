#! /usr/bin/env perl

use strict;

Locale::XGettext::MyExtractor->newFromArgv(\@ARGV)->run->output;

package Locale::XGettext::MyExtractor;

use strict;

use base qw(Locale::XGettext);

our $VERSION = '23.4.89';

sub readFile {
    my ($self, $filename) = @_;

    open my $fh, "<$filename" or die "Error reading '$filename': $!\n";
    
    my $lineno = 0;
    while (my $line = <$fh>) {
        ++$lineno;
        $self->addEntry({msgid => $line,
                         reference => "$filename:$lineno"});
    }

    return $self;
}

sub extractFromNonFiles {
    my ($self) = @_;

    if (!$self->option("test_binding")) {
        return $self;
    }

    print "Keywords:\n";

    my $keywords = $self->keywords;
    while (my ($keyword, $definition) = each %$keywords) {
        print "function: $keyword\n";
            
        my $context = $definition->context;
        if (defined $context) {
            print "  message context: argument #$context\n";
        } else {
            print "  message context: [none]\n";
        }

        my $singular = $definition->{singular};

        print "  singular form: argument #$singular\n";

        my $plural = $definition->plural;
        if ($plural) {
            print "  plural form: argument #$plural\n";
        } else {
            print "  plural form: [none]\n";
        }
                
        # Try --keyword=hello:1c,2,3,'"Hello, world!"' to see an
        # automatic comment.
        my $comment = $definition->comment;
        $comment = '[none]' if !defined $comment;
        print "  automatic comment: $comment\n";
    }

    return $self;
}

# Describe the type of input files.
sub fileInformation {
    return "Input files are plain text files and are converted into one PO entry\nfor every non-empty line."
}

# Return an array with the default keywords.  This is only used if the
# method canKeywords() (see below) returns a truth value.  For the lines
# extractor you would rather return undef or an empty hash.
sub defaultKeywords {
    return [ 
        'gettext:1', 
        'ngettext:1, 2',
        'pgettext:1c,2',
        'npgettext:1c,2,3'
    ];
}

# You can add more language specific options here.  It is your
# responsibility that the option names do not conflict with those of the
# wrapper.
sub languageSpecificOptions {
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
    ];
}

sub canExtractAll {
    return;
}

sub canKeywords {
    return 1;
}

sub canFlags {
    return 1;
}

1;
