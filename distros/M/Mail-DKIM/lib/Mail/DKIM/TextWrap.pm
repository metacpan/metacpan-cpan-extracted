package Mail::DKIM::TextWrap;
use strict;
use warnings;
our $VERSION = '1.20220520'; # VERSION
# ABSTRACT: text wrapping module written for use with DKIM

use Carp;


sub new {
    my $class = shift;
    my %args  = @_;
    my $self  = {
        Margin      => 72,
        Break       => qr/\s/,
        BreakBefore => undef,
        Swallow     => qr/\s/,
        Separator   => "\n",
        cur         => 0,
        may_break   => 0,
        soft_space  => "",
        word        => "",
        %args,
    };
    $self->{Output} ||= \*STDOUT;
    return bless $self, $class;
}

# Internal properties:
#
# cur - the last known column position
#
# may_break - nonzero if the current location allows a linebreak
#
# soft_space - contains added text that will not be printed if a linebreak
#              occurs
#
# word - contains the current word

# Internal methods:
#
# _calculate_new_column() - determine where cur would be after adding some text
#
# my $new_cur = _calculate_new_column($cur, "some additional\ntext");
#
sub _calculate_new_column {
    my ( $cur, $text ) = @_;
    confess "invalid argument" unless defined($text);

    while ( $text =~ /^(.*?)([\n\r\t])(.*)$/s ) {
        $cur += length($1);
        if ( $2 eq "\t" ) {
            $cur = ( int( $cur / 8 ) + 1 ) * 8;
        }
        else {
            $cur = 0;
        }
        $text = $3;
    }
    $cur += length($text);
    return $cur;
}


