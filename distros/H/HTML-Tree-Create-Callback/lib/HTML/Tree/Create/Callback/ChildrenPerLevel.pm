package HTML::Tree::Create::Callback::ChildrenPerLevel;

our $DATE = '2016-04-01'; # DATE
our $VERSION = '0.03'; # VERSION

use 5.010001;
use strict;
use warnings;
use HTML::Entities;

use HTML::Tree::Create::Callback qw();

use Exporter qw(import);
our @EXPORT_OK = qw(create_html_tree_using_callback);

sub create_html_tree_using_callback {
    my ($callback, $num_children_per_level) = @_;

    my $index_per_level = [];
    my $num_children_per_level_so_far = [];

    HTML::Tree::Create::Callback::create_html_tree_using_callback(
        sub {
            my ($level, $seniority) = @_;

            my ($element, $attrs, $text_before, $text_after) =
                $callback->($level, $seniority);
            my $num_children;
            if ($level >= @$num_children_per_level) {
                $num_children = 0;
            } elsif ($level == 0) {
                $num_children = $num_children_per_level->[0];
            } else {

                my $idx = ++$index_per_level->[$level];

                # at this point we must already have this number of children
                my $target = sprintf("%.0f",
                                     $idx *
                                         ($num_children_per_level->[$level] /
                                          $num_children_per_level->[$level-1]));

                # we have this number of children so far
                $num_children_per_level_so_far->[$level] //= 0;
                my $has = $num_children_per_level_so_far->[$level];

                $num_children = $target - $has;
                $num_children_per_level_so_far->[$level] += $num_children;
            }
            return ($element, $attrs, $text_before, $text_after, $num_children);
        },
    );
}

1;
# ABSTRACT: Create HTML document by using a callback (and number of elements per level)

__END__

=pod

=encoding UTF-8

=head1 NAME

HTML::Tree::Create::Callback::ChildrenPerLevel - Create HTML document by using a callback (and number of elements per level)

=head1 VERSION

This document describes version 0.03 of HTML::Tree::Create::Callback::ChildrenPerLevel (from Perl distribution HTML-Tree-Create-Callback), released on 2016-04-01.

=head1 SYNOPSIS

    use HTML::Tree::Create::Callback::ElemsPerLevel qw(create_html_tree_using_callback);
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
                );
            } elsif ($level == 1) {
                return ('p', {id=>$id}, "", "");
            } elsif ($level == 2) {
                return (
                    'span', {id=>$id, class=>"foo".$seniority},
                    'text3.'.$seniority,
                    'text4',
                );
            }
        },
        [3, 2],
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
   </p>
   <p id="4">
   </p>
   <p id="5">
     <span class="foo0" id="6">
       text3.0
       text4
     </span>
   </p>
   text after children
 </body>

=head1 DESCRIPTION

=head1 FUNCTIONS

=head2 create_html_tree_using_callback($cb, \@num_children_per_level) => str

This is like L<HTML::Tree::Create::Callback>'s
C<create_html_tree_using_callback> (in fact, it's implemented as a thin wrapper
over it), except that the callback does not need to return:

 ($element, \%attrs, $text_before, $text_after, $num_children)

but only:

 ($element, \%attrs, $text_before, $text_after)

The C<$num_children> will be calculated by this function to satisfy total number
of children per level specified in C<\@num_children_per_level>. So suppose
C<\@num_children_per_level> is C<[10, 50, 25]>, then the root element will have
10 child elements, and each child element will have 50/10 = 5 children of their
own, but only one out of two of these children will have a child because the
number of children at the third level is only 25 (half of 50).

Specifying total number of children per level is sometimes more convenient than
specifying number of children per node.

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

The interface of this module is modeled after
L<Tree::Create::Callback::ChildrenPerLevel>.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
