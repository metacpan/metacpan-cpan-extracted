package EBook::MOBI::Converter;

our $VERSION = '0.72'; # VERSION (hook for Dist::Zilla::Plugin::OurPkgVersion)

use strict;
use warnings;

use HTML::Entities;

#############################
# Constructor of this class #
#############################

sub new {
    my $self    = shift;
    my $ref = {};

    bless($ref, $self);

    return $ref;
}

sub text {
    my $self = shift;
    my $txt  = shift;

    #we have to make sure that HTML entities get encoded
    my $mhtml = encode_entities($txt);

    return $mhtml;
}

sub title {
    my $self = shift;
    my $txt  = shift;
    my $lvl  = shift;
    my $toc  = shift;

    # default values for lvl and toc (issue #31 on github)
    unless( defined $lvl ) {
        $lvl = 1;
    }
    unless( defined $toc ) {
        $toc = 1;
    }

    die("Titles can't be higher than level 6\n") if ($lvl > 6);

    my $mhtml = '';
    
    if ($toc) {
        $mhtml = "<h$lvl>$txt</h$lvl>\n";
    }
    else {
        # If the h1 (or any other level) should not appear in the TOC
        # we put a whitespace in front of it.
        # Like this the regex of the TOC generator does not find it.
        $mhtml = " <h$lvl>$txt</h$lvl> <!-- not in TOC -->\n";
    }

    return $mhtml;
}

sub paragraph {
    my $self = shift;
    my $txt  = shift;

    my $mhtml = "<p>$txt</p>\n";

    return $mhtml;
}

sub newline {
    my $self = shift;

    my $mhtml = "<br />\n";

    return $mhtml;
}

sub pagebreak {
    my $self = shift;

    my $mhtml = "<mbp:pagebreak />\n";

    return $mhtml;
}

sub italic {
    my $self = shift;
    my $txt  = shift;

    my $mhtml = "<i>$txt</i>";

    return $mhtml;
}

sub bold {
    my $self = shift;
    my $txt  = shift;

    my $mhtml = "<b>$txt</b>";

    return $mhtml;
}

sub code {
    my $self = shift;
    my $txt  = shift;

    my $enc_txt = _nbsp($txt);   # whitespaces
       $enc_txt =~ s/\n/<br \/>\n/g; # line breaks

    my $mhtml = "<code>$enc_txt</code>\n";

    return $mhtml;
}

sub small {
    my $self = shift;
    my $txt  = shift;

    my $mhtml = "<small>$txt</small>";

    return $mhtml;
}

sub big {
    my $self = shift;
    my $txt  = shift;

    my $mhtml = "<big>$txt</big>";

    return $mhtml;
}

sub emphasize {
    my $self = shift;
    my $txt  = shift;

    my $mhtml = "<em>$txt</em>";

    return $mhtml;
}

sub list {
    my $self      = shift;
    my $list_ref  = shift;
    my $list_type = shift || 'ul';

    my $mhtml = "<$list_type>\n";
    foreach my $item (@{$list_ref}) {

        $mhtml .= "<li>$item</li>\n";
    }
    $mhtml .= "</$list_type>\n";

    return $mhtml;
}

sub table {
    my $self      = shift;
    my %table_data = @_;

    my $table_args = '';
    if (exists $table_data{border}) {
        $table_args .= ' border="'. $table_data{border} .'"';
    }
    if (exists $table_data{cellspacing}) {
        $table_args .= ' cellspacing="'. $table_data{cellspacing} .'"';
    }
    if (exists $table_data{cellpadding}) {
        $table_args .= ' cellpadding="'. $table_data{cellpadding} .'"';
    }

    my $mhtml;
    $mhtml = "<table$table_args>\n";

    if (exists $table_data{th}) {
        my @table_header = @{$table_data{th}};

        $mhtml .= "<tr>";
        foreach my $head (@table_header) {
            $mhtml .= "<th>$head</th>";
        }
        $mhtml .= "</tr>\n";
    }

    if (exists $table_data{td}) {
        my @table_datarow = @{$table_data{td}};

        foreach my $row (@table_datarow) {
            my @table_data= @{$row};

            $mhtml .= "<tr>";
            foreach my $data (@table_data) {
                $mhtml .= "<td>$data</td>"
            }
            $mhtml .= "</tr>\n";
        }
    }

    if (exists $table_data{caption}) {
        $mhtml .= "<caption>$table_data{caption}</caption>\n";
    }

    $mhtml .= "</table>\n";

    return $mhtml;
}

sub image {
    my $self        = shift;
    my $path        = shift;
    my $description = shift || '';

    # We count the pictures, so that each has a number
    $self->{img_count} ++; 

    my $mhtml;

    # e.g.: <img src="/home/user/picture.jpg" recindex="1">
    # recindex is MOBI specific, its the number of the picture,
    # pointing into the picture records of the Mobi-format
    $mhtml =  '<img src="'  . $path . '"' 
            . ' recindex="' . $self->{img_count} .'" >'
            . "\n";

    # Then we print out the image description
    if ($description) {
        $mhtml .= "<p>$description</p>\n";
    }

    return $mhtml;
}

###################################################################

## replaces whitespace with html entitie
sub _nbsp {
    my $string = shift;

    $string =~ s/\ /&nbsp;/g;

    return $string;
}

1;

__END__

=encoding utf8

=head1 NAME

EBook::MOBI::Converter - Tool to create MHTML.

