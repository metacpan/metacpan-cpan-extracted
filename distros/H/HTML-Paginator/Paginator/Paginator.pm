package HTML::Paginator;
use strict;

# Preloaded methods go here.

sub new {
    my $pkg = shift or return undef;
    my $obj = { html=>{ pre_cap => '',
                        end_cap => '',
                        previous_icon => '&lt;&lt; ',
                        next_icon => ' &gt;&gt;',
                        singular => '',
                        plural => 's',
			item_name => 'result',
			seperator => ' | ',
                        href_link => $ENV{REQUEST_URI} }};
    bless $obj, ref $pkg || $pkg;
    $obj->_Prep_HTML_Text;
    if ($obj->{html}->{href_link} =~ /&page\=\d+&/) {
        $obj->{html}->{href_link} =~ s/&page\=\d+&/&/g;
	$obj->{html}->{href_link} .= '&page=';
    }
    elsif ($obj->{html}->{href_link} =~ /\?page\=\d+&/) {
        $obj->{html}->{href_link} =~ s/\?page\=\d+&//g;
	$obj->{html}->{href_link} .= '&page=';
    }
    elsif ($obj->{html}->{href_link} =~ /&page\=\d+$/) {
        $obj->{html}->{href_link} =~ s/&page\=\d+$//g;
	$obj->{html}->{href_link} .= '&page=';
    }
    elsif ($obj->{html}->{href_link} =~ /\?page\=\d+$/) {
        $obj->{html}->{href_link} =~ s/\?page\=\d+$//g;
	$obj->{html}->{href_link} .= '?page=';
    }
    elsif ($obj->{html}->{href_link} =~ /\?/) {
        $obj->{html}{href_link} .= '&page=';
    }
    else {
        $obj->{html}{href_link} .= '?page=';
    }
    $obj->{num_per_page} = shift
      and $obj->{num_per_page} > 0
       or return undef; # must have at least one item per page
    $obj->{book} = \@_;
    $obj->_Ginsoo;
    return $obj;
}

sub _Ginsoo {
    my ($obj, @array);
    $obj = shift and ref $obj and @array = @{$obj->{book}} or return undef;
    $obj->{total} = scalar @array; # store total in array
    my $i = 0;
    while (my @slice = splice @array, 0, $obj->{num_per_page}) {
        push @{$obj->{page}}, \@slice; # one slice per page
        $i++
    }
    $obj->{num_pages} = $i;
}

sub _Set_HTML_Text {
    my $obj;
    $obj = shift and ref $obj or return undef;
    my $what = shift or return undef;
    my $new_name = shift;
    defined $new_name or return undef;
    $obj->{html}->{$what} = $new_name;
    return $obj->_Prep_HTML_Text;
}

sub _Prep_HTML_Text {
    my $obj;
    $obj = shift and ref $obj or return undef;
    $obj->{html}->{previous_text} = "Last %d $obj->{html}->{item_name}%s";
    $obj->{html}->{next_text} = "Next %d $obj->{html}->{item_name}%s";
    return 1;
}

sub Name_Item {
    my $obj;
    $obj = shift and ref $obj or return undef;
    return $obj->_Set_HTML_Text('item_name', shift);
}

sub Set_Plural {
    my $obj;
    $obj = shift and ref $obj or return undef;
    return $obj->_Set_HTML_Text('plural', shift);
}

sub Set_Singular {
    my $obj;
    $obj = shift and ref $obj or return undef;
    return $obj->_Set_HTML_Text('singular', shift);
}

sub Contents {
    my ($obj, $page);
    $obj = shift
      and ref $obj
      and $page = shift
      and $page > 0
       or return undef;
    $page--;
    return exists $obj->{page}->[$page]?
             @{$obj->{page}->[$page]}:
             ();
}

sub Next { # next page index is current page number
    my $obj;
    $obj = shift and ref $obj or return undef;
    return $obj->_Item_Count(shift);
}

