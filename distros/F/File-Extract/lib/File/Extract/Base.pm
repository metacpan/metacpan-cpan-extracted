# $Id: /mirror/perl/File-Extract/trunk/lib/File/Extract/Base.pm 4210 2007-10-27T13:43:07.499967Z daisuke  $
#
# Copyright (c) 2005 Daisuke Maki <dmaki@cpan.org>
# All rights reserved.

package File::Extract::Base;
use strict;
use Encode qw(encode decode FB_PERLQQ);
use Encode::Guess;
use File::Extract::Result;

sub new
{
    my $class = shift;
    my %args  = @_;

    my $encoding  = $args{output_encoding} || 'utf8';
    my @encodings = $args{encodings} ?
        (ref($args{encodings}) eq 'ARRAY' ? @{$args{encodings}} : $args{encodings}) : ();
    return bless {
        output_encoding => $encoding,
        encodings => \@encodings
    }, $class;
}

sub mime_type { Carp::croak(__PACKAGE__ . '::mime_type() is not defined') }
sub extract { Carp::croak(__PACKAGE__ . '::extract() is not defined') }
sub recode
{
    my $self = shift;
    my $text = shift;

    my $enc = eval { guess_encoding($text, @{$self->{encodings}}) };
    ref($enc) or die "Can't guess: $enc";
    return encode($self->{output_encoding}, $enc->decode($text), FB_PERLQQ);
}

1;

__END__

=head1 METHODS

=head2 new(%args)

=over 4

=item encodings

=back

=head2 mime_type

=head2 extract

=head2 recode($data)

Guess and re-encodings the string specified $data to the encoding specified
in the constructor.

=cut