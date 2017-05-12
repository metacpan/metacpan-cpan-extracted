package EBook::MOBI;

use strict;
use warnings;

our $VERSION = 0.72;

# needed CPAN stuff
use File::Temp qw(tempfile);
use Carp;

# needed local stuff
use EBook::MOBI::Driver::POD;
use EBook::MOBI::Mhtml2Mobi;

# Constructor of this class
sub new {
    my $self = shift;
    my $ref = { html_data => '',
                html_toc  => '',
                toc_label => 'Table of Contents',
                toc_set   => 0,
                toc_done  => 0,

                filename  => 'book.mobi',
                title     => 'This Book has no Title',
                author    => 'This Book has no Author',

                encoding  => ':encoding(UTF-8)',
           default_driver => 'EBook::MOBI::Driver::POD',

                CONST     => '6_--TOC-_thisStringShouldNeverOccurInInput',

                ref_to_debug_sub => 0,
            };

    bless($ref, $self);
    return $ref;
}

sub reset {
    my $self = shift;
    $self->{html_data} = '',
    $self->{html_toc } = '',
    $self->{toc_label} = 'Table of Contents',
    $self->{toc_set  } = 0,
    $self->{toc_done } = 0,

    $self->{filename } = 'book',
    $self->{title    } = 'This Book has no Title',
    $self->{author   } = 'This Book has no Author',

    $self->{encoding } = ':encoding(UTF-8)',
$self->{default_driver}= 'EBook::MOBI::Driver::POD',

    $self->{CONST    } = '6_--TOC-_thisStringShouldNeverOccurInInput',

    $self->{ref_to_debug_sub} = 0,
}

sub debug_on {
    my ($self, $ref_to_debug_sub) = @_;

    $self->{ref_to_debug_sub} = $ref_to_debug_sub;
    
    &$ref_to_debug_sub('DEBUG mode on');
}

sub debug_off {
    my ($self) = @_;

    if ($self->{ref_to_debug_sub}) {
        &{$self->{ref_to_debug_sub}}('DEBUG mode off');
        $self->{ref_to_debug_sub} = 0;
    }
}

# Internal debug method
sub _debug {
    my ($self,$msg) = @_;

    if ($self->{ref_to_debug_sub}) {
        &{$self->{ref_to_debug_sub}}($msg);
    }
}

sub set_title {
    my $self = shift;

    $self->{title} = shift;
}

sub set_author {
    my $self = shift;

    $self->{author} = shift;
}

sub set_filename {
    my $self = shift;

    $self->{filename} = shift;
}

sub set_encoding {
    my $self = shift;
    my $encoding = shift;

    if (! $self->_encoding_to_codepage($encoding))
    {
        croak "Encoding $encoding is not supported by EPub::MOBI";
    }

    $self->{encoding} = $encoding;
}

sub _encoding_to_codepage
{
    # Translate a Perl encoding name into a codepage value or return
    # undef if not supported.

    my $self = shift;
    my $encoding = shift;

    if ($encoding =~ /iso-8859-1|ascii/i)
    {
        return 1252;
    }
    elsif ($encoding =~ /utf-*8/i)
    {
        return 65001;
    }
    else
    {
        return undef;
    }
}

sub add_mhtml_content {
    my ($self, $html) = @_;

    $self->{html_data} .= $html;
}

sub add_content {
    my $self = shift;
    my %args = @_;
    
    my $data       = $args{data}       || 0;
    my $pagemode   = $args{pagemode}   || 0;
    my $head0_mode = $args{head0_mode} || 0;
    my $driver     = $args{driver}     || $self->{default_driver};
    my $driver_opt = $args{driver_options} || 0;

    # we load a plugin to convert the input to mobi format
    my $parser;
    (my $require_name = $driver . ".pm") =~ s{::}{/}g;
    eval {
        require $require_name;
        $parser = $driver->new();
    };
    die "Problems with plugin $driver at $require_name: $@" if $@;

    # pass some settings
    if ($self->{ref_to_debug_sub}) {
        $parser->debug_on($self->{ref_to_debug_sub});
    }
    if ($driver_opt) {
        $parser->set_options($driver_opt);
    }

    my $output = $parser->parse($data);

    $self->{html_data} .= $output;
}