sub Previous { # previous page index is two less than page number
    my $obj;
    $obj = shift and ref $obj or return undef;
    return $obj->_Item_Count(shift(@_) - 2);
}

sub Item_Count { # current page is one less than page number
    my $obj;
    $obj = shift and ref $obj or return undef;
    return $obj->_Item_Count(shift(@_) - 1);
}


sub _Item_Count {
    my $obj;
    $obj = shift and ref $obj or return undef;

    my $page = shift;
    $page > -1 or return undef; # no negative page numbers
    return exists $obj->{page}->[$page]?
      scalar @{$obj->{page}->[$page]}:
      0;
}

sub Page_Count {
    my $obj;
    $obj = shift and ref $obj or return undef;
    return scalar @{$obj->{page}};
}

sub First_Item {
    my $obj;
    $obj = shift and ref $obj or return undef;
    my $page = shift;
    $page > 0 or return undef;
    $page--;
    return undef unless $obj->_Item_Count($page);
    return ($obj->{num_per_page} * $page) + 1;
}

sub Last_Item {
    my $obj;
    $obj = shift and ref $obj or return undef;
    my $page = shift;
    $page > 0 or return undef;
    $page--;
    return undef unless $obj->_Item_Count($page);
    return ($obj->{num_per_page} * $page) + scalar $obj->_Item_Count($page);
}

sub Page_Header_HTML {
    my ($obj, $page);
    $obj = shift and ref $obj and $page = shift and $page > 0
      or return "[An error occurred while forming the page header]";
    $obj->{html}->{previous_text} = "Last %d $obj->{html}->{item_name}%s";
    $obj->{html}->{next_text} = "Next %d $obj->{html}->{item_name}%s";
    if ($obj->Page_Count > 1) { # Case more than one page
        return sprintf <<"eohtml",
%s%s %d to %d of %d (Page $page of %d)
eohtml
                       ucfirst $obj->{html}->{item_name},
                       $obj->{html}->{plural},
                       $obj->First_Item($page),
                       $obj->Last_Item($page),
                       $obj->{num_per_page} * ($obj->Page_Count - 1)
		        + $obj->_Item_Count($obj->Page_Count-1),
                       $obj->Page_Count;
    }
    elsif ($obj->_Item_Count($page-1) == 1) { # Case one page one item
        return sprintf <<"eohtml",
The only %s%s
eohtml
                       $obj->{html}->{item_name},
		       $obj->{html}->{singular};
    }
    elsif ($obj->_Item_Count($page-1) == 0) { # Case no items
        return sprintf <<"eohtml",
No %s%s
eohtml
                       $obj->{html}->{item_name},
		       $obj->{html}->{plural};
    }
    else { # Case one page multiple items
        return sprintf <<"eohtml",
All %d %s%s
eohtml
                       $obj->_Item_Count($page-1),
		       $obj->{html}->{item_name},
		       $obj->{html}->{plural};
    }
}

sub Page_Nav_HTML {
    my ($obj, $page);
    $obj = shift and ref $obj and $page = shift and $page > 0
       or return "[An error occured while forming the page count]";
    $obj->{html}->{previous_text} = "Last %d $obj->{html}->{item_name}%s";
    $obj->{html}->{next_text} = "Next %d $obj->{html}->{item_name}%s";
    my $p_cap = $obj->{html}->{pre_cap};
    my $n_cap = $obj->{html}->{end_cap};
    my $p_icon = $obj->{html}->{previous_icon};
    my $n_icon = $obj->{html}->{next_icon};
    my $p_count = $obj->Previous($page);
    my $n_count = $obj->Next($page);
    my $p_page = $page - 1;
    my $n_page = $page + 1;
    my $p_text = sprintf $obj->{html}->{previous_text},
                         $p_count,
                         $p_count == 1?
                           $obj->{html}->{singular}:
                           $obj->{html}->{plural};
    my $n_text = sprintf $obj->{html}->{next_text},
                         $n_count,
                         $n_count == 1?
                           $obj->{html}->{singular}:
                           $obj->{html}->{plural};
    my $link = $obj->{html}->{href_link};
    my $sep = $obj->{html}->{seperator};
    my $nav_html = sprintf <<"eohtml",
$p_cap%s%s%s$n_cap
eohtml
      $p_count?
        "<a href=\"$link$p_page\">$p_icon$p_text</a>":
        '',
      $p_count && $n_count?
        $sep:
        '',
      $n_count?
        "<a href=\"$link$n_page\">$n_text$n_icon</a>":
	'';
    return $nav_html;
}

