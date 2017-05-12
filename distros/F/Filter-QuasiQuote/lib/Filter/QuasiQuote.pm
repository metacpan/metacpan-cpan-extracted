package Filter::QuasiQuote;

use strict;
no warnings;
#use Smart::Comments;

our $VERSION = '0.07';

use Filter::Util::Call qw(filter_read);

our $Debug;

sub import {
    my ($type, @arguments) = @_ ;
    #warn $type;
    my ($package, $filename, $line) = caller;
    #warn "$package";
    my $self = bless {
        file => $filename,
        line => $line,
        quoted => undef,
        method => undef,
        ignore_once => undef,
        pos_diff => 0,
    }, $type;
    Filter::Util::Call::real_import($self, $package, 0) ;
}

sub filter {
    my ($self) = @_ ;
    #warn "SELF: $self";
    my($status) ;

    $status = filter_read;
    #warn scalar(s/\r//g);
    #warn "Last char: ", ord(substr($_, -1, 1));
    my $changed;
    if ($status > 0) {
        $self->{pos_diff} = 0;
        $self->{line}++;
        my ($i, $buf);
        while (1) {
            $i++;
            $self->debug("Pos ", pos, ", Pass $i, Line $self->{line}");
            if (/\G\s+/gc) { $buf .= $& }
            if (/\G\[:(\w+)\|(.*?)\|\]/gc) {
                #warn "$1 => $2";
                my ($meth, $s) = ($1, $2);
                my $len = length($&);
                my $to = pos;

                if (defined $self->{method}) {
                    die "Syntax error at $self->{file}, line $self->{line}: Quasiquotes cannot be nested.\n";
                }

                #warn "to: $to\n";
                #warn "len: $len\n";
                if ($self->can($meth)) {
                    #warn "POS diff: $self->{pos_diff}";
                    my $col = $to - $self->{pos_diff} - $len + 1;
                    my $res = $self->$meth($s, $self->{file}, $self->{line}, $col);
                    #$self->debug("Pos BEFORE change \$_: ", pos($_));
                    substr($_, $to - $len, $len, $res);
                    $changed = 1; pos($_) = $to - $len + length($res);
                    $self->{pos_diff} = length($res) - $len;
                    #$self->debug("Pos AFTER change \$_: ", pos($_));
                    ### $_
                }
            }
            elsif (/\G\[:(\w+)\|(.*)/gc) {
                my ($meth, $s) = ($1, $2);
                my $len = length($&);
                my $to = pos $_;
                #warn "len: $len to: $to match: $&\n";
                if (!$self->can($meth)) {
                    $self->debug("Ignoring starting $meth at $self->{line} (pos $to, pass $i)");
                    $self->{ignore_once} = 1;
                    #$self->{method} = $meth;
                    last;
                }

                substr($_, $to - $len, $len, ' ');
                $changed = 1;
                my $col = $to - $self->{pos_diff} - $len + 1;
                $self->{saved_pos} = [$self->{line}, $col];
                ### $_

                if (!defined $self->{method}) {
                    $self->{quoted} = $s;
                    $self->{method} = $meth;
                } else {
                    die "Syntax error at $self->{file}, line $self->{line}: Quasiquotes cannot be nested.\n";
                }
                last;
            }
            elsif (/\G\|\]/gc) {
                my $s = $buf;
                my $len = length($buf . $&);
                my $to = pos;
                $self->debug("Found closing tag: ", ref $self, " (pos $to, pass $i, line $self->{line})");
                if ($self->{ignore_once}) {
                    $self->debug("Ignoring closing $self->{method} at $self->{line} (pos $to, pass $i)") if $self->{method};
                    undef $self->{ignore_once};
                    undef $self->{method};
                    undef $self->{quoted};
                    next;
                }

                my $meth = $self->{method};
                if (!defined $meth) {
                    #warn $self;
                    #warn "POS: ", pos;
                    die ref $self, ": Syntax error at $self->{file}, line $self->{line}: Pending closing quasiquote. (pos $to, pass $i)\n";
                }
                #warn "POS diff: $self->{pos_diff}";
                my $pos = $self->{saved_pos};
                my ($line, $col);
                if (!$pos) { $line = $self->{line}; $col = 0 }
                else { ($line, $col) = @$pos }
                my $res = $self->$meth($self->{quoted} . $s, $self->{file}, $line, $col);
                undef $self->{method};
                undef $self->{quoted};
                substr($_, $to - $len, $len, $res);
                $changed = 1; pos($_) = $to - $len + length($res);
                $self->{pos_diff} = length($res) - $len;

                #$changed = 1;
            }
            elsif (/\G[^\|\[]+|\G./gc) {
                #print "Ignored: $_";
                #last;
                #warn $&;
                $buf .= $&;
            }
            else {
                last;
            }
        }
        if (!$changed && defined $self->{method}) {
            $self->{quoted} .= $_;
            $_ = "\n"; $changed = 1;
        }
        #warn "$self->{file}: line $self->{line}: $_";
    }
    $self->debug("Processed: (line $self->{line}): $_") if $changed;
    s/\n//gs;
    $_ .= "\n" unless substr($_, -1, 1) eq "\n";
    #warn $status;
    $status ;
}

sub debug {
    my $self = shift;
    warn ref $self, ": ", join('', @_), "\n" if $Debug;
}

1;
__END__

=head1 NAME

Filter::QuasiQuote - Quasiquoting for Perl

=head1 VERSION

This document describes Filter::QuasiQuote 0.07 released on August 20, 2008.

=head1 SYNOPSIS

    package MyFilter;

    require Filter::QuasiQuote;
    our @ISA = qw( Filter::QuasiQuote );

    sub my_filter {
        my ($self, $s, $file, $line, $col) = @_;
        # parse the dsl source in $s and emit the perl source in ONE LINE
        return generate_perl_source( parse_dsl( $s ) );
    }

    # and in another file:
    use MyFilter;

    [:my_filter|This is my little DSL...|]

=head1 DESCRIPTION

GHC 6.10.x is going to have a nice quasiquoting feature for
Haskell:

L<http://www.eecs.harvard.edu/~mainland/ghc-quasiquoting/>

This module implements similar quasiquoting syntax for Perl by
means of carefully designed source filters.

The user can subclass C<Filter::QuasiQuote> and define her own DSL
extensions. Besides, multiple concrete quasiquoting filters can be
chained and composed within a single Perl file.

Special efforts have been made to ensure line numbers for the
resulting Perl source won't be corrupted and support for precise
file position information is also provided to user's DSL compilers
as well.

This work is still in B<alpha> phase and under active development. So please check back often ;)