sub add_pagebreak {
    my ($self) = @_;

    $self->{html_data} .= '<mbp:pagebreak />' . "\n";
}

sub add_toc_once {
    my ($self, $label) = @_;

    $self->{toc_label} = $label if $label;
    $self->{toc_set} = 1;
    $self->{html_data} .= $self->{CONST};
    # this newline is needed, otherwise the generation of the toc will
    # not recognise the first <h1> in the split function
    $self->{html_data} .= "\n";
}

sub make {
    my ($self) = @_;

    if (exists $self->{toc_set} and $self->{toc_set}) {
        $self->_generate_toc();
    }
    else {
        my $tmp = $self->{html_data};
    $self->{html_data} = "<html>
<head>
</head>
<body>
" . $tmp . "</body>\n</html>\n";
    }
}

sub print_mhtml {
    my ($self, $arg) = @_;

    unless ($arg) {
        print $self->{html_data};
    }

    return $self->{html_data};
}

sub save {
    my ($self) = @_;

    my $mobi = EBook::MOBI::Mhtml2Mobi->new();
    $mobi->debug_on($self->{ref_to_debug_sub})
        if ($self->{ref_to_debug_sub});

    my $codepage = $self->_encoding_to_codepage($self->{encoding});

    $mobi->pack(    $self->{html_data},
                    $self->{filename},
                    $self->{author},
                    $self->{title},
                    $codepage,
                    $self->{header_opts}, 
                );
}

sub _generate_toc {
    my $self = shift;

    if (exists $self->{toc_done} and $self->{toc_done}) {
        $self->_debug(
            'Skipping generation of TOC, has been done earlier.');

        return 1;
    }
    else {
        $self->_debug("generating TOC...");
        $self->{toc_done} = 1;
    }

    foreach my $line (split("\n", $self->{html_data})) {
        # The <h1> is only added to TOC if it is at the beginning of a line
        # and if there is a newline directly following afterwards
        if ($line =~ m/^<h1>(.*)<\/h1>$/) {
            $self->{html_toc} .=
                "<li><a filepos=\"00000000\">$1</a></li><!-- TOC entry -->\n";
        }
    }

    my $toc  = "<h1>$self->{toc_label}</h1><!-- TOC start -->\n";
       $toc .= "<p><ul>\n$self->{html_toc}<\/ul><\/p>\n";

    $self->{html_data} =~ s/$self->{CONST}/$toc/;

    my $tmp = $self->{html_data};
    $self->{html_data} = "<html>
<head>
<guide>
<reference type=\"toc\" title=\"$self->{toc_label}\" filepos=\"00000000\"/>
</guide>
</head>
<body>
" . $tmp . "</body>\n</html>\n";

    # now we need to calculate the positions for "filepos"
    my $chars = 0;
    my $data_copy = $self->{html_data};
    foreach my $line (split("\n", $data_copy)) {

        if ($line =~ m/^<h1>(.*)<\/h1>$/) {
            my $this_pos = $chars;
            my $fill_pos = sprintf("%08d", $this_pos);
            my $m = $1;

            $self->_debug("...ref to char $this_pos,\ttitle '$1'");

            $self->{html_data} =~
            s/<li><a filepos="00000000">\Q$m\E<\/a><\/li><!-- TOC entry -->/<li><a filepos="$fill_pos">$m<\/a><\/li><!-- TOC entry -->/;
        }
        elsif ($line =~ /<!-- TOC start -->$/) {
            my $this_pos = $chars;
            my $fill_pos = sprintf("%08d", $this_pos);
            my $label    = $self->{toc_label};

            $self->{html_data} =~
            s/<reference type="toc" title="\Q$label\E" filepos="00000000"\/>/<reference type="toc" title="$self->{toc_label}" filepos="$fill_pos"\/>/;
        }
        $chars += length($line) + 1;
    }

}

