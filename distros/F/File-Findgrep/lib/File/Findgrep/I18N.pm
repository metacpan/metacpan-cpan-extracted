
package File::Findgrep::I18N;
  # This is the project base class for "findgrep", an example application
  # using Locale::Maketext;

use Locale::Maketext 1.01;
use base ('Locale::Maketext');

# I decree that this project's first language is English.

%Lexicon = (
  '_AUTO' => 1,
  # That means that lookup failures can't happen -- if we get as far
  #  as looking for something in this lexicon, and we don't find it,
  #  then automagically set $Lexicon{$key} = $key, before possibly
  #  compiling it.
  
  # The exception is keys that start with "_" -- they aren't auto-makeable.



  '_USAGE_MESSAGE' => 
   # an example of a phrase whose key isn't meant to ever double
   #  as a lexicon value
\q{
Usage:
 findgrep [switches] line-pattern [filename-pattern [dirnames...]]
Switches:
 -R   recurse
 -m123   minimum filesize in bytes   (default: 0)
 -m123K  minimum filesize in kilobytes
 -m123M  minimum filesize in megabytes
 -m123G  minimum filesize in gigabytes
 -M123   maximum filesize in bytes   (default: 10 million)
 -M123K  maximum filesize in kilobytes
 -M123M  maximum filesize in megabytes
 -M123G  maximum filesize in gigabytes
 -h      exit, displaying this message
 --      signal end of switches
 
Line-pattern should be a regexp that matches lines.
Filename-pattern should be a regexp that matches basenames.
  If not specified, uses all filenames not starting with a dot.
Dirnames should be list of directories to search in.
  If not specified, uses current directory.
Example:
  findgrep -R '\bgr[ea]y\b' '\.txt$' ~/stuff
},


  # Any further entries...

);
# End of lexicon.



1;  # End of module.

