package IO::Unread;

use 5.008001;

use warnings;
use strict;

use Carp;
use XSLoader;
use Symbol qw/qualify_to_ref/;
use Scalar::Util qw/openhandle/;

BEGIN {
    our $VERSION   = '1.04';
    XSLoader::load __PACKAGE__, $VERSION;
}

my $USE_PERLIO = HAVE_PERLIO_LAYERS;
my $Debug;

sub debug {
    my $func = (caller 1)[3];
    $Debug and warn "$func: ", @_;
}

sub import {
    no strict 'refs';
    my $from = shift;
    my $to   = caller;
    my @carp;
    
    while ($_ = shift) {
        /^-tie$/ and do {
            $USE_PERLIO = 0;
            next;
        };

        /^-debug$/ and do {
            $Debug = 1;
            debug "debugging on";
            next;
        };
        
        s/^&//;
        !/^_/ and /[^[:upper:]]/ and 
            exists &{"$from\::$_"} and do
        {
            *{"$to\::$_"} = \&{"$from\::$_"};
            next;
        };

        push @carp, qq/"$_" is not exported by $from/;
    }
    
    @carp and do {
        carp $_ for @carp;
        croak "can't continue after import errors";
    };

    debug "import done";
}

sub _get_fh {
    my $fh = do {
        local $^W = 0;
        qualify_to_ref shift, caller 2;
    };
    openhandle $fh or return;
    debug "fh open";
    _check_fh $fh  or return;
    debug "fh mode good";
    return $fh;
}

sub unread (*@) {
    {
        no warnings 'uninitialized';
        debug '[', (join '][', @_), ']';
    }
    
    my $fh = _get_fh shift or return;
    
    my $str = @_ ? (join "", reverse @_) : $_;
    length $str or return "0 but true";

    my $rv;
    undef $@;
    if ($USE_PERLIO) {
        debug "using PerlIO_unread";
        $rv = eval { _PerlIO_unread $fh, $str };
    }
    else {
        debug "using IO::Unread::Tied";
        tie *$fh, 'IO::Unread::Tied' => $fh, $str;
        $rv = length $str;
    }

    if ($@) {
        warnings::enabled "io" and carp $@;
	return;
    }
    defined $rv or return;
    $rv         or return "0 but true";
    return $rv;
}

sub ungetc (*;$) {
    my $fh = _get_fh shift or return;
   
    my $str = @_ ? shift : $_;
    length $str or return '';
    
    my $rv = _PerlIO_ungetc $fh, substr $str, 0, 1;
    defined $rv or return;
    return $rv;
}

{{

package IO::Unread::Tied;

use Tie::Handle 4.0;
use base qw/Tie::Handle/;
use Carp;
BEGIN { *debug = \&IO::Unread::debug }

sub TIEHANDLE {
    my ($c, $handle, $data) = @_;
    debug $data;
    $handle eq 'RETIE' and (debug "retieing"), return $data;
    length $data or croak __PACKAGE__."::TIEHANDLE called with null data";
    return bless { handle => $handle, data => $data }, $c;
}

sub WRITE {
    my ($s, $data, $len, $off) = @_;
    debug;
    my $h = $s->{handle};
    untie *$h;
    my $rv = print $h substr $data, 0, $off;
    tie *$h, ref $s => RETIE => $s;
    return $rv;
}

sub READ {
    my ($s, undef, $len, $off) = @_;
    my $h    = $s->{handle};
    my $rv   = $len;

    debug;

    my $read = substr $s->{data}, 0, $len, '';
    $len -= length $read;
    unless (length $s->{data}) {
        untie *$h;
        $rv = read $h, $read, $len, length $read;
        defined $rv and $rv += length $read;
    }
    
    substr($_[1], $off, 0) = $read;
    return $rv;
}

sub READLINE {
    my $s   = shift;
    my $h   = $s->{handle};
    my $rv;

    debug;
    
    if (not defined $/) {
        untie *$h;
        return $s->{data} . <$h>;
    }
    
    if ($/ eq '') {
        $rv = $s->{data} =~ s!^ ([^\n]* \n+)!!x;
        $rv = $rv ? $1 : undef;
    }
    else {
        $rv = $s->{data} =~ s!^ (.*? \Q$/\E )!!x;
        $rv = $rv ? $1 : undef;
    }

    debug "rv = ", (defined $rv) ? (quotemeta $rv) : "(undef)";

    unless (defined $rv) {
        $rv = $s->{data};
        $s->{data} = '';
    }

    if ($s->{data} eq '') {
        untie *$h;
        
        my $done = $rv =~ m! \Q$/\E $ !x;
        if ($/ eq '') {
            my $chr = getc $h;
            IO::Unread::ungetc $h, $chr;
            $done = ($chr ne "\n");
        }
        debug "rv = |$rv|, \$/ = |$/|, done = $done";
        $rv .= <$h> unless $done;
    }
    debug "rv = $rv";

    return $rv;
}

sub CLOSE {
    untie *{$_[0]{handle}};
    close $_[0]{handle};
}

sub SEEK {
    my $s = shift;
    untie *{$s->{handle}};
    seek $s->{handle}, $_[0], $_[1];
}

sub TELL {
    untie *{$_[0]{handle}};
    tell $_[0]{handle};
}

sub UNTIE {
    debug;
}

}}

42;

=head1 NAME

IO::Unread - push more than one character back onto a filehandle

=head1 SYNOPSIS

    use IO::Unread;

    unread STDIN, "hello world\n";

    $_ = "goodbye";
    unread ARGV;

=head1 DESCRIPTION

C<IO::Unread> exports one function, C<unread>, which will push data back
onto a filehandle. Any amount of data can be pushed: if your perl is
built with PerlIO layers, the data is stored in a special C<:pending>
layer; if not, the module C<tie>s the filehandle to a class which
returns the unread data and unties itself.

=head2 unread FILEHANDLE, LIST

C<unread> unreads LIST onto FILEHANDLE. If LIST is omitted, C<$_> is unread.
Returns the number of characters unread on success, C<undef> on failure. Warnings 
are produced under category C<io>.

Note that C<unread $FH, 'a', 'b'> is equivalent to

  unread $FH, 'a';
  unread $FH, 'b';

, ie. to C<unread $FH, 'ba'> rather than C<unread $FH, 'ab'>.

=head2 ungetc FILEHANDLE, STRING

C<ungetc> pushes the first character of STRING onto FILEHANDLE. Unlike
C<unread>, it does not use a C<tie> implementation if your perl doesn't
support PerlIO layers; rather it calls your I<ungetc(3)>. This is only
guarenteed to support one character of pushback, and then only if it is
the last character that was read from the handle.

=head1 EXPORTS

None by default; C<unread>, C<ungetc> on request.

=head1 BUGS

C<ungetc> is subject to the whims of your libc if you're not using
perlio.

=head1 COPYRIGHT

Copyright 2003 Ben Morrow <ben@morrow.me.uk>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<PerlIO>, L<perltie>, L<ungetc(3)>

=cut
