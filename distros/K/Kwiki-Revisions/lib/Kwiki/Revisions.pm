package Kwiki::Revisions;
use Kwiki::Plugin -Base;
use mixin 'Kwiki::Installer';
our $VERSION = '0.15';

const class_id => 'revisions';
const cgi_class => 'Kwiki::Revisions::CGI';
field revision_id => 0;

sub register {
    my $registry = shift;
    $registry->add(prerequisite => 'archive');
    $registry->add(action => 'revisions');
    $registry->add(toolbar => 'revisions_button', 
                   template => 'revisions_button.html',
                   show_for => 'display',
                  );
    $registry->add(toolbar => 'revisions_controls', 
                   template => 'revisions_controls.html',
                   show_for => 'revisions',
                   params_class => $self->class_id,
                  );
}

sub revisions {
    $self->render_screen($self->toolbar_params);
}

sub toolbar_params {
    my $page = $self->pages->current;
    $page->load;
    my $revision_id = $self->cgi->revision_id
      or return $self->redirect($page->url);

    my $revisions = $page->revision_numbers;
    $revision_id = $revisions->[-$revision_id] if ($revision_id < 0);
    $self->revision_id($revision_id);

    my $archive = $self->hub->archive;
    $page->content($archive->fetch($page, $revision_id));
    my $page_title = $page->title;
    my $screen_title = "$page_title <span style=\"font-size:smaller;color:red\">(Revision $revision_id)</span>";
    my ($prev, $next);

    REVISIONS: {
        foreach my $index (0..$#$revisions) {
            $revisions->[$index] == $revision_id or next;

            $prev = $revisions->[$index+1];
            $next = $revisions->[$index-1] if $index;

            $page->metadata->from_hash(
                $archive->fetch_metadata($page, $revision_id)
            );

            last REVISIONS;
        }
        die "No such revision: $revision_id";
    }

    return (
        screen_title => $screen_title,
        page_html => $page->to_html,
        revision_id => $revision_id,
        previous_id => $prev,
        next_id => $next,
    );
}

package Kwiki::Revisions::CGI;
use Kwiki::CGI -base;

cgi 'revision_id';

package Kwiki::Revisions;
__DATA__

=head1 NAME 

Kwiki::Revisions - Kwiki Revisions Plugin

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 AUTHOR

Brian Ingerson <ingy@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2004. Brian Ingerson. All rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut
__template/tt2/revisions_button.html__
[% revisions = hub.archive.show_revisions %]
[% IF revisions %]
<a href="[% script_name %]?action=revisions&page_name=[% page_uri %]&revision_id=-1" accesskey="r" title="[% IF revisions > 1 %][% revisions %] Revisions[% ELSE %]Previous Revision[% END %]">
[% INCLUDE revisions_button_icon.html %]
</a>
[% END %]
__template/tt2/revisions_button_icon.html__
Revisions
__template/tt2/revisions_controls.html__
[% IF previous_id -%]
<a href="[% script_name %]?action=revisions&page_name=[% page_uri %]&revision_id=[% previous_id %]" accesskey="p" title="Previous Revision">
[% INCLUDE revisions_controls_previous_icon.html %]
</a> &nbsp; 
[% END -%]
<a href="[% script_name %]?[% page_uri %]" accesskey="c" title="Current Revision">
[% INCLUDE revisions_controls_current_icon.html %]
</a>
[% IF next_id -%]
 &nbsp; <a href="[% script_name %]?action=revisions&page_name=[% page_uri %]&revision_id=[% next_id %]" accesskey="n" title="Next Revision">
[% INCLUDE revisions_controls_next_icon.html %]
</a>
[% END -%]
__template/tt2/revisions_controls_current_icon.html__
Current
__template/tt2/revisions_controls_next_icon.html__
Next
__template/tt2/revisions_controls_previous_icon.html__
Previous
__template/tt2/revisions_content.html__
[% INCLUDE display_changed_by.html %]
<div class="wiki">
[% page_html -%]
</div>
