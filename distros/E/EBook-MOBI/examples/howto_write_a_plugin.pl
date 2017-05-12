######################################################################
# This code shows a very simple example of how to implement a plugin #
# for EBook::MOBI                                                    #
######################################################################
package EBook::MOBI::Example::AnyPlugin;

use strict;
use warnings;

# This is an input plugin for EBook::MOBI
use EBook::MOBI::Driver;
our @ISA = qw(EBook::MOBI::Driver);

# We use the converter to give us some help
use EBook::MOBI::Converter;

use feature 'switch';

# The only thing that needs to be implemented is the parse method.
# It should take a string and return a converted string.
sub parse {
    my ($self, $anyFormat) = @_;

    # This module can help me to translate my stuff to html understood by
    # the mopipocket format
    my $converter = EBook::MOBI::Converter->new();

    # Because of "KISS" the module does not do much, but return the
    # converted stuff. So I need to manage the output myself.
    # I'll keep everything in this variable.
    my $mobiFormat = '';

    # We have some usefull methods from EBook::MOBI::Driver
    $self->debug_msg("Start parsing...");

    ########################################################################
    # Here is the parsing... for sure this looks different for any other   #
    # format. You might even use an existing parser like e.g. POD::Parser. #
    ########################################################################

    # work on each line, including newline
    while($anyFormat =~ /([^\n]+\n?)/g){
        my $line = $1;

        # this converts every html special char to it's html entity.
        # if your markups format does interfere with html special chars
        # you should call this AFTER parsing.
        my $mobi_line .= $converter->text($line);

        if ($mobi_line =~ /^!(.)!\s+(.*)/) {
            my $cmd = $1;
            my $txt = $2;

            given ($cmd) {
                when ('h') { $mobiFormat .= $converter->title ($txt)  }
                when ('i') { $mobiFormat .= $converter->italic($txt)
                                         .  $converter->newline();    }
                when ('b') { $mobiFormat .= $converter->bold  ($txt)
                                         .  $converter->newline();    }
                when (' ') { $mobiFormat .=                    $txt
                                         .  $converter->newline();    }
                default    { $self->debug_msg("Unknown format: $cmd") }
            }
        }
        else {
            $self->debug_msg("Unknown line: $mobi_line");
        }
    }

    $self->debug_msg("...done");

    # and return the complete converted text
    return $mobiFormat;
}

# That's it.
# We have created an input plugin for EBook::MOBI
# Now let's test it.
# This is basically how EBook::MOBI will call it later on.

######################################################################
# This code shows a very simple example of how such a plugin then    #
# can be used                                                        #
######################################################################
package EBook::MOBI::Example::UsePlugin;

use feature 'say';

# This code-file is utf8, and the example text also
use utf8;

# we create an instance to the plugin
my $plugin = EBook::MOBI::Example::AnyPlugin->new();

# we have some debug features offered by any plugin
$plugin->debug_on(  sub {
                        my ($package, $filename, $line) = caller;
                        print "$package\t$_[0]\n";
                    }
                 );

# this is our fancy markup for test purposes and demonstration
# source of phoem:
#     http://gedichte.xbib.de/Goethe_gedicht_An+die+Erw%E4hlte.htm
my $anyFormat = <<PHOEM;
!h! Goethe: An die Erwählte
! ! Frisch gewagt ist schon gewonnen,
!i! Halb ist schon mein Werk vollbracht!
! ! Sterne leuchten mir wie Sonnen,
!b! Nur dem Feigen ist es Nacht.

typo
!U! unknown command
PHOEM

# use the plugins interface to convert
my $mobiFormat = $plugin->parse($anyFormat);

# let's see the result
say "---BEGIN---OUTPUT---";
say $mobiFormat;
say "---END---- OUTPUT---";

# and save it to disc, to look at it in a browser
open my $fh, '>MHTML.html';
print $fh $mobiFormat;
close $fh;
say 'saved in file: MHTML.html';