1;
__END__

=head1 NAME

HTML::Paginator - Object-Oriented Pagination for Web Applications

=head1 SYNOPSIS

  use CGI;
  use HTML::Paginator;

  my $cgi = new CGI;
  my $page = $cgi->param('page') || 1;

  my @items = (1..67);
  
  my $book = HTML::Paginator->new(25,@items);
  $book->Name_Item('random item');
  @items = $book->Contents($page);

  print "<html>\n  <head>\n  <title>Sample Script</title>\n  ",
        "</head>\n</html>";
  # it bugs me that people use CGI methods for stuff like that 
  #   above. Gaaah.
  print "<body>\n",
        $cgi->h2($book->Page_Header_HTML($page)),
        "<ul>\n";
  print "  </li>$_</li>\n" for @items;
  print "</ul>\n",
        $book->Page_Nav_HTML($page),
	"</body>\n</html>\n";


=head1 DESCRIPTION

HTML::Paginator is an Object-Oriented module intended to make pagination of
large lists easy. Using an amazing (or amazingly simple) internal method, it
takes your favourite array and it slices, it dices, and it makes Julien Fries
out of your array.

It's an HTML module because that's where it's most useful. However, a small
amount of finagling can make it useful for any interface, really.

=head1 Instantiation

You create a Paginator object, which I'm calling a 'book' for lack of a better
term, by calling the new($@) method, like is done with most OO modules.

