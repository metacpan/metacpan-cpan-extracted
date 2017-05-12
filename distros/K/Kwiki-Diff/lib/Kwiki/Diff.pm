package Kwiki::Diff;
use strict;
use warnings;

use Kwiki::Plugin -Base;
use Kwiki::Installer -base;

our $VERSION = '0.03';

const class_title => 'Kwiki diffs';
const class_id    => 'diff';
const cgi_class   => 'Kwiki::Diff::CGI';
const css_file    => 'diff.css';

sub register {
    my $registry = shift;
    $registry->add( action => 'diff' );
    $registry->add(
        toolbar      => 'diff_button',
        template     => 'diff_button.html',
        show_for     => 'revisions',
        params_class => $self->class_id,
    );
    $registry->add(
        toolbar      => 'diff_controls',
        template     => 'diff_controls.html',
        show_for     => 'diff',
        params_class => $self->class_id,
    );
}

sub diff {

    # a lot of chunks here stolen from ingy's Kwiki::Revisions
    my $page = $self->pages->current;
    $page->load;
    my $revision_id = $self->cgi->revision_id
      or return $self->redirect( $page->url );

    my $revisions = $page->revision_numbers;
    $revision_id = $revisions->[ -$revision_id ] if ( $revision_id < 0 );
    my $archive = $self->hub->archive;

    my $screen_title =
      $page->title . " <small>(Diff of Revision $revision_id)</small>",

    # now the diff
    my $current = [ split /\n/, $page->content ];
    my $this_revision = [ split /\n/, $archive->fetch( $page, $revision_id ) ];
    require Algorithm::Diff;
    my @diff = Algorithm::Diff::sdiff( $this_revision, $current );

    # check out sdiff() in Algorithm::Diff -- i'm changing
    # the markers to real words so we can use them in
    # the template really easily
    $_->[0] = {
        '+' => 'added',
        '-' => 'removed',
        'u' => 'unmodified',
        'c' => 'changed',
      }->{ $_->[0] }
      for @diff;

    $self->render_screen(
        revision_id  => $revision_id,
        screen_title => $screen_title,
        diff         => \@diff,
    );
}

sub toolbar_params {
    my $revision_id = $self->cgi->revision_id
      or return $self->redirect( $self->pages->current->url );
    return revision_id => $revision_id;
}

package Kwiki::Diff::CGI;
use Kwiki::CGI '-base';
cgi 'revision_id';

package Kwiki::Diff;

__DATA__

=head1 NAME 

Kwiki::Diff - display differences between the current wiki page and older revisions

=head1 SYNOPSIS

 $ cd /path/to/kwiki
 $ kwiki -add Kwiki::Diff

=head1 DESCRIPTION

This module requires that you be using L<Kwiki::Revisions>. Please make sure
L<Kwiki::Revisions> is in your F<plugins> file.

This module adds a toolbar item, "Differences," when viewing past revisions of
wiki pages. When clicked, the user is shown a colorful side-by-side comparison
of that revision and the current revision.

=head1 TODO

=over 4

=item * Alternate diff styles, such as showing *only* the lines that have changed at the top or inline with the text.

=item * Faster access to the differences of the current page.

=back

=head1 AUTHORS

Ian Langworth <langworth.com>

=head1 SEE ALSO

L<Kwiki>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004 by Ian Langworth

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__css/diff.css__
.diff-added, .diff-removed, .diff-unmodified, .diff-changed {
    font-family: monospace;
}
.diff-added {
    background: #cfc;
    color: #000;
}
.diff-removed {
    background: #fcc;
    color: #000;
}
.diff-unmodified {
    background: inherit;
    color: #000;
}
.diff-changed {
    background: #ffc;
    color: #000;
}

table.diff {
    border: 1px solid #666;
}

table th {
    border-bottom: 1px solid #666;
}

th.lhs, td.lhs {
    padding-right: 1em;
}
th.rhs, td.rhs {
    padding-left: 1em;
    border-left: 1px solid #666;
}

h1 small {
    color: #f00;
}

__template/tt2/diff_button.html__
<!-- BEGIN diff_button.html -->
<a href="[% script_name %]?action=diff&page_name=[% page_uri %]&revision_id=[% revision_id %]" accesskey="r" title="Differences">[% INCLUDE diff_button_icon.html %]</a>
<!-- END diff_button.html -->

