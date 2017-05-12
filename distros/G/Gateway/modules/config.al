# config.al -- Configuration file parsing.  -*- perl -*-
# $Id: config.al,v 0.4 1998/04/12 17:28:20 eagle Exp $
#
# Copyright 1997, 1998 by Russ Allbery <rra@stanford.edu>
#
# This program is free software; you may redistribute it and/or modify it
# under the same terms as Perl itself.  This is a News::Gateway module and
# requires News::Gateway to be used.

package News::Gateway;

############################################################################
# Methods
############################################################################

# The core method.  Takes a configuration directive and a list of arguments
# and calls the appropriate module callbacks with those directives and
# arguments.  We fail with an error if no hooks are registered.  Directives
# are case-insensitive.
sub config {
    my ($self, $directive, @arguments) = @_;
    my $methods = $$self{confhooks}{lc $directive}
        or $self->error ("Unknown configuration directive $directive");
    for (@$methods) {
        my $method = $_ . '_conf';
        $self->$method (lc $directive, @arguments);
    }
}

# Parses a single line, splitting it on whitespace, and returns the
# resulting array.  Double quotes are supported for arguments that have
# embedded whitespace, and backslashes escape the next character (whatever
# it is).  Any text outside of double quotes is automatically lowercased,
# but anything inside quotes is left alone.  We can't use Text::ParseWords
# because it's too smart for its own good.
sub config_parse {
    my ($self, $line) = @_;
    my (@args, $snippet);
    while ($line ne '') {
        $line =~ s/^\s+//;
        $snippet = '';
        while ($line !~ /^\s/ && $line ne '') {
            my $tmp;
            if (index ($line, '"') == 0) {
                $line =~ s/^\"((?:[^\"\\]|\\.)+)\"//s
                    or $self->error ("Parse error in '$line'");
                $tmp = $1;
            } else {
                $line =~ s/^((?:[^\\\"\s]|\\.)+)//s;
                $tmp = lc $1;
            }
            $tmp =~ s/\\(.)/$1/g;
            $snippet .= $tmp;
        }
        push (@args, $snippet);
    }
    @args;
}

# Parses a single configuration line, breaking up the arguments using
# config_parse() and then passing them on to config().
sub config_line {
    my ($self, $line) = @_;
    my @line = $self->config_parse ($line);
    $self->config (@line);
}

# Reads in a configuration file, taking either a scalar or a reference to a
# file glob or file handle.  Blank lines and lines beginning with # are
# ignored.  Each valid directive is passed to config_line for processing
# (this separation is so that other programs can call config_line separately
# and just pass it a line of text).  A line ending in a backslash is
# considered to be continued on the next line, but note that the newline is
# passed along to the parser (which means that newlines inside double quotes
# will be preserved).
sub config_file {
    my ($self, $config) = @_;
    unless (ref $config) {
        open (CONFIG, $config)
            or $self->error ("Cannot open file $config: $!");
        $config = \*CONFIG;
    }
    local $_;
    while (<$config>) {
        s/^\s+//;
        next if (/^\#/ || /^$/);
        s/\s+$//;
        while (/\\$/) {
            my $next = <$config>;
            $next =~ s/\s+$//;
            s/\\$/\n$next/;
        }
        $self->config_line ($_);
    }
}

1;