new takes two or more arguments: the first is the number of items you want per
page. The second and all following are the items you want sliced up into
seperate pages. For instance, you could pull the results of a SQL query in
to be sliced up, and display 10 per page:

  my @stuff;
  while (my $row = $my_query->fetchrow_hashref) {
      push @stuff, $row;
  }

  my $book = HTML::Paginator->new(10, @stuff);

  for my $row ($book->Contents($page) {
      print $row->{column_to_print};
  }


It's that easy.

Of course, if your database is slow, or you have a huge number of results,
you don't want to pull down all of them first. I recommend getting a count,
using paginator to slice *that* up, and then working a little programmer
magic to get back only the slice of the table you want (Oracle would let
you use rownum, while with MySQL you might have to work harder, doing a few
small queries to whittle things to where you want them).

Then again, who says you're using a database? You could even use this to
paginate a huge text document in an external file, with a while(<>) and a
counter scalar, maybe. Ahh, this is all your job. I did the slicing.

As a note, HTML::Paginator acts like it thinks in terms of 1-indexed arrays.
It doesn't, really. It just pretends to with its public methods. This is
because while we all know that arrays should be zero-indexed, the user doesn't,
and seeing page=0 in their URL looks goofy to them. So we're nice to them.
They won't thank you because the web is full of ungrateful bastards, but you
can feel nicer about yourself for knowing you were nice to a bastard. Or
something.

=head1 Public Methods

Several nice convenience methods are supplied, so you can make the module
do the thinking and you can back to drinking... or whatever. Hey, it rhymed.

=over 4

=item new($@) (constructor)

As stated above, this creates a new Paginator object and slices it up into
little pieces (or big pieces, as you prefer). It takes 2 or more arguments:
the number of items per page, and the array or list (not an arrayref, BTW.
Dereference any arrays you intend to hand to this first (or en passe)). For
instance:

  my $book = HTML::Paginator(25, @array);

or perhaps

  my $book = HTML::Paginator->new(100, @{$object->{arrayref}});

=item Name_Item($)

Takes any string and makes that the internal name for whatever you're chopping
up a list of. The default is 'result'. For instance, if you have a list of
kittens for sale, you would call:

  $book->Name_Item('kitten');

=item Set_Plural($)

Takes any string and makes that the plural-iser for the item name. The default
is 's'. For instance, if you'd set the item name to 'child' with Name_Item,
you would want to set the plural correctly, so that it didn't consider more
than one to be 'childs':

  $book->Set_Plural('ren');

=item Set_Singular($)

Like Set_Plural above, sets the singular. The default is '' (empty string).
You may want to set the singular when the word changes form based on plurality.
For instance, if you were strange enough to list octopi (that's the plural
for 'octopus'), you would want to set the name to the least common denominator,
and set the plural and singular forms:

  $book->Name_Item('octop');
  $book->Set_Singular('us');
  $book->Set_Plural('i');

While you can, theoretically, set the name to '' and the Singular and Plural
forms to be the entire words:

  $book->Name_Item('');
  $book->Set_Singular('mouse');
  $book->Set_Plural('mice');

I don't recommend it, because there is, in one of the two convenience methods,
a case where the item name is ucfirst-ed. This will miss this case.

=item Contents($)

This method takes the current page number as an argument. It returns the slice
of the array or list you handed it corresponding to the page number.

This is the method that is most important and useful to this whole thing,
really.

=item Next($)

Next takes a page number as an argument and returns the number of items in the
*following* page. So if you slice up 67 items, page 6 will have items 51-60, and
page 7 will have items 61-67. Thus, if you call:

  my $page7_items = $book->next(6);
  
Your $page7_items will be set to 7. Of course, you can feel free to use this
for it's boolean value as well. I do.

=item Previous($)

Similar to Next above, this method returns the number of items in the page
BEFORE the page number given in the argument. This is really only useful for
its boolean value, however, as the only way to get a different number than
the number of pages you set is to ask for page 1 (which will return 0), or
a page outside of the page list (i.e. number of pages+1 will return the number
of items in the last page, while number of pages +2 will return 0).

=item Item_Count($)

Quite similar to the Next and Previous methods above, Item_Count returns the
numbe of items in the current page. This is useful for finding out if there are
any items at all (a boolean use) or just any old use you feel like putting it
to. Of course, its argument is the page being referred to.

=item Page_Count()

This method returns the total number of pages in the 'book'. It takes no
arguments at all. All it does is return the scalar value of @{$book->{page}},
the internal arrayref.

=item First_Item($)

This useful litle method returns the 1-indexed number of the first item in the
current page as it equates to all of the items in the original list. It takes
a page number as an argument. Assuming you haven't changed the default array
index or gotten rid of the original array, ($book->Content($page))[0] will
always match @original_array[$book->First($page)-1]. Using whatever names.

=item Last_Item($)

Like First_Item above, this returns the 1-indexed number of the *last* item
in the current page slice as it associates with the original array. Again,
it takes a page number as an argument.

=item Page_Header_HTML($)

This super cool method takes a page number as an argument, and returns a nicely
formatted sentence telling you where you are in the 'book'. The results look
like:

  Results 51 to 60 of 67 (Page 6 of 7)

Isn't that nice? Of course, if you have set Name_Item to 'g' and Set_Plural to
'eese', it will say:

  Geese 51 to 60 of 67 (Page 6 of 7)

And if you did the thing with mouse/mice that I said not to, it will say:

  mice 51 to 60 of 67 (Page 6 of 7)

With 'mice' in lowercase, which is why I said 'don't do that.'

If it's called wrong it tells you (via its return) in a square-bracketed
SSI-esque sort of way.

=item Page_Nav_HTML($)

Another really cool method, this also takes a page number as an argument (is
that part getting redundant or is it just me?) and returns a spiffy-cool
formatted HTML link for each page forward or back (with 'page' as the CGI
parameter name that looks like so:

  <a href="your_url?page=1">Last 10 items</a> | <a href="your_url?page=3"> Next 6 items</a>

or whatever. Again, setting the item name and plurality stuff changes the
appearance. There is also some stuff below for property setting. Um, sorry,
you can't change the cgi parametre name yet -- look for a later version. I just
thought of that as I was writing this POD.

One of the cool things about this is that it actually preserves any other
arguments in the query string, but replaces its page number (and sticks it
at the end). This way you can use it with other arguments at the same time. As
long as they aren't 'page' (hey, I can't think of everything off the bat!)

If it fails it returns a square bracketed message telling you it failed. This
means you called it wrong (i.e. you gave it a silly page number like -1 or 0,
or you didn't give it a page number, or you tried to call it as a sub instead
of a method, or whatever.)

=back

=head1 Private Methods

=over 4

=item _Ginsoo

This method does all the work, chopping and slicing like one of those crazy
chefs at Benihana.

=item _Set_HTML_Text

This does the work of setting your plurals and stuff.

=item _Prep_HTML_Text

This resets things based on html text you may have changed

=item _Item_Count

This does what the public method Item_Count does, but it takes a 0-indexed
subarray index rather than a 'page number'. Thus for page 1, you ask for 0.
Actually, you don't -- use the public methods.

=back

=head1 Properties

=over 4

=item html properties

The object has a hashref of properties keyed by 'html' inside it. This is
set by the Name_Item and Set_Plural/Singular methods. You get to these with:

  $book->{html}->{<key_name>}


You can, if you really need to, mess around with these. They are as follows:

  pre_cap: The thing that begins the HTML navigation tag.
           Default empty string.
  end_cap: The thingy on the other end. Default empty string.
  previous_icon: a thingy pointing left. You can replace this
                 with an image tag or something if you want.
		 Default '&lt;&lt;' (<<)
  next_icon: As above with previous icn, but pointing right.
             Default '&gt;&gt;' (>>)
  singular: what you set with Set_Singular. Default ''
  plural: what you set with Set_Plural. Default 's'
  item_name: what you set with Name_Item. Default 'result'
  seperator: a thingy between direction links if there are two.
             Default ' | '
  href_link: the URL to link to. Defaults to $ENV{REQUEST_URI}
             whatever that is. If you have to change this,
	     remember that the CGI parametre name for the page
	     rests here, not in the place where the number is
	     filled in. Actually, you can always
	     s/page/your_param_name/ here to change the parametre
	     name the hard way.
  previous_text: A sprintf template to point at the prior page.
                 Don't break the template if you feel you must
		 change it.
		 Default "Last %d $obj->{html}->{item_name}%s"
  next_text: As above.
             Default "Next %d $obj->{html}->{item_name}%s"

=item num_per_page

You can change the num_per_page if you want, though you will have to call
the private method _Ginsoo to reslice. The num_per_page property is:

  $book->{num_per_page}

=item book

This is where the original array is stored. Note that is IS kept around. After
the object is created you can remove it if you have to, and you can use this
property if you suddenly change your mind in a fit of boredom. For instance,
if you decide you want to slice up different stuff, you can. Just set this
property to an arrayref of your choice:

  $book->{book} = \@new_array

If you have to do this, remember to call $book->_Ginsoo before you expect it
to do anything, really.

=back

=head1 GOOD INTENTIONS

- Add an easy way to set the CGI parametre name.

- Add the option of giving it a negative number as the first argument,
  and use that to slice for a given number of pages with whatever number
  per page, instead.
  
- Methods to set words like 'Last' and 'Next' for easy locale changing.

- A 'goooooooogle' style Page Navigation bar, maybe.

=head1 AUTHOR

Dodger - dodger@dodger.org

=head1 WEBSITE

http://www.perl5cgi.com

=head1 SEE ALSO

perl(1).

=cut
