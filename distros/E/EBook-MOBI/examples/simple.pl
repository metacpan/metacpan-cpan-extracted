#!/usr/bin/perl

use EBook::MOBI;

my $pod = <<END;

=head1 Some POD

Some text.

=head2 Some Pictures

An image.

=image ./example/img/camel.jpg A Camel.

An image which has been resized.

=for image ./example/img/camel_big.jpg A Camel again.

=head3 A List

=over

=item *

First item.

=item *

Second item.

=back

=head2 That's it

The end.

END

my $book = EBook::MOBI->new();

# let's define a debug sub witch will be used by all modules
sub debug {
    my ($package, $filename, $line) = caller;
    print "$package\t$_[0]\n";
}

# pass the reference of the sub to our book
$book->debug_on(\&debug);

# fill the book with meta info
$book->set_filename('Simple.mobi');
$book->set_title   ('A Test: Simple');
$book->set_author  ('Boris');
$book->set_encoding(':encoding(UTF-8)');

# fill the book with content
$book->add_mhtml_content(" <h1>A Test Titlepage</h1><p>Very simple...</p>");
$book->add_pagebreak();
$book->add_toc_once();
$book->add_pagebreak();
$book->add_content(data => $pod, pagemode => 1);

$book->make();
#$book->print_mhtml();
$book->save();

