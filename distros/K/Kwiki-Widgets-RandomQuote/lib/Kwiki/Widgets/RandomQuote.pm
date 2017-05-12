package Kwiki::Widgets::RandomQuote;
use Kwiki::Plugin -Base;
use mixin 'Kwiki::Installer';
our $VERSION = '0.01';

const class_id => 'widgets_random_quote';
const class_title => 'Random Qoute';

sub register {
    my $registry = shift;
    $registry->add(widget => 'random_quote',
		   template => 'widgets_random_quote.html');
}

# This could be a really slow function.
sub show {
    my @pages = $self->pages->all_ids_newest_first;
    my $page = $self->pages->new_page($pages[int(rand(@pages))]);
    my @paragraphs = split(/\n+/,$page->content);
    my $choosen = @paragraphs[int(rand(@paragraphs))];
    return $self->hub->formatter->text_to_html($choosen);
}

__DATA__

=head1 NAME

  Kwiki::Widgets::RandomQuote - Quote a random paragraph from all pages.

=head1 DESCRIPTION

This Kwiki widget display a random quote on your widget_pane, which is just
for fun.

=head1 COPYRIGHT

Copyright 2005 by Kang-min Liu <gugod@gugod.org>.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

See <http://www.perl.com/perl/misc/Artistic.html>

=cut

__template/tt2/widgets_random_quote.html__
<div id="widgets_random_quote">
<h4>Random Quote</h4>
[% hub.widgets_random_quote.show %]
</div>
