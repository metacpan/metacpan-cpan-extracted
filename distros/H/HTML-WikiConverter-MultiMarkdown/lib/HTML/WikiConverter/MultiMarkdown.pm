package HTML::WikiConverter::MultiMarkdown;

use strict;
use warnings;

our $VERSION = '0.02';

use base 'HTML::WikiConverter::Markdown';

use Params::Validate qw( ARRAYREF );


sub rules
{
    my $self = shift;

    my $rules = $self->SUPER::rules(@_);

    return
        { %{$rules},
          table => { block => 1,
                     end => \&_table_end,
                   },
          tr    => { start       => \&_tr_start,
                     end         => qq{ |\n},
                     line_format => 'single'
                   },
          td    => { start => \&_td_start,
                     end   => q{ } },
          th    => { alias   => 'td', },
          title => { replace => \&_title },
        };
}

sub attributes
{
    my $self = shift;

    return
        { %{ $self->SUPER::attributes() },
          strip_tags => { type => ARRAYREF, default => [ qw( ~comment script style / ) ] },
        };
}

sub _title
{
    my $self = shift;
    my $node = shift;

    my $text = $self->get_elem_contents($node);

    return 'Title: ' . $text;
}

sub _table_end
{
    my $self = shift;

    delete $self->{__row_count__};
    delete $self->{__th_count__};

    return q{};
}


# This method is first called on the _second_ row, go figure
sub _tr_start
{
    my $self = shift;

    my $start = q{};
    if ( $self->{__row_count__} == 2 )
    {
        $start = '|---' x $self->{__th_count__};
        $start .= qq{|\n};
    }

    $self->{__row_count__}++;

    return $start;
}

# This method is called for the first cell in a table, and before the
# first call to table or tr start!
sub _td_start
{
    my $self = shift;

    $self->{__row_count__} = 1
        unless exists $self->{__row_count__};

    if ( $self->{__row_count__} == 1 )
    {
        if ( exists $self->{__th_count__} )
        {
            $self->{__th_count__}++;
        }
        else
        {
            $self->{__th_count__} = 1;
        }
    }

    return '| ';
}

1;

__END__

=pod

=head1 NAME

HTML::WikiConverter::MultiMarkdown - Converts HTML to MultiMarkdown syntax

=head1 SYNOPSIS

    use HTML::WikiConverter::MultiMarkdown;

    my $converter = HTML::WikiConverter::MultiMarkdown->new();

    my $markdown = $converter->html2wiki( html => $html );

=head1 DESCRIPTION

This is a subclass of L<HTML::WikiConverter::Markdown> that output
MultiMarkdown syntax. The most notable extension MultiMarkdown provides for
original Markdown is support for tables.

See L<http://fletcherpenney.net/multimarkdown/> for more information on
MultiMarkdown.

For now, this module's implementation is incomplete, and it does not support
most MultiMarkdown features. Supported features are:

=over 4

=item * tables

There is basic support for tables. The first row of a table is always treated
as the header. There is no support for column or row groups. There is also no
support for captions or summaries.

=item * metadata

The page's C<< <title> >> tag will be turned into a Title metadata item.

=back

Patches for more syntax feature support are welcome.

=head1 METHODS

See L<HTML::WikiConverter> for usage information.

=head1 AUTHOR

Dave Rolsky, E<gt>autarch@urth.orgE<lt>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-html-wikiconverter-multimarkdown@rt.cpan.org>, or through the web
interface at L<http://rt.cpan.org>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 DONATIONS

If you'd like to thank me for the work I've done on this module,
please consider making a "donation" to me via PayPal. I spend a lot of
free time creating free software, and would appreciate any support
you'd care to offer.

Please note that B<I am not suggesting that you must do this> in order
for me to continue working on this particular software. I will
continue to do so, inasmuch as I have in the past, for as long as it
interests me.

Similarly, a donation made in this way will probably not make me work
on this software much more, unless I get so many donations that I can
consider working on free software full time, which seems unlikely at
best.

To donate, log into PayPal and send money to autarch@urth.org or use
the button on this page:
L<http://www.urth.org/~autarch/fs-donation.html>

=head1 COPYRIGHT & LICENSE

Copyright 2009 Dave Rolsky, All Rights Reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
