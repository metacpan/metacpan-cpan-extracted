package Encode::Newlines;

use 5.007003;
use strict;
use warnings;

our $VERSION = '0.05';
our $AllowMixed = 0;

use parent qw(Encode::Encoding);
use constant CR => "\015";
use constant LF => "\012";
use constant CRLF => "\015\012";
use constant Native => (
    ($^O =~ /^(?:MSWin|cygwin|dos|os2)/) ? CRLF :
    ($^O =~ /^MacOS/) ? CR : LF
);

foreach my $in (qw( CR LF CRLF Native )) {
    foreach my $out (qw( CR LF CRLF Native )) {
        no strict 'refs';
        my $name = (($in eq $out) ? $in : "$in-$out");

        $Encode::Encoding{$name} = bless {
            Name => $name,
            decode => &$in,
            encode => &$out,
        } => __PACKAGE__;
    }
};

foreach my $func (qw( decode encode )) {
    no strict 'refs';
    *$func = sub ($$;$) {
        my ($obj, $str, $chk) = @_;

        if ($AllowMixed) {
            $str =~ s/(?:\015\012?|\012)/$obj->{$func}/g;
        }
        elsif ($str =~ /((?:\015\012?|\012))/) {
            my $eol = $1;

            if ($eol eq CRLF) {
                require Carp;
                Carp::croak('Mixed newlines')
                    if $str =~ /\015(?!\012)|(?<!\015)\012/;
            }
            else {
                require Carp;
                Carp::croak('Mixed newlines')
                    if index($str, (($eol eq CR) ? LF : CR)) >= 0;
            }

            $str =~ s/$eol/$obj->{$func}/g;
        }

        $_[1] = '' if $chk;
        return $str;
    }
}

sub perlio_ok { 0 }

1;
__END__

=head1 NAME

Encode::Newlines - Normalize line ending sequences

=head1 VERSION

This document describes version 0.04 of Encode::Newlines, released 
September 4, 2007.

=head1 SYNOPSIS

    use Encode;
    use Encode::Newlines;

    # Convert to native newlines
    # Note that decode() and encode() are equivalent here
    $native = decode(Native => $string);
    $native = encode(Native => $string);

    {
        # Allow mixed newlines in $mixed
        local $Encode::Newlines::AllowMixed = 1;
        $cr = encode(CR => $mixed);
    }

=head1 DESCRIPTION

This module provides the C<CR>, C<LF>, C<CRLF> and C<Native> encodings,
to aid in normalizing line endings.

It converts whatever line endings the source uses to the designated newline
sequence, for both C<encode> and C<decode> operations.

If you specify two different line endings joined by a C<->, it will use the
first one for decoding and the second one for encoding.  For example, the
C<LF-CRLF> encoding means that all input should be normalized to C<LF>, and
all output should be normalized to C<CRLF>.

If the source has an inconsistent line ending style, then a C<Mixed newlines>
exception is raised on behalf of the caller.  However, if the package variable
C<$Encode::Newlines::AllowMixed> is set to a true value, then it will silently
convert all three line endings.

=head1 CAVEATS

This module is not suited for working with L<PerlIO::encoding>, because it
cannot guarantee that the chunk bounaries won't happen within a CR/LF 
sequence.  See L<PerlIO::eol> for how to deal with this correctly.

An optional XS implemenation would be nice.

=head1 AUTHORS

Audrey Tang E<lt>audreyt@audreyt.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2004-2007 by Audrey Tang E<lt>audreyt@audreyt.orgE<gt>.

This program is free software; you can redistribute it and/or 
modify it under the same terms as Perl itself.

See L<http://www.perl.com/perl/misc/Artistic.html>

=cut
