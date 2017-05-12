package HTML::Tree::Create::Callback;

our $DATE = '2016-04-01'; # DATE
our $VERSION = '0.03'; # VERSION

use 5.010001;
use strict;
use warnings;
use HTML::Entities;

use Exporter qw(import);
our @EXPORT_OK = qw(create_html_tree_using_callback);

sub _render_elem {
    my ($callback, $level, $seniority) = @_;

    my $indent  = "  " x $level;
    my $indent2 = "  " x ($level + 1);

    my ($elem, $attrs, $text_before, $text_after, $num_children) =
        $callback->($level, $seniority);

    my @res;

    $attrs //= {};
    push @res, (
        $indent,
        "<$elem",
        keys(%$attrs) ? " " : "",
        join(" ",
             map {$_ . '="' . encode_entities($attrs->{$_}) . '"'}
                 sort keys %$attrs
             ),
        ">\n"
    );
    if (defined($text_before) && length($text_before)) {
        push @res, $indent2, $text_before, "\n";
    }
    for (0..$num_children-1) {
        push @res, _render_elem($callback, $level+1, $_);
    }
    if (defined($text_after) && length($text_after)) {
        push @res, $indent2, $text_after, "\n";
    }
    push @res, $indent, "</$elem>\n";
    @res;
}

sub create_html_tree_using_callback {
    my $callback = shift;

    # create the root node
    join("", _render_elem($callback, 0, 0));
}

1;
# ABSTRACT: Create HTML document by using a callback

__END__

=pod

=encoding UTF-8

=head1 NAME

HTML::Tree::Create::Callback - Create HTML document by using a callback

=head1 VERSION

This document describes version 0.03 of HTML::Tree::Create::Callback (from Perl distribution HTML-Tree-Create-Callback), released on 2016-04-01.

=head1 SYNOPSIS

    use HTML::Tree::Create::Callback qw(create_html_tree_using_callback);
    $tree = create_html_tree_using_callback(
        sub {
            my ($level, $seniority) = @_;
            $id++;
            if ($level == 0) {
                return (
                    'body',
                    {}, # attributes
                    "text before children",
                    "text after children",
                    3, # number of children node
                );
            } elsif ($level == 1) {
                return ('p', {id=>$id}, "", "", 2);
            } elsif ($level == 2) {
                return (
                    'span', {id=>$id, class=>"foo".$seniority},
                    'text3.'.$seniority,
                    'text4',
                    0,
                );
            }
        }
    );
    print $tree;

Sample result:

 <body>
   text before children
   <p id="2">
     <span class="foo0" id="3">
       text3.0
       text4
     </span>
     <span class="foo1" id="4">
       text3.1
       text4
     </span>
   </p>
   <p id="5">
     <span class="foo0" id="6">
       text3.0
       text4
     </span>
     <span class="foo1" id="7">
       text3.1
       text4
     </span>
   </p>
   <p id="8">
     <span class="foo0" id="9">
       text3.0
       text4
     </span>
     <span class="foo1" id="10">
       text3.1
       text4
     </span>
   </p>
   text after children
 </body>

=head1 DESCRIPTION

=head1 FUNCTIONS

=head2 create_html_tree_using_callback($cb) => str

Create HTML document using callback for each element. Your callback will be
called with these arguments:

 ($level, $seniority)

where C<$level> starts with 0 for the root element, then 1 for the child
element, and so on. C<$seniority> starts with 0 for the first child, 1 for the
second child, and so on. The callback is expected to return a list:

 ($element, \%attrs, $text_before, $text_after, $num_children)

where C<$element> is a string containing element name (e.g. C<body>, C<p>, and
so on), C<\%attrs> is a hashref containing list of attributes, C<$text_before>
is text to put before the first child element, C<$text_after> is text to put
after the last child element, and C<$num_children> is the number of child
element to have. The callback will then be called again for each child element.
To stop the tree from growing, at the last level you want you should put 0 to
the number of children.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/HTML-Tree-Create-Callback>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-HTML-Tree-Create-Callback>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=HTML-Tree-Create-Callback>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

The interface of this module is modeled after L<Tree::Create::Callback>.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