=head1 EXAMPLES

=over

=item SQL auto-quoter

The concrete filter class could be defined as follows:

    # QuoteSQL.pm
    package QuoteSQL;

    require Filter::QuasiQuote;
    our @ISA = qw( Filter::QuasiQuote );

    sub sql {
        my ($self, $s, $file, $line, $col) = @_;
        my $package = ref $self;
        #warn "SQL: $file: $line: $s\n";
        $s =~ s/\n+/ /g;
        $s =~ s/^\s+|\s+$//g;
        $s =~ s/\\/\\\\/g;
        $s =~ s/"/\\"/g;
        $s =~ s/\$\w+\b/".${package}::Q($&)."/g;
        $s = qq{"$s"};
        $s =~ s/\.""$//;
        $s;
    }

    sub Q {
        my $s = shift;
        $s =~ s/'/''/g;
        $s =~ s/\\/\\\\/g;
        $s =~ s/\n/ /g;
        "'$s'";
    }

    1;

And then use it this way:

    use QuoteSQL;

    my $sql = [:sql|
        select id, title
        from posts
        where id = $id and title = $title |];

which is actually equivalent to

    my ($id, $title) = (32, 'Hello');
    my $sql =
        "select id, title from posts where id = ".quote($id);

=back

=head1 INTERNAL METHODS

The following methods are internal and are not intended to call directly.

=over

=item debug

Used to print debug info to stderr when C<$Filter::QuasiQuote::Debug> is set to 1.

=item filter

Main filter function which is usually inherited by concrete filter subclasses.

=back

=head1 CAVEATS

Subclasses of C<Filter::QuasiQuote> should NOT use it directly. For example, the following will break things:

    use Filter::QuasiQuote; # BAD!!!
    use base 'Filter::QuasiQuote'; # BAD TOO!!!

Because One should never call the C<import> method of Filter::QuasiQuote directly. (Perl's C<use> statement calls its C<import> automatically while the C<require> statement does not.)

=head1 TODO

=over

=item *

Use L<Module::Compile>'s F<.pmc> trick to cache the filters' results onto disks.

=back

=head1 BUGS

Please report bugs or send wish-list to the CPAN RT site:

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Filter-QuasiQuote>.

=head1 VERSION CONTROL

For the very latest version of this module, check out the source from
the SVN repos below:

L<http://svn.openfoundry.org/filterquote>

There is anonymous access to all. If you'd like a commit bit, please let
me know. :)

=head1 AUTHOR

Agent Zhang C<< <agentzh@yahoo.cn> >>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2008 by Agent Zhang (agentzh).

This software is released under the MIT license cited below.
The "MIT" License

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

=head1 SEE ALSO

=over

=item Quasiquoting support in Haskell (via GHC)

L<http://www.eecs.harvard.edu/~mainland/ghc-quasiquoting/>,

=item Related CPAN modules

L<Filter::Util::Call>, L<Filter::Simple>, L<Module::Compile>.

=back

