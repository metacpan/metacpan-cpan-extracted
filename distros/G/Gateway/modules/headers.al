# headers.al -- Rewrite and trim mail headers.  -*- perl -*-
# $Id: headers.al,v 0.5 1998/04/12 11:14:28 eagle Exp $
#
# Copyright 1997, 1998 by Russ Allbery <rra@stanford.edu>
#
# This program is free software; you may redistribute it and/or modify it
# under the same terms as Perl itself.  This is a News::Gateway module and
# requires News::Gateway to be used.

# @@ Interface:  ['header']

package News::Gateway;

############################################################################
# Configuration directives
############################################################################

# Add a single header rewrite rule.  We check to make sure the action is one
# that we support and then do variable substitution; $n becomes the name of
# the running program, $v becomes the version, and $i becomes a (hopefully
# unique) identifier built from the time and the process ID.  We also allow
# $$ to mean $ just in case.
sub headers_conf {
    my ($self, $directive, $header, $action, $replacement) = @_;
    my $actions = 'add|rename|ifempty|drop|replace|prepend|reject';
    unless ($action =~ /^($actions)$/o) {
        $self->error ("Unknown header rewrite action $action");
    }
    if (defined $replacement) {
        $replacement =~ s/((?:^|[^\$])(?:\$\$)*)\$n/$1$0/g;
        $replacement =~ s/((?:^|[^\$])(?:\$\$)*)\$v/$1$VERSION/g;
        $replacement =~ s%((?:^|[^\$])(?:\$\$)*)\$i%$1@{[time]}/$$%g;
        $replacement =~ s/\$\$/\$/g;
    }
    push (@{$$self{headers}{lc $header}}, [ $action, $replacement ]);
}


############################################################################
# Post rewrites
############################################################################

# Apply all transformations to the headers requested by header lines in the
# configuration file.  We support six directives:  drop deletes a header,
# rename renames the original header to X-Original-<header>, add adds a new
# header with the given content, ifempty sets a value for a header iff the
# header is empty, replace replaces the current header contents with the
# given new content, prepend adds the new content to the beginning of the
# current header (or creates a new header if none exists), and reject
# returns an error message if that header is present.
sub headers_mesg {
    my $self = shift;

    # Iterate through all rewrite rules we have saved and apply each one of
    # them individually.  Note that for each header we have an anonymous
    # array of anonymous arrays, where each anonymous array contains the
    # action and the replacement if any.
    my $fixes = $$self{headers};
    my $article = $$self{article};
    for (keys %$fixes) {
        my $fix;
        for $fix (@{$$fixes{$_}}) {
            my ($action, $content) = @$fix;
            if ($action eq 'drop') {
                $article->drop_headers ($_);
            } elsif ($action eq 'rename') {
                $article->rename_header ($_, "x-original-$_", 'add');
            } elsif ($action eq 'add') {
                $article->add_headers ($_, $content);
            } elsif ($action eq 'ifempty') {
                my $current = $article->header ($_);
                undef $current if ($_ eq 'subject' && $current eq '(none)');
                if (!$current) {
                    $article->set_headers ($_, $content);
                }
            } elsif ($action eq 'replace') {
                $article->set_headers ($_, $content);
            } elsif ($action eq 'prepend') {
                my @current = $article->header ($_);
                $current[0] = $content . ($current[0] ? $current[0] : "");
                $article->set_headers ($_, [ @current ]);
            } elsif ($action eq 'reject' && $article->header ($_)) {
                return "Invalid header $_";
            }
        }
    }
    undef;
}

1;
