# Copyright (C) 2016-2017 Guido Flohr <guido.flohr@cantanea.com>,
# all rights reserved.

# This file is distributed under the same terms and conditions as
# Perl itself.

# This next lines is here to make Dist::Zilla happy.
# ABSTRACT: Perl Globstar (double asterisk globbing) and utils

package File::Globstar;

use strict;

use File::Glob qw(bsd_glob);
use Scalar::Util qw(reftype);
use File::Find;

use base 'Exporter';
use vars qw(@EXPORT_OK);
@EXPORT_OK = qw(globstar fnmatchstar translatestar quotestar);

sub _globstar;

sub empty($) {
    my ($what) = @_;

    return if defined $what && length $what;

    return 1;
}

sub _find_files($) {
    my ($directory) = @_;

    my $empty = empty $directory;
    $directory = '.' if $empty;

    my @hits;
    File::Find::find sub {
        return if -d $_;
        return if '.' eq substr $_, 0, 1;
        push @hits, $File::Find::name;
    }, $directory;

    if ($empty) {
        @hits = map { substr $_, 2 } @hits;
    }

    return @hits;
}

sub _find_directories($) {
    my ($directory) = @_;

    my $empty = empty $directory;
    $directory = '.' if $empty;

    my @hits;
    File::Find::find sub {
        return if !-d $_;
        return if '.' eq substr $_, 0, 1;
        push @hits, $File::Find::name;
    }, $directory;

    if ($empty) {
        @hits = map { substr $_, 2 } @hits;
    }

    return @hits;
}

sub _find_all($) {
    my ($directory) = @_;

    my $empty = empty $directory;
    $directory = '.' if $empty;

    my @hits;
    File::Find::find sub {
        return if '.' eq substr $_, 0, 1;
        push @hits, $File::Find::name;
    }, $directory;

    if ($empty) {
        @hits = map { substr $_, 2 } @hits;
    }

    return @hits;
}

sub _globstar($$;$) {
    my ($pattern, $directory, $flags) = @_;

    $directory = '' if !defined $directory;
    $pattern = $_ if !@_;

    if ('**' eq $pattern) {
        return _find_all $directory;
    } elsif ('**/' eq $pattern) {
        return map { $_ . '/' } _find_directories $directory;
    } elsif ($pattern =~ s{^\*\*/}{}) {
        my %found_files;
        foreach my $directory ('', _find_directories $directory) {
            foreach my $file (_globstar $pattern, $directory, $flags) {
                $found_files{$file} = 1;
            }
        }
        return keys %found_files;
    }

    my $current = $directory;
 
    # This is a quotemeta() that does not escape the slash and the
    # colon.  Escaped slashes confuse bsd_glob() and escaping colons
    # may make a full port to Windows harder.
    $current =~ s{([\x00-\x2e\x3b-\x40\x5b-\x60\x7b-\x7f])}{\\$1}g;
    if ($directory ne '' && '/' ne substr $directory, -1, 1) {
        $current .= '/';
    }
    while ($pattern =~ s/(.)//s) {
        if ($1 eq '\\') {
            $pattern =~ s/(..?)//s;
            $current .= $1;
        } elsif ('/' eq $1 && $pattern =~ s{^\*\*/}{}) {
            $current .= '/';

            # Expand until here.
            my @directories = bsd_glob $current, $flags;

            # And search in every subdirectory;
            my %found_dirs;
            foreach my $directory (@directories) {
                $found_dirs{$directory} = 1;
                foreach my $subdirectory (_find_directories $directory) {
                    $found_dirs{$subdirectory . '/'} = 1;
                }
            }

            if ('' eq $pattern) {
                my %found_subdirs;
                foreach my $directory (keys %found_dirs) {
                    $found_subdirs{$directory} = 1;
                    foreach my $subdirectory (_find_directories $directory) {
                        $found_subdirs{$subdirectory . '/'} = 1;
                    }
                }
                return keys %found_subdirs;
            }
            my %found_files;
            foreach my $directory (keys %found_dirs) {
                foreach my $hit (_globstar $pattern, $directory, $flags) {
                    $found_files{$hit} = 1;
                }
            }
            return keys %found_files;
        } elsif ('**' eq $pattern) {
            my %found_files;
            foreach my $directory (bsd_glob $current, $flags) {
                $found_files{$directory . '/'} = 1;
                foreach my $file (_find_all $directory) {
                    $found_files{$file} = 1;
                }
            }
            return keys %found_files;
        } else {
            $current .= $1;
        }
    }

    # Pattern without globstar.  Just return the normal expansion.
    return bsd_glob $current, $flags;
}