__template/tt2/diff_button_icon.html__
<!-- BEGIN diff_button_icon.html -->
Differences
<!-- END diff_button_icon.html -->

__icons/gnome/template/diff_button_icon.html__
<!-- BEGIN diff_button_icon.html -->
<img src="icons/gnome/image/diff.png" alt="Differences" />
<!-- END diff_button_icon.html -->

__template/tt2/diff_controls.html__
<!-- BEGIN diff_controls.html -->
<a href="[% script_name %]?action=revisions&page_name=[% page_uri %]&revision_id=[% revision_id %]" accesskey="r" title="Revision [% revision_id %]">
[%- INCLUDE revisions_button_icon.html -%]
</a> | <a href="[% script_name %]?[% page_uri %]" accesskey="c" title="Current Revision">
[%- INCLUDE revisions_controls_current_icon.html -%]
</a> 
<!-- END diff_controls.html -->

__template/tt2/diff_legend.html__
<!-- BEGIN diff_legend -->
<p><span style="border:1px solid #ccc; padding:2px; color:#ccc">
    <span class="diff-added">Added</span> |
    <span class="diff-removed">Removed</span> |
    <span class="diff-changed">Changed</span> |
    <span class="diff-unmodified">Unmodified</span>
</span></p>
<!-- END diff_legend -->

__template/tt2/diff_content.html__
<!-- BEGIN diff_content.html -->
[% INCLUDE diff_legend.html %]
<table border="0" cellspacing="0" cellpadding="1" summary="A line-by-line difference between the current page and revision [% revision_id %]" class="diff">
<colgroup><col width="50%"/><col width="50%"/></colgroup>
<tr>
    <th>Revision [% revision_id %]</th>
    <th>Current</th>
</tr>
[% FOREACH line = diff -%]
    [% IF line.0 == 'added' || line.0 == 'removed' %]
        <tr>
        [% IF line.1.length %]
            <!-- line.1 length -->
            <td class="lhs diff-[% line.0 %]">[% line.1 FILTER html %]</td>
            <td class="rhs">&nbsp;</td>
        [% ELSIF line.2.length %]
            <!-- line.2 length -->
            <td class="lhs">&nbsp;</td>
            <td class="rhs diff-[% line.0 %]">[% line.2 FILTER html %]</td>
        [% ELSE %]
            <!-- neither length -->
            <td class="lhs">&nbsp;</td>
            <td class="rhs">&nbsp;</td>
        [% END %]
        </tr>
    [% ELSE %]
        <!-- not added or removed -->
        <tr class="diff-[% line.0 %]">
            <td class="lhs">[% line.1 FILTER html %] &nbsp;</td>
            <td class="rhs">[% line.2 FILTER html %] &nbsp;</td>
        </tr>
    [% END %]
[%- END %]
</table>
<!-- END diff_content.html -->

__icons/gnome/image/diff.png__
iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAACXBIWXMAAAsSAAALEgHS3X78AAAA
BGdBTUEAALGOfPtRkwAAACBjSFJNAAB6JQAAgIMAAPn/AACA6QAAdTAAAOpgAAA6mAAAF2+SX8VG
AAABZklEQVR42mL4//8/AxAEA/F/IrAPAxSA9IEwQAAxgglGxv/z799nQAZLHz1i2G1nxxh8yPW/
qbAVw/0vdxhmWSwDSYUA8VqoxQwAAcSErOnj799w/O7qVbDY66vvGB59vc9gK+bE4LvXHiS0Btkl
AAGEYgAu8PLHc4YpKyYy3FvzhEHWQwIktBkmBxBARBlgLmLDwCbAyvD99U+Gd5c+osgBBBALuuL/
WAzgY+VniHCOZmBwZmC49vESw1SzhXA5gABiIqQZBP79/weVx1QBEEAsyJr//f+P1yv/gQbBDIMB
gABiIcYFf///QWL/RZEDCCAWVKf+Byr4j9ML2ABAAGGEARMjI3bnI0FkABBARLkA5myQZnTXAAQQ
US5AthndBQABhOGC/3iiERYTyAAggOAG7Hv1iuHXP4Tkq337GBgyMxme7nvFcN3gMlz8xbsXIOoq
jA8QQAzQXJVNZHaG4RRYdgYIMACPS7sR62SgVAAAAABJRU5ErkJggg==