1;

__END__

=encoding utf8

=head1 NAME

EBook::MOBI - create an ebook in the MOBI format.

You are at the right place here if you want to create an ebook in the so called MOBI format (somethimes also called PRC format or Mobipocket).

This is a software library for the I<perl programming language>.

=head1 SYNOPSIS

If you plan to create a typical ebook you probably will need most of the methods provided by this module. So it might be a good idea to read all the descriptions in the methods section, and also have a look at this example here.

=head2 Minimalistic Example

Paste and run.

 use EBook::MOBI;
 my $book = EBook::MOBI->new();
 $book->add_mhtml_content("hello world");
 $book->make();
 $book->save();

You should then find a file C<book.mobi> in your current directory.

=head2 Detailed Example

Because the input in this example is from the same file as the code, and this text-file is utf-8, we enable utf-8 and we will have no problems.

 use utf8;

Then we create an object and set some information about the book.

 # Create an object of a book
 use EBook::MOBI;
 my $book = EBook::MOBI->new();

 # give some meta information about this book
 $book->set_filename('./data/my_ebook.mobi');
 $book->set_title   ('Read my Wisdome');
 $book->set_author  ('Alfred Beispiel');
 $book->set_encoding(':encoding(UTF-8)');

Input can be done in several ways.
You can always work directly with the format itself.
See L<EBook::MOBI::Converter> for more information about this format.

 # lets create our own title page!
 $book->add_mhtml_content(
     " <h1>This is my Book</h1>
      <p>Read my wisdome.</p>"
 );
 $book->add_pagebreak();

To help you with the format use L<EBook::MOBI::Converter>.
The above would then look like this:

 my $c = EBook::MOBI::Converter->new();
 $book->add_mhtml_content( $c->title('This is my Book', 1, 0) );
 $book->add_mhtml_content( $c->paragraph('Read my wisdome')   );
 $book->add_mhtml_content( $c->pagebreak()                    );

At any point in the book you can insert a table of content.

 # insert a table of contents after the titlepage
 $book->add_toc_once();
 $book->add_pagebreak();

The preferred way for your normal input should be the add_content() method.
It makes use of plugins, so you should make sure there is a plugin for your input markup.

 my $POD_in = "=head1 Title\n\nSome text.\n\n";  

 # add the books text, which is e.g. in the POD format
 $book->add_content( data           => $POD_in,
                     driver         => 'EBook::MOBI::Driver::POD',
                     driver_options => { pagemode => 1},
                   );

After that, some small final steps are needed and the book is ready.

 # prepare the book (e.g. calculate the references for the TOC)
 $book->make();

 # let me see how this mobi-format looks like
 $book->print_mhtml();

 # ok, give me that mobi-book as a file!
 $book->save();

 # done

=head1 METHODS (set meta data)

=head2 set_title

Give a string which will appear in the meta data of the format. This will be used e.g. by ebook-readers to determine the books name.

 $book->set_title('Read my Wisdome');

=head2 set_author

Give a string which will appear in the meta data of the format. This will be used e.g. by ebook-readers to determine the books author.

 $book->set_author('Alfred Beispiel');

=head2 set_filename

The book will be stored under the name and location you pass here. When calling the save() method the file will be created.

 $book->set_filename('./data/my_ebook.mobi');

If you don't use this method, the default name will be 'book.mobi'.

=head2 set_encoding

If you don't set anything here, C<:encoding(UTF-8)> will be default.

 $book->set_encoding(':encoding(UTF-8)');

Only two encodings are supported by the mobiperl driver: UTF-8 or
ISO-8859-1. ASCII is treated the same as ISO-8859-1. If any other
encodings are passed in, the module will raise an error.