sub globstar {
    my ($pattern, $flags) = @_;

    # The double asterisk can only be used in place of a directory.
    # It is illegal everywhere else.
    my @parts = split /\//, $pattern;
    foreach my $part (@parts) {
        $part ne '**' and 0 <= index $part, '**' and return;
    }

    return _globstar $pattern, '', $flags;
}

sub quotestar {
    my ($string, $listmatch) = @_;

    $string =~ s/([\\\[\]*?])/\\$1/g;
    $string =~ s/^!/\\!/ if $listmatch;
    
    return $string;
}

sub _transpile_range($) {
    my ($range) = @_;

    # Strip-off enclosing brackets.
    $range = substr $range, 1, -2 + length $range;

    # Replace leading exclamation mark with caret.
    $range =~ s/^!/^/;

    # Backslashes escape inside Perl ranges but not in ours.  Escape them:
    $range =~ s/\\/\\\\/g;

    # Quote dots and equal sign to prevent Perl from interpreting 
    # equivalence and collating classes.
    $range =~ s/\./\\\./g;
    $range =~ s/\=/\\\=/g;
    
    return "[$range]";
}

sub translatestar {
    my ($pattern, %options) = @_;

    $pattern =~ s
                {
                    (.*?)               # Anything, followed by ...
                    (  
                       \\.              # escaped character
                    |                   # or
                       \A\*\*(?=/)      # leading **/
                    |                   # or
                       /\*\*(?=/|\z)    # /**/ or /** at end of string
                    |                   # or
                      \*\*.             # invalid
                    |                   # or
                      .\*\*             # invalid
                    |                   # or
                       \.               # a dot
                    |                   # or
                       \*               # an asterisk
                    |
                       \?               # a question mark
                    |
                       \[               # opening bracket
                       !?
                       \]?              # possible (literal) closing bracket
                       (?:
                       \\.              # escaped character
                       |
                       \[:[a-z]+:\]     # character class
                       |
                       [^\\\]]+         # non-backslash or closing bracket
                       )+
                       \]
                    )?
                }{
                    my $translated = quotemeta $1;
                    if ('\\' eq substr $2, 0, 1) {
                        $translated .= quotemeta substr $2, 1, 1;
                    } elsif ('**' eq $2) {
                        $translated .= '.*';
                    } elsif ('/**' eq $2) {
                        $translated .= '/.*';
                    } elsif ('.' eq $2) {
                        $translated .= '\\.';
                    } elsif ('*' eq $2) {
                        $translated .= '[^/]*';
                    } elsif ('?' eq $2) {
                        $translated .= '[^/]';
                    } elsif ('[' eq substr $2, 0, 1) {
                        $translated .= _transpile_range $2;
                    } elsif (length $2) {
                        if ($2 =~ /\*\*/) {
                            die "invalid use of double asterisk";
                        }
                        die "should not happen: $2"; 
                    }
                    $translated;
                }gsex;

    return $options{ignoreCase} ? qr/^$pattern$/i : qr/^$pattern$/;
}

sub fnmatchstar {
    my ($pattern, $string, %options) = @_;

    my $transpiled = eval { translatestar $pattern, %options };
    if ($@) {
        if ($options{ignoreCase}) {
            lc $pattern eq lc $string or return;
        } else {
            $pattern eq $string or return;
        }

        return 1;
    }

    $string =~ $transpiled or return;

    return 1;
}

1;

