# A package to sanitize HTML in order to ease comparison between multiple tools.

package HtmlSanitizer;

use strict;
use warnings;
use utf8;
use feature ':5.24';

use Exporter 'import';

our @EXPORT = qw(sanitize_html);


my $html_tag_name_re = qr/[a-zA-Z][-a-zA-Z0-9]*/;
my $html_attribute_name_re = qr/[a-zA-Z_:][-a-zA-Z0-9_.:]*/;
my $html_space_re = qr/\n[ \t]*|[ \t][ \t]*\n?[ \t]*/;  # Spaces, tabs, and up to one line ending.
my $opt_html_space_re = qr/[ \t]*\n?[ \t]*/;  # Optional spaces.
my $html_attribute_value_re = qr/ [^ \t\n"'=<>`]+ | '[^']*' | "[^"]*" /x;
my $html_attribute_re =
    qr/ ${html_space_re} ${html_attribute_name_re} (?: ${opt_html_space_re} = ${opt_html_space_re} ${html_attribute_value_re} )? /x;

my $html_open_tag_re = qr/ ${html_tag_name_re} ${html_attribute_re}* ${opt_html_space_re} \/? /x;
my $html_close_tag_re = qr/ \/ ${html_tag_name_re} ${opt_html_space_re} /x;


# The sanitizing here is quite strict (it only removes new lines happening just
# before or after an HTML tag), so this forces our converter to match closely
# what the cmark spec has (I guess it’s not a bad thing).
# In addition, this light-weight normalization did uncover a couple of bugs that
# were hidden by the normalization done by the cmark tool.
sub  sanitize_html {
  my ($html) = @_;
  while ($html =~ m/<code>|(?<new_line>(?<=>)\s*\n+\s*(?=.)|\s*\n+\s*(?=<))/g) {
    if ($+{new_line}) {
      my $p = pos($html);
      substr $html, $-[0], $+[0] - $-[0], '';
      pos($html) = $p - length($+{new_line});
    } else {
      $html =~ m/<\/code>|$/g;
    }
  }
  $html =~ s/( < (?: \/[a-z]+ | input ) >)/$1\n/gx;
  $html =~ s/\n\n+$/\n/;
  return $html;
}
