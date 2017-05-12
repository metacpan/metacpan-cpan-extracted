package Kwiki::Diff::Mutual;
use strict;
use warnings;
use base qw( Kwiki::Diff );

our $VERSION = '0.01';

sub class_title { 'Kwiki mutual diffs' }
sub cgi_class   { 'Kwiki::Diff::Mutual::CGI' }

sub diff {
    my $self = shift;
    my $page = $self->pages->current;
    $page->load;

    my $revisions = $page->revision_numbers;
    my $revision_id = $self->cgi->revision_id
      or return $self->redirect( $page->url );
    my $current_revision_id = $self->cgi->current_revision_id;
    unless ($current_revision_id =~ /^\d+$/) {
        $current_revision_id = $revision_id - 1;
    }

    $revision_id = $revisions->[ -$revision_id ] if ( $revision_id < 0 );
    $current_revision_id = $revisions->[ -$current_revision_id ] if ( $current_revision_id < 0 );

    if ($revision_id > $current_revision_id) {
        my $tmp = $revision_id;
        $revision_id = $current_revision_id;
        $current_revision_id = $tmp;
    }

    my $archive = $self->hub->archive;

    my $screen_title =
      $page->title . " <small>(Diff of Revision $revision_id to $current_revision_id)</small>",

    # now the diff
    my $current       = [ split /\n/, $archive->fetch( $page, $current_revision_id ) ];
    my $this_revision = [ split /\n/, $archive->fetch( $page, $revision_id ) ];
    require Algorithm::Diff;
    my @diff = Algorithm::Diff::sdiff( $this_revision, $current );

    # check out sdiff() in Algorithm::Diff -- i'm changing
    # the markers to real words so we can use them in
    # the template really easily
    require String::Diff;
    @diff = map {
        $_->[0] = {
            '+' => 'added',
            '-' => 'removed',
            'u' => 'unmodified',
            'c' => 'changed',
        }->{ $_->[0] };
        if ($_->[0] eq 'changed') {
            $_->[3] = String::Diff::diff_fully($_->[1], $_->[2]);
        } else {
            #url-breaker
            for my $i (1..2) {
                $_->[$i] =~ s!([\x21-\x7f]{10,10})([\x21-\x7f]{10,10})!$1<wbr>$2!mgo;
            }
        }
        $_;
    } @diff;

    my $page_name = $self->cgi->page_name;
    utf8::encode($page_name) if utf8::is_utf8($page_name);

    $self->render_screen(
        revision_id          => $revision_id,
        current_revision_id  => $current_revision_id,
        revisions            => $revisions,
        last_revision_id     => $revisions->[0],
        screen_title         => $screen_title,
        diff                 => \@diff,
        page_name            => $page_name,
        page_meta            => $archive->fetch_metadata($page, $revision_id),
        current_page_meta    => $archive->fetch_metadata($page, $current_revision_id),
    );
}

package Kwiki::Diff::Mutual::CGI;
use Kwiki::CGI '-base';
cgi 'page_name';
cgi 'revision_id';
cgi 'current_revision_id';

package Kwiki::Diff::Mutual;

__DATA__

=head1 NAME 

Kwiki::Diff::Mutual - The selection of revision of both parties of Diff is enabled.

=head1 SYNOPSIS

 $ cd /path/to/kwiki
 $ kwiki -add Kwiki::Diff::Mutual

=head1 DESCRIPTION

This module requires that you be using L<Kwiki::Diff>. Please make sure
L<Kwiki::Diff> is in your F<plugins> file.

Working to which the function of A is enhanced of both parties of Diff. 

=head1 AUTHORS

Kazuhiro Osawa E<lt>ko@yappo.ne.jpE<gt>

=head1 SEE ALSO

L<Kwiki>, L<Kwiki::Diff>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Kazuhiro Osawa

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__template/tt2/diff_content.html__
<!-- BEGIN diff_content.html -->
[% INCLUDE diff_legend.html %]
[% IF revision_id > 1 %]
<a href="[% script_name %]?action=diff&page_name=[% page_name FILTER uri %]&revision_id=[% revision_id - 1 %]&current_revision_id=[% current_revision_id - 1 %]">Previous</a>
[% END %]
&nbsp;
[% IF current_revision_id < last_revision_id %]
<a href="[% script_name %]?action=diff&page_name=[% page_name FILTER uri %]&revision_id=[% revision_id + 1 %]&current_revision_id=[% current_revision_id + 1 %]">Next</a>
[% END %]
<form name="diff_mutual"
      action="[% script_name %]">
<input type="hidden" name="action" value="diff" />
<input type="hidden" name="page_name" value="[% page_name %]" />
<table border="0" cellspacing="0" cellpadding="1" summary="A line-by-line difference between the current page and revision [% revision_id %]" class="diff">
<colgroup><col width="50%"/><col width="50%"/></colgroup>
<tr>
    <th>Revision <select name="revision_id" onchange="diff_mutual.submit();">
    [% FOREACH id = revisions %]
    <option[% IF revision_id == id %] selected[% END %]>[% id %]</option>
    [% END %]
    </select> edit by [% page_meta.edit_by %]<br /> at [% page_meta.edit_time %] GMT</th>
    <th>Revision <select name="current_revision_id" onchange="diff_mutual.submit();">
    [% FOREACH id = revisions %]
    <option[% IF current_revision_id == id %] selected[% END %]>[% id %]</option>
    [% END %]
    </select> edit by [% current_page_meta.edit_by %]<br /> at [% current_page_meta.edit_time %] GMT</th>
</tr>
[% FOREACH line = diff -%]
    [% IF line.0 == 'added' || line.0 == 'removed' %]
        <tr>
        [% IF line.1.length %]
            <!-- line.1 length -->
            <td class="lhs diff-[% line.0 %]">[% line.1 FILTER html FILTER replace('&lt;wbr&gt;', '<wbr>') %]</td>
            <td class="rhs">&nbsp;</td>
        [% ELSIF line.2.length %]
            <!-- line.2 length -->
            <td class="lhs">&nbsp;</td>
            <td class="rhs diff-[% line.0 %]">[% line.2 FILTER html FILTER replace('&lt;wbr&gt;', '<wbr>') %]</td>
        [% ELSE %]
            <!-- neither length -->
            <td class="lhs">&nbsp;</td>
            <td class="rhs">&nbsp;</td>
        [% END %]
        </tr>
    [% ELSIF line.0 == 'changed' %]
        <!-- changed -->
        <tr class="diff-[% line.0 %]">
            <td class="lhs">
[% FOREACH old = line.3.0 -%][% IF old.0 == '-' -%]<span class="diff-removed">[% old.1 | html -%]</span>[% ELSE -%][% old.1 | html -%][% END -%][% END -%]
            &nbsp;</td>
            <td class="rhs">
[% FOREACH new = line.3.1 -%][% IF new.0 == '+' -%]<span class="diff-added">[% new.1 | html -%]</span>[% ELSE -%][% new.1 | html -%][% END -%][% END -%]
            &nbsp;</td>
        </tr>
    [% ELSE %]
        <!-- not added or removed -->
        <tr class="diff-[% line.0 %]">
            <td class="lhs">[% line.1 FILTER html FILTER replace('&lt;wbr&gt;', '<wbr>') %] &nbsp;</td>
            <td class="rhs">[% line.2 FILTER html FILTER replace('&lt;wbr&gt;', '<wbr>') %] &nbsp;</td>
        </tr>
    [% END %]
[%- END %]
</table>
</form>
<!-- END diff_content.html -->
