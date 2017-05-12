package MediaWiki::Table::Tiny;

our $DATE = '2015-06-18'; # DATE
our $VERSION = '0.01'; # VERSION

use 5.010001;
use strict;
use warnings;

sub table {
    my %args = @_;

    my $rows = $args{rows};

    my @res;

    push @res, '{| class="wikitable" style="text-align:center" border="1"',
        "\n";
    push @res, '{+', $args{caption}, "\n" if $args{caption};
    push @res, '|-', "\n";
    my $i = 0;
    for my $row (@$rows) {
        if (!$i) {
            push @res, '! ', join(' !! ', @$row), "\n";
        } else {
            push @res, '| ', join(' || ', @$row), "\n";
        }
        push @res, '|-', "\n";
        $i++;
    }
    push @res, '|}', "\n";
    join('', @res);
}

1;
# ABSTRACT: Generate MediaWiki table from table data

__END__

=pod

=encoding UTF-8

=head1 NAME

MediaWiki::Table::Tiny - Generate MediaWiki table from table data

=head1 VERSION

This document describes version 0.01 of MediaWiki::Table::Tiny (from Perl distribution MediaWiki-Table-Tiny), released on 2015-06-18.

=head1 SYNOPSIS

 use MediaWiki::Table::Tiny;

 my $rows = [
     # header row
     ['Name', 'Rank', 'Serial'],
     #
     ['alice', 'pvt', '123456'],
     ['bob',   'cpl', '98765321'],
     ['carol', 'brig gen', '8745'],
 ];
 print MediaWiki::Table::Tiny::table(rows => $rows);

Result:

 {| class="wikitable" style="text-align:center" border="1"
 |-
 ! Name !! Rank !! Serial
 |-
 | alice || pvt || 123456
 |-
 | bob || cpl || 98765321
 |-
 | carol || brig gen || 8745
 |-
 |}

=head1 DESCRIPTION

This module can be used to generate MediaWiki table from table data. The
interface is inspired from L<Text::Table::Tiny>.

=head1 FUNCTIONS

=head2 table(%args) => str

Generate table in MediaWiki format. Arguments (C<*> marks required argument):

=over

=item * rows* => aoa

=item * caption => str

=back

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/MediaWiki-Table-Tiny>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-MediaWiki-Table-Tiny>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=MediaWiki-Table-Tiny>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