sub add {
    my ( $self, $text ) = @_;
    my $break_after  = $self->{Break};
    my $break_before = $self->{BreakBefore};
    my $swallow      = $self->{Swallow};
    $self->{word} .= $text;
    while ( length $self->{word} ) {
        my $word;
        if ( defined($break_before)
            and $self->{word} =~ s/^(.+?)($break_before)/$2/s )
        {
            # note- $1 should have at least one character
            $word = $1;
        }
        elsif ( defined($break_after)
            and $self->{word} =~ s/^(.*?)($break_after)//s )
        {
            $word = $1 . $2;
        }
        elsif ( $self->{NoBuffering} ) {
            $word = $self->{word};
            $self->{word} = "";
        }
        else {
            last;
        }

        die "assertion failed" unless length($word) >= 1;

        my $next_soft_space;
        if ( defined($swallow) && $word =~ s/($swallow)$//s ) {
            $next_soft_space = $1;
        }
        else {
            $next_soft_space = "";
        }

        my $to_print = $self->{soft_space} . $word;
        my $new_pos = _calculate_new_column( $self->{cur}, $to_print );

        if ( $new_pos > $self->{Margin} && $self->{may_break} ) {

            # what would happen if we put the separator in?
            my $w_sep =
              _calculate_new_column( $self->{cur}, $self->{Separator} );
            if ( $w_sep < $self->{cur} ) {

                # inserting the separator gives us more room,
                # so do it
                $self->output( $self->{Separator} );
                $self->{soft_space} = "";
                $self->{cur}        = $w_sep;
                $self->{word}       = $word . $next_soft_space . $self->{word};
                next;
            }
        }

        $self->output($to_print);
        $self->{soft_space} = $next_soft_space;
        $self->{cur}        = $new_pos;
        $self->{may_break}  = 1;
    }
}


sub finish {
    my $self = shift;
    $self->flush;
    $self->reset;
}


sub flush {
    my $self = shift;

    local $self->{NoBuffering} = 1;
    local $self->{Swallow}     = undef;
    $self->add("");
}

sub output {
    my $self     = shift;
    my $to_print = shift;

    my $out = $self->{Output};
    if ( UNIVERSAL::isa( $out, "GLOB" ) ) {
        print $out $to_print;
    }
    elsif ( UNIVERSAL::isa( $out, "SCALAR" ) ) {
        $$out .= $to_print;
    }
}

sub reset {
    my $self = shift;
    $self->{cur}        = 0;
    $self->{soft_space} = "";
    $self->{word}       = "";
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Mail::DKIM::TextWrap - text wrapping module written for use with DKIM

=head1 VERSION

version 1.20220520

=head1 DESCRIPTION

This is a general-purpose text-wrapping module that I wrote because
I had some specific needs with Mail::DKIM that none of the
contemporary text-wrapping modules offered.

Specifically, it offers the ability to change wrapping options
in the middle of a paragraph. For instance, with a DKIM signature:

  DKIM-Signature: a=rsa; c=simple; h=first:second:third:fourth;
          b=Xr2mo2wmb1LZBwmEJElIPezal7wQQkRQ8WZtxpofkNmXTjXf8y2f0

the line-breaks can be inserted next to any of the colons of the h= tag,
or any character of the b= tag. The way I implemented this was to
serialize the signature one element at a time, changing the
text-wrapping options at the start and end of each tag.

=head1 SYNOPSIS (FOR MAIL::DKIM USERS)

  use Mail::DKIM::TextWrap;

Just add the above line to any program that uses L<Mail::DKIM::Signer>
and your signatures will automatically be wrapped to 72 characters.

=head1 SYNOPSIS (FOR OTHER USERS)

  my $output = "";
  my $tw = Mail::DKIM::TextWrap->new(
                  Margin => 10,
                  Output => \$output,
              );
  $tw->add("Mary had a little lamb, whose fleece was white as snow.\n");
  $tw->finish;

  print $output;

=head1 TEXT WRAPPING OPTIONS

Text wrapping options can be specified when calling new(), or
by simply changing the property as needed. For example, to change
the number of characters allowed per line:

  $tw->{Margin} = 20;

=over

=item Break

a regular expression matching characters where a line break
can be inserted. Line breaks are inserted AFTER a matching substring.
The default is C</\s/>.

=item BreakBefore

a regular expression matching characters where a line break
can be inserted. Line breaks are inserted BEFORE a matching substring.
Usually, you want to use Break, rather than BreakBefore.
The default is C<undef>.

=item Margin

specifies how many characters to allow per line.
The default is 72. If no place to line-break is found on a line, the
line will extend beyond this margin.

=item Separator

the text to insert when a linebreak is needed.
The default is "\n". If you want to set a following-line indent
(e.g. all lines but the first begin with four spaces),
use something like "\n    ".

=item Swallow

a regular expression matching characters that can be omitted
when a line break occurs. For example, if you insert a line break
between two words, then you are replacing a "space" with the line
break, so you are omitting the space. On the other hand, if you
insert a line break between two parts of a hyphenated word, then
you are breaking at the hyphen, but you still want to display the
hyphen.
The default is C</\s/>.

=back

=head1 CONSTRUCTOR

=head2 new() - create a new text-wrapping object

  my $tw = Mail::DKIM::TextWrap->new(
                      Output => \$output,
                      %wrapping_options,
                  );

The text-wrapping object encapsulates the current options and the
current state of the text stream. In addition to specifying text
wrapping options as described in the section above, the following
options are recognized:

=over

=item Output

a scalar reference, or a glob reference, to specify where the
"wrapped" text gets output to. If not specified, the default of
STDOUT is used.

=back

=head1 METHODS

=head2 add() - process some text that can be wrapped

  $tw->add("Mary had a little lamb.\n");

You can add() all the text at once, or add() the text in parts by calling
add() multiple times.

=head2 finish() - call when no more text is to be added

  $tw->finish;

Call this when finished adding text, so that any remaining text
in TextWrap's buffers will be output.

=head2 flush() - output the current partial word, if any

  $tw->flush;

Call this whenever changing TextWrap's parameters in the middle
of a string of words. It explicitly allows a line-break at the
current position in the string, regardless of whether it matches
the current break pattern.

=head1 AUTHORS

=over 4

=item *

Jason Long <jason@long.name>

=item *

Marc Bradshaw <marc@marcbradshaw.net>

=item *

Bron Gondwana <brong@fastmailteam.com> (ARC)

=back

=head1 THANKS

Work on ensuring that this module passes the ARC test suite was
generously sponsored by Valimail (https://www.valimail.com/)

=head1 COPYRIGHT AND LICENSE

=over 4

=item *

Copyright (C) 2013 by Messiah College

=item *

Copyright (C) 2010 by Jason Long

=item *

Copyright (C) 2017 by Standcore LLC

=item *

Copyright (C) 2020 by FastMail Pty Ltd

=back

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
