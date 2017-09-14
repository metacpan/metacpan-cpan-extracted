#! /bin/false
# vim: ts=4:et

# Copyright (C) 2016-2017 Guido Flohr <guido.flohr@cantanea.com>,
# all rights reserved.

# This program is free software; you can redistribute it and/or modify it
# under the terms of the GNU Library General Public License as published
# by the Free Software Foundation; either version 2, or (at your option)
# any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Library General Public License for more details.

# You should have received a copy of the GNU Library General Public
# License along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307,
# USA.

package Locale::XGettext::Util::POEntries;

use strict;

use Locale::TextDomain qw(Locale-XGettext);

sub new {
    bless {
        __entries => [],
        __lookup => {},
    }, shift;
}

sub __add {
    my ($self, $entry, $prepend) = @_;

    my $msgid = $entry->msgid || defined $entry->msgid ? $entry->msgid : '""';
    my $msgctxt = $entry->msgctxt || defined $entry->msgctxt ? $entry->msgctxt : '""';
    my $msgid_plural = $entry->msgid_plural 
        || defined $entry->msgid_plural ? $entry->msgid_plural : '""';
    my $existing = $self->{__lookup}->{$msgid}->{$msgctxt};
    if ($existing) {
        $self->__mergeEntries($existing, $entry);
        $entry = $existing;
    } else {
        if ($prepend) {
            unshift @{$self->{__entries}}, $entry;
        } else {
            push @{$self->{__entries}}, $entry;
        }
        $self->{__lookup}->{$msgid}->{$msgctxt} = $entry;
    }

    return $self;
}

sub add {
    my ($self, $entry) = @_;

    $entry->msgid('') if !defined $entry->msgid;
    if (defined $entry->msgid_plural) {
        if (!defined $entry->msgstr_n) {
            $entry->msgstr_n({0 => '', 1 => ''});
        }
        $entry->msgstr(undef);
    } elsif (!defined $entry->msgstr) {
        $entry->msgstr('') if !defined $entry->msgstr;        
    }
     
    return $self->__add($entry);
}

sub prepend {
    my ($self, $entry) = @_;

    return $self->__add($entry, 1);
}

sub addEntries {
    my ($self, @entries) = @_;

    foreach my $entry (@entries) {
        $self->add($entry);
    }

    return $self;
}

sub entries {
    @{shift->{__entries}};
}

# This is a simplified merge for merging entries without any translations.
sub __mergeEntries {
    my ($self, $entry, $overlay) = @_;

    if (defined $entry->msgid_plural 
        && defined $overlay->msgid_plural
        && $entry->msgid_plural ne $overlay->msgid_plural) {
        # This is a fatal error as GNU gettext cannot grok with
        # this case.
        # See https://savannah.gnu.org/bugs/index.php?48411
        $self->__conflict($entry, $overlay,
                          __"conflicting plural forms");
    }

    # If one of the two entries currently has no plural form, there is no
    # problem.
    $entry->msgid_plural($overlay->dequote($overlay->msgid_plural)) 
        if defined $overlay->msgid_plural;

    my $new_ref = $overlay->reference;
    my $reference = $entry->reference;
    my @lines = split "\n", $reference;
    if (!@lines) {
        push @lines, $new_ref;
    } else {
        my $last_line = $lines[-1];
        my $ref_length = 1 + length $new_ref;

        if ($ref_length > 76) {
                push @lines, $new_ref;
        } elsif ($ref_length + length $last_line > 76) {
                push @lines, $new_ref;
        } else {
                $lines[-1] .= ' ' . $new_ref;
        }
    }

    $entry->reference(join "\n", @lines);

    $entry->fuzzy($overlay->fuzzy) if $overlay->fuzzy;
    if (defined $entry->comment) {
        $entry->comment(join "\n", $entry->comment, $overlay->comment);
    } else {
        $entry->comment($overlay->comment) if defined $overlay->comment;
    }
    if (defined $entry->automatic) {
        $entry->automatic(join "\n", $entry->automatic, $overlay->automatic);
    } else {
        $entry->automatic($overlay->automatic) if defined $overlay->automatic;
    }

    # Locale::PO does not allow to iterate over the flags.  We have to
    # use the private property directly.
    my @flags = @{$overlay->{_flags} || []};
    foreach my $flag (@flags) {
        if ($flag =~ /^no-(.*)/) {
           $self->__conflict($entry, $overlay,
                             __x"conflicting flags")
               if $entry->has_flag($1);
        } elsif ($entry->has_flag("no-$flag")) {
           $self->__conflict($entry, $overlay,
                             __x"conflicting flags");
        }
        $entry->add_flag($flag) if !$entry->has_flag($flag);
    }

    return $self;
}

sub __conflict {
    my ($self, $old, $new, $msg) = @_;

    my $old_ref = $old->reference;
    my $new_ref = $new->reference;

    die __x(<<EOF, new_ref => $new_ref, old_ref => $old_ref, msg => $msg);
{new_ref}: conflicts with ...
{old_ref}: {msg}
EOF
}

1;