Please see L<http://perldoc.perl.org/functions/binmode.html> for the syntax of your encoding keyword.
If you use use hardcoded strings in your program, C<use utf8;> should be helping.

=head1 METHODS (adding content)

=head2 add_mhtml_content

'mhtml' stands for mobi-html, which means: it is actually HTML but some things are different. I invented this term myself, so it is probably not a good idea to search the web or ask other people about it. If you are looking for more information about this format you might search the web for 'mobipocket file format' or something similar.

If you stick to the most basic HTML tags it should be perfect mhtml 'compatible'. This way you can add your own content directly. If this is to tricky, have a look at the add_content() method.

 $book->add_mhtml_content(
     " <h1>This is my Book</h1>
      <p>Read my wisdome.</p>"
 );

If you indent the 'h1' tag with any whitespace, it will not appear in the TOC (only 'h1' tags directly starting and ending with a newline are marked for the TOC). This may be usefull if you want to design a title page.

There is a module L<EBook::MOBI::Converter> which helps you in creating this format. See it's documentation for more information.

If you are passing your own text to add_mhtml_content rather than
using a converter you will need to: a) encode the text according to
your chosen encoding, eg call L<Encode::encode_utf8>; b) ensure that
any HTML entities such as '<' in your text are replaced, eg by calling
L<HTML::Entities::encode_entities>.

=head2 add_content

Use this method if you have your content in a specific markup format.
See below for details to the arguments supported by this method.

 $book->add_content( data           => $data_as_string,
                     driver         => $driver_name,
                     driver_options => {plugin_option => $value}
                   );

The method uses a plugin system to transform your format into an ebook.
If you don't find a plugin for your markup please write one and release it under the namespace C<EBook::MOBI::Driver::$YourMarkup>.

Details for the options of this method:

=head3 data

A string, containing your text for the ebook.

=head3 driver

The name of the module which parses your data.
If this value is not set, the default is L<EBook::MOBI::Driver::POD>.
You are welcome to add your own driver for your markup of choice!

=head3 driver_options

Pass a hash ref here, with options for the plugin.
This options may be different for each plugin.

=head2 add_pagebreak

Use this method to seperate content and give some structure to your book.

 $book->add_pagebreak();

=head2 add_toc_once

Use this method to place a table of contents into your book. You will B<need to> call the make() method later, B<after> you added all your content to the book. This is, because we need all the content - to be able to calculate the references where the TOC is pointing to. B<Only 'h1' tags starting and ending with a newline char will enter the TOC.>

 $book->add_toc_once();

By default, the toc is called 'Table of Contents'. You can change that label by passing it as a parameter:

 $book->add_toc_once( 'Summary' );

This method can only be called once. If you call it twice, the second call will not do anything.

=head1 METHODS (finishing)

=head2 make

You only need to call this one before saving, if you have used the add_toc_once() method. This will calculate the references, pointing from the TOC into the content.

 $book->make();

=head2 print_mhtml

If you are curious how the mobi-specific HTML looks like, take a look!

If you call the method it will print to standard output. You can change this behaviour by passing any true argument. The content will then be returned, so that you can store it in a variable.

 # print to stdout
 $book->print_mhtml();
 
 # or get the result into a variable
 $mhtml_data = $book->print_mhtml('result to var');

=head2 save

Put the whole thing together as an ebook. This will create a file, with the name and location you gave with set_filename().

 $book->save();

In this process it will also read images and store them into the ebook. So it is important, that the images are readable at the path you provided before.

=head1 METHODS (debugging)

=head2 reset

Reset the object, so that all the content is purged. Helpful if you like to make a new book, but are to lazy to create a new object. (e.g. for testing)

 $book->reset();

=head2 debug_on

You can just ignore this method if you are not interested in debugging!
Pass a reference to a debug subroutine and enable debug messages.

 sub debug {
     my ($package, $filename, $line) = caller;
     print "$package\t$_[0]\n";
 }

 $book->debug_on(\&debug);

