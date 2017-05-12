package Kwiki::PageInclude;
use Kwiki::Plugin -Base;
our $VERSION = '0.02';

const class_id => 'page_include';
const class_title => 'Include Other Page';

sub register {
    my $reg = shift;
    $reg->add(wafl => include => 'Kwiki::PageInclude::WaflPhrase');
}

package Kwiki::PageInclude::WaflPhrase; 
use base 'Spoon::Formatter::WaflPhrase';

sub to_html {
    my @args = split(/[\s,]+/,$self->arguments);
    my $ret;
    for(@args) {
        my $page = $self->hub->pages->new_from_name($_);
        $ret .= $self->hub->formatter->text_to_html($page->content);
    }
    return $ret;
}

__END__

=head1 NAME

  Kwiki::PageInclude - Include other page into this one

=head1 SYNOPSIS

  {include: PageOne}

  {include: PageOne,PageTwo}

  {include: PageOne PageTwo PageThree}

=head1 DESCRIPTION

After you install this plugin, your are able to use C<{include: PageName}>
wafl phrase in your Kwiki page content, and that will
include all content of that page in this one. So it allows you to
"modualize" your Kwiki pages. You can give a list of page names
sepearated by comma, or space. They will be included in order.

=head1 COPYRIGHT

Copyright 2004 by Kang-min Liu <gugod@gugod.org>.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

See <http://www.perl.com/perl/misc/Artistic.html>

=cut

