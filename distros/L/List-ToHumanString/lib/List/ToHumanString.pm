package List::ToHumanString;

use 5.006;
use strict;
use warnings;

our $VERSION = '1.003001'; # VERSION

require Exporter;
our @ISA         = qw(Exporter);
our @EXPORT      = qw(to_human_string);
our $Extra_Comma = 1;
our $Separator   = '|';

sub _combine_list_to_string {
    my @list = @_;

    @list = grep defined && /\S/, @list;

    if ( not @list ) {
        return '';
    }
    elsif ( @list == 1 ) {
        return "$list[0]";
    }
    elsif ( @list == 2 ) {
        return "$list[0]" . ' and ' . "$list[1]";
    }
    else {
        return join ', ', map "$_",
            $Extra_Comma
            ? ( @list[0..$#list-1], 'and ' . $list[-1] )
            : ( @list[0..$#list-2], $list[-2] . ' and ' . $list[-1] )
    }
}

sub to_human_string {
    my ( $string, @list ) = @_;

    @list = grep defined && /\S/, @list;

    my $replacement_index = ( @list == 1 ? 0 : 1 );
    $string=~
    s%
        { ( [^}]*  \Q$Separator\E  [^}]* ) }
    %
        ( split /\Q$Separator\E/, $1, 2 )[ $replacement_index ];
    %gex;

    my $re = qr/\Q$Separator\Elist\Q$Separator\E/;
    if ( $string =~ /$re/ ) {
        my $human_list = _combine_list_to_string( @list );
        $string =~ s/$re/$human_list/g;
    }

    return $string;
}


1;

__END__

=encoding utf8

=head1 NAME

List::ToHumanString - write lists in strings like a human would

=head1 SYNOPSIS

=for html  <div style="display: table; height: 91px; background: url(http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/section-code.png) no-repeat left; padding-left: 120px;" ><div style="display: table-cell; vertical-align: middle;">

    use List::ToHumanString;

    print to_human_string "Report{|s} for |list|\n", qw/March May July/;
    ## Prints "Reports for March, May, and July";

    print to_human_string "Report{|s} for |list|\n", qw/March July/;
    ## Prints "Reports for March and July";

    print to_human_string "Report{|s} {is|are} needed for |list|\n", qw/March/;
    ## Prints "Report is needed for March";

=for html  </div></div>

=head1 DESCRIPTION

Provides a way to make it easy to prepare a string containing
a list of items, where that string is meant to be read by a human.

=head1 SEE ALSO

L<Lingua::Conjunction> -- You might find L<Lingua::Conjunction>
more apt at joining the list of things, if that's the only
thing that you're after.

=head1 EXPORTS BY DEFAULT

=head2 C<to_human_string>

    print to_human_string "Report{|s} for |list|\n", qw/March May July/;
    ## Prints "Reports for March, May, and July";

    print to_human_string "Report{|s} for |list|\n", qw/March July/;
    ## Prints "Reports for March and July";

    print to_human_string "Report{|s} {is|are} needed for |list|\n", qw/March/;
    ## Prints "Report is needed for March";

    print to_human_string '|list|', qw/March May July/;
    ## Prints "March, May, and July";

    $List::ToHumanString::Separator   = '*SEP*';
    $List::ToHumanString::Extra_Comma = 0;
    print to_human_string "I have {one item*SEP*many items}: *SEP*list*SEP*", qw/Foo Bar Baz/;
    ## Prints "I have many items: Foo, Bar and Baz" (note the missing comma before "and")

B<Exported by default>. B<Takes> a string to "humanize" as the first argument
and a list of items to use.
B<Removes all undefs and empty and blank strings> before counting the
number of items in the list. If the list contains one item, chooses the
"singular" variation in the first argument's format (see below). If the list
contains any other number of items, chooses "plural" variation in the format.
Once all the substitutions have been done, B<returns> the resultant string.

=head3 first argument format

    "I have {one item|many items}"

    "I have {one item that is|many items that are} |list|"

    "I have item{|s}: |list|"

    "I have {a|} thing{|s}"

    $List::ToHumanString::Separator = '::SEP::';
    "I have {one item::SEP::many items}: ::SEP::list::SEP::",

=head3 singular/plural

C<to_human_string()> will replace any occurence of C<{singularSEPARATORplural}>
with either the C<"singular"> or C<"plural"> texts, depending on the number of
items in the list given to it. The C<"singular"> and C<"plural"> texts can
be any text (even empty string) that doesn't have a C<SEPARATOR> in it.
The C<SEPARATOR>
is the value of C<$List::ToHumanString::Separator>, which B<by default>
is a pipe character (C<|>). Regex special characters in the C<SEPARATOR>
have no effect.

=head3 humanized list

    "I have item{|s}: |list|"

    "I have {one item::SEP::many items}: ::SEP::list::SEP::",

You can automatically insert a "humanized" list of items into your string
by using word C<list> set off be C<SEPARATOR> string on each side.
That string will be replaced by a "humanized" way to write the
list of items you provided, which is as follows:

=head4 empty list of items

    to_human_string('|list|',);
    # returns ''

Humanized string will be: empty string.

=head4 1-item list of items

    to_human_string('|list|', 'foo');
    # returns 'foo'

    to_human_string('|list|', URI->new("http://example.com") );
    # returns 'http://example.com'

Humanized string will be: the item itself (stringified).

=head4 2-item list of items

    to_human_string('|list|', 'foo', 'bar');
    # returns 'foo and bar'

Humanized string will be: the two items joined with C<' and '>

=head4 list with 3 or more items

    to_human_string('|list|', 'foo', 'bar', 'ber', 'baz');
    # returns 'foo, bar, ber, and baz'

    $List::ToHumanString::Extra_Comma = 0;
    to_human_string('|list|', 'foo', 'bar', 'ber', 'baz');
    # returns 'foo, bar, ber and baz'

Humanized string will be: the list of items in the list you provided
joined with C<', '> (comma and space).
The last element is also preceded by word C<'and '>. B<Note:> depending
on your stylistic preference, you might wish not to have a comma before
the last element. You can accomplish that by setting
C<$List::ToHumanString::Extra_Comma> to zero.

=head1 VARIABLES

=head2 C<$List::ToHumanString::Separator>

    my @items = ( 1..10 );
    $List::ToHumanString::Separator = '::SEP::';
    print to_human_string "I have {one item::SEP::many items} {foo|bar}\n", @items;
    ## Prints "I have many items {foo|bar}"

B<Takes> any non-empty string as a value.
B<Specifies> what separator to use between the "singular" and "plural" texts
in the string given to C<to_human_string()>.
B<Defaults to:> C<|> (a pipe character)

=head2 C<$List::ToHumanString::Extra_Comma>

    $List::ToHumanString::Extra_Comma = 0;
    to_human_string('|list|', 'foo', 'bar', 'ber', 'baz');
    # returns 'foo, bar, ber and baz'

B<Takes> true or false values as a value.
B<Specifies> whether to use a comma after the penultimate element in the
list when using C<to_human_string()> to insert humanized list into the
string. If set to a true value, the comma
will be used. B<Defaults to:> C<1> (true value).

=for html <div style="background: url(http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/hr.png);height: 18px;"></div>

=head1 REPOSITORY

=for html  <div style="display: table; height: 91px; background: url(http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/section-github.png) no-repeat left; padding-left: 120px;" ><div style="display: table-cell; vertical-align: middle;">

Fork this module on GitHub:
L<https://github.com/zoffixznet/List-ToHumanString>

=for html  </div></div>

=head1 BUGS

=for html  <div style="display: table; height: 91px; background: url(http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/section-bugs.png) no-repeat left; padding-left: 120px;" ><div style="display: table-cell; vertical-align: middle;">

To report bugs or request features, please use
L<https://github.com/zoffixznet/List-ToHumanString/issues>

If you can't access GitHub, you can email your request
to C<bug-list-tohumanstring at rt.cpan.org>

=for html  </div></div>

=head1 AUTHOR

=for html  <div style="display: table; height: 91px; background: url(http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/section-author.png) no-repeat left; padding-left: 120px;" ><div style="display: table-cell; vertical-align: middle;">

=for html   <span style="display: inline-block; text-align: center;"> <a href="http://metacpan.org/author/ZOFFIX"> <img src="http://www.gravatar.com/avatar/328e658ab6b08dfb5c106266a4a5d065?d=http%3A%2F%2Fwww.gravatar.com%2Favatar%2F627d83ef9879f31bdabf448e666a32d5" alt="ZOFFIX" style="display: block; margin: 0 3px 5px 0!important; border: 1px solid #666; border-radius: 3px; "> <span style="color: #333; font-weight: bold;">ZOFFIX</span> </a> </span>

=for text Zoffix Znet <zoffix at cpan.org>

=for html  </div></div>

=head1 LICENSE

You can use and distribute this module under the same terms as Perl itself.
See the C<LICENSE> file included in this distribution for complete
details.

=cut