Or shorter:

 $book->debug_on(sub { print @_; print "\n" });

=head2 debug_off

Stop debug messages and erease the reference to the subroutine.

 $book->debug_off();

=head1 PLUGINS / DRIVERS

=head2 POD

L<EBook::MOBI::Driver::POD> is a plugin for Perls markup language POD.
Please see its docs for more information and options.

=head2 Example

L<EBook::MOBI::Driver::Example> is an example implementation of a simple plugin. It is only useful for plugin writers, as an example.
Please see its docs for more information and options.

=head1 IMAGES

Since C<v0.56> there is a change to the image behaviour.
If you like to include images or pictures into your ebook you now should install the module L<EBook::MOBI::Image>.
This code is no more with the main module, to reduce dependencies to image libraries (not everybody need to add images).
It depends on your input plugin, how you can add images to your book.
For POD, see the special syntax described in L<EBook::MOBI::Driver::POD>.
For adding manually in MHTML, see L<EBook::MOBI::Converter>.

B<Shortcut> for lazy guys: The conclusion of reading L<EBook::MOBI::Driver::POD> will be that you can add images via the POD-driver as following:

 $book->add_content( data   => '=for image /my/camel.jpg This is a Camel.',
                     driver => 'EBook::MOBI::Driver::POD',
                     driver_options => { pagemode => 0, head0_mode => 0 }
                   );

If you don't want to use the POD driver for adding images then you should read the section I<WHAT IS MHTML?> in the module L<EBook::MOBI::Converter> (as said already). But this needs some effort.

=head1 SEE ALSO

=over

=item * L<Github|https://github.com/borisdaeppen/EBook--MOBI> for participating and also for L<bugreports|https://github.com/borisdaeppen/EBook--MOBI/issues>.

=item * L<EBook::MOBI> - create an ebook in the MOBI format.

=item * L<EBook::MOBI::Driver::Example> - Example plugin implementation.

=item * L<EBook::MOBI::Driver::POD> - Create HTML, flavoured for the MOBI format, out of POD.

=item * L<EBook::MOBI::Driver> - Interface for plugins.

=item * L<EBook::MOBI::Converter> - Tool to create MHTML.


=item * L<EBook::MOBI::Mhtml2Mobi> - Create a Mobi ebook by packing MOBI-ready HTML.

=item * Everything in the namespace C<EBook::MOBI::MobiPerl> is coming from MobiPerl. For information about this code, please visit L<https://dev.mobileread.com/trac/mobiperl>

=back

=head1 THANKS TO

=over

=item * Renée Bäcker and L<Perl-Services.de|http://www.perl-services.de/> for the idea, patches and making this module possible.

=item * L<Perl-Magazin|http://perl-magazin.de/> for publishing an article in autumn 2012.

=item * L<Linux-Magazin|http://shop.linuxnewmedia.de/eh20194.html> for mentioning the module in the Perl-Snapshots. The article is also available L<online|http://www.linux-magazin.de/content/view/full/69651> and as L<podcast|http://www.linux-magazin.de/plus/2012/08/Perl-Snapshot-Linux-Magazin-2012-08>.

=item * Tompe for developing MobiPerl.

=back

=head1 CONTRIBUTORS

=over

=item * L<Breno G. de Oliveira (GARU)|https://metacpan.org/author/GARU>

=item * L<Renée Bäcker (RENEEB)|https://metacpan.org/author/RENEEB>

=item * L<Rupert Lane (RUPERTL)|https://metacpan.org/author/RUPERTL>

=item * L<Abby Pan (abbypan)|http://abbypan.github.io/>

=item * L<Gabor Szabo (szabgab)|https://metacpan.org/author/SZABGAB>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2015 Boris Däppen, all rights reserved.

This program is free software; you can redistribute it and/or modify it under the same terms of Artistic License 2.0.


=head1 AUTHOR

Boris Däppen E<lt>bdaeppen.perl@gmail.comE<gt>

=cut