=head1 SYNOPSIS

  use EBook::MOBI::Converter;
  my $c = EBook::MOBI::Converter->new();

  my $mhtml_text = '';

  $mhtml_text .= $c->title(     $c->text('This is my Book') , 1, 0);
  $mhtml_text .= $c->paragraph( $c->text('Read my wisdome')       );
  $mhtml_text .= $c->pagebreak(                                   );

=head1 WHAT IS MHTML?

'mhtml' stands for mobi-html, which means: it is actually HTML but some things are different. I invented this term myself, so it is probably not a good idea to search the web or ask other people about this term. If you are looking for more information about this format you might search the web for 'mobipocket file format' or something similar.

If you stick to the most basic HTML tags it should be perfect mhtml 'compatible'. So if you want to 'write a book' or something similar you can just use basic HTML for markup. The ebook readers using the MOBI format actually just display plain HTML. But sadly that's not the whole truth - you can't stick to the official HTML standards. Since I did some research on how to do things, I'd like to share my knowledge.

=head2 Simple Text

Most simple HTML tags will just work.

  <h1>My Book</h1>
  <p>
  This is my first book.
  I want to show the world <b>my</b> mind!
  <br />&nbsp; -- the author
  </p>

=head2 TOC and Hyperlinks

Hyperlinks pointing to the WWW are working just like in HTML. But if you want to point into your own file, e.g. for a table of contents, it will not work. You then have to declare an attribute called 'filepos' which points to the char where you whant to jump to.

  <h1>Table of Contents</h1>
  <ul>
  <li><a filepos="00000458">CHAPTER ONE</a></li>
  <li><a filepos="00000510">CHAPTER TWO</a></li>
  </ul>

=head2 Images

Images are handled slightly different than in standard HTML, since all the data is not on a normal filesystem - it is packed into the MOBI format. Since there are no such things as filenames in the MOBI format (at least as far as I know) you can't point to an image over it's name. Images are stored in seperat format-intern containers, which have a count. You can then adress to an image with the number of it's container. The syntax is like this:

  <img recindex="0004">

Attention! If you have a lot of text, it will fill up more than one container. But even then... images always start counting from recindex one! So this count seems to be relative, not absolute. Just start counting with C<recindex="1"> and it will be fine!

=head2 New Page

If you want to enforce a new page at the ebook-reader you can use a MOBI specific tag:

  <mbp:pagebreak />

=head1 METHODS

=head2 new

=head2 text

Returns your normal text (without markup) encoded for MHTML, which means, HTML special chars get replaced with HTML entities.

This method gets not called autmotically by the other methods.
So you need to call this every time, also when using other methods, if you want to ensure that special chars are converted.

=head1 METHODS (for tags)

=head2 title

Returns your text formated as a title.
Takes 3 arguments:

 my $mobi_title = $converter->title(

    # Arguments:

        $text, # your title

        $level,# title level form 1 to 6
               # (default: 1)

        $toc   # pass false if it should not appear in the TOC
               # (default: true)
 );

=head2 paragraph

=head2 newline

=head2 pagebreak

=head2 italic

=head2 bold

=head2 code

 $mhtml = $c->code(
 'for my $i (@a) {
     print $_;
     print "the end\n";
 }
 ');

=head2 small

=head2 big

=head2 emphasize

=head2 list

Create a very simple list.

 my $mhtml = $c->list( ['A', 'B', 'C', 'D'], 'ul' );

=head2 table

Create a very simple table.

 $mhtml = $c->table(   th =>   ['A', 'B', 'C'],
                         td => [
                                ['1', '2', '3'],
                                ['10', '20', '30'],
                                ['100', '200', '300']
                               ],
                         caption     => 'This is a table',
                         border      => '8',
                         cellspacing => '10',
                         cellpadding => '20'
                     );

=head2 image

Add a picture to the data.

 $mhtml = $c->image('/path/to/pic.jpg', 'This is a picture');

Image must remain on the path at disc, until ebook is created!
This method just adds the path, not the data.

=head1 Possible Tags

According to L<mobipocket.com|http://www.mobipocket.com/dev/article.asp?BaseFolder=prcgen&File=TagRef_OEB.htm> the following tags are supported in Mobipocket. Not all are implemented in the methods mentioned above.

  <?xml?>
  <?xml-stylesheet?>
  <!--
  <!doctype>
  <a>
  <area>
  <b>
  <base>
  <big>
  <blockquote>
  <body>
  <br
  <caption>
  <center>
  <cite>
  <code>
  <dd>
  <del>
  <dfn>
  <dir>
  <div>
  <dl>
  <dt>
  <em>
  <font>
  <head>
  <h1
  <hr
  <html>
  <i>
  <img
  <ins>
  <kbd>
  <li>
  <link
  <listing>
  <map>
  <menu>
  <meta>
  <object>
  <ol>
  <p>
  <param>
  <plaintext>
  <pre>
  <q>
  <s>
  <samp>
  <small>
  <span>
  <strike>
  <strong>
  <style>
  <sub>
  <sup>
  <table>
  <td>
  <th>
  <title>
  <tr>
  <tt>
  <u>
  <ul>
  <var>
  <xmp>

=head1 COPYRIGHT & LICENSE

Copyright 2012, 2013 Boris Däppen, all rights reserved.

This program is free software; you can redistribute it and/or modify it under the same terms of Artistic License 2.0.

=head1 AUTHOR

Boris Däppen E<lt>bdaeppen.perl@gmail.comE<gt>

=cut

