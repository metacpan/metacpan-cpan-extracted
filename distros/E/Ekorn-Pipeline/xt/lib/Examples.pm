use v5.36;

package Examples;

# Finding the Perl examples in the docs, and what their comments say
# they print, for xt/howto.t and xt/examples.t (roadmap 2026-0053). An
# example marked as not run is left out: in Markdown, by
# <!-- not run --> on the line before it; in POD, by =for not-run, a
# paragraph every formatter leaves out.
#
# What an example prints is in its comments:
#
# - a comment at the end of a line that prints, with say or print, is
#   what that line prints;
# - comment lines straight after a line that prints, with no comment of
#   its own, or after the end of a block that prints, are what it
#   prints, a line each.
#
# In either, ... stands for any text, such as a file's path or a line
# number.

use Exporter qw(import);

our @EXPORT_OK = qw(md_examples pod_examples expected matches);

# Return the Perl examples in a Markdown file, each as the line it starts
# at and its code, up to a line that's $before, if given.
sub md_examples ($file, $before = undef) {
    my @lines = _lines($file);
    my(@examples, $code, $start, $skip);
    for my $n (1 .. @lines) {
        my $line = $lines[$n - 1];
        last if defined $before && $line eq "$before\n";
        if (defined $code && $line =~ m( \A ``` \s* \z )x) {
            push @examples, [$start, $code] unless $skip;
            ($code, $skip) = (undef, 0);
        }
        elsif (defined $code) {
            $code .= $line;
        }
        elsif ($line =~ m( \A ```perl \s* \z )x) {
            ($code, $start) = ('', $n + 1);
        }
        else {
            # The marker counts for the next example, if nothing else
            # comes between them.
            $skip = $line =~ m( \A <!--\ not\ run\ --> )x
                if $line =~ m( \S )x;
        }
    }
    return @examples;
}

# Return the examples in a POD file, each as the line it starts at and
# its code: its verbatim paragraphs, those with only blank lines between
# them taken together.
sub pod_examples ($file) {
    my @lines = _lines($file);
    my(@examples, $code, $start, $blanks, $skip);
    for my $n (1 .. @lines) {
        my $line = $lines[$n - 1];
        if ($line =~ m( \A [\ \t]+ \S )x) {
            ($code, $start, $blanks) = ('', $n, 0) unless defined $code;
            $code   .= ("\n" x $blanks) . $line;
            $blanks  = 0;
        }
        elsif ($line !~ m( \S )x) {
            $blanks++ if defined $code;
        }
        else {
            push @examples, [$start, $code] if defined $code && !$skip;
            $skip = 0 if defined $code;
            undef $code;
            $skip = 1 if $line =~ m( \A =for \s+ not-run \s* \z )x;
        }
    }
    push @examples, [$start, $code] if defined $code && !$skip;
    return @examples;
}

# Return what an example's comments say it prints, a line each.
sub expected ($code) {
    my(@lines, $after, $pending);
    for my $line (split m( \n )x, $code) {
        if ($line !~ m( \S )x) {
            ($after, $pending) = (0, 0);
        }
        elsif ($line =~ m( \A \s* \# \  ?(.*) \z )x) {
            push @lines, $1 if $after;
        }
        else {
            my $prints = $line =~ m( \b (?: say | print ) \b )x;
            my($said) = $line =~ m( ;? \s{2,} \# \  (.*) \z )x;
            if ($prints && defined $said) {
                push @lines, $said;
                $after = 0;
            }
            elsif ($prints) {
                ($after, $pending) = (1, 1);
            }
            else {
                # The end of a block that prints.
                $after = $pending && $line =~ m( \A \s* [\}\)] )x;
            }
        }
    }
    return @lines;
}

# Return true if a line printed is what a comment says, where ... stands
# for any text.
sub matches ($printed, $said) {
    my $pattern = join '.*', map { quotemeta } split m( \.\.\. )x, $said, -1;
    return $printed =~ m( \A $pattern \z )xs;
}

# Return the lines of a file.
sub _lines ($file) {
    open my $in, '<', $file or die "Can't read $file: $!";
    my @lines = <$in>;
    close $in;
    return @lines;
}

1;
