package HTML::FillInForm::ForceUTF8;

use strict;
use warnings;
use base qw(HTML::FillInForm);
use Encode;

our $VERSION = '0.03';

sub fill {
    my ( $self, %option ) = @_;
    if ( exists $option{file} ) {
        if ( ref $option{file} ) {
            binmode $option{file}, ":utf8";
        }
        else {
            open my $fh, ":utf8", $option{file};
            $option{file} = $fh;
        }
    }
    elsif ( exists $option{scalarref} && !Encode::is_utf8($option{scalarref}) ) {
        my $val = ${$option{scalarref}};
        Encode::_utf8_on( $val );
        $option{scalarref} = \$val;
    }
    elsif ( exists $option{arrayref} ) {
        for ( @{ $option{arrayref} } ) {
            Encode::_utf8_on($_) unless Encode::is_utf8($_);
        }
    }
    $self->SUPER::fill(%option);
}

sub _get_param {
    my $self = shift;
    my $ret  = $self->SUPER::_get_param(@_);
    for ( ref($ret) ? @$ret : $ret ) {
        Encode::_utf8_on($_) unless Encode::is_utf8($_);
    }
    return $ret;
}

1;
__END__

=encoding utf-8

=head1 NAME

HTML::FillInForm::ForceUTF8 -  FillInForm with utf8 encoding

=head1 SYNOPSIS

  use HTML::FillInForm::ForceUTF8;

  my $fif = HTML::FillInForm::ForceUTF8->new;

  my $fdat;
  $fdat->{foo} = "\x{306a}\x{304c}\x{306e}"; #Unicode flagged
  $fdat->{bar} = "\xe3\x81\xaa\xe3\x81\x8c\xe3\x81\xae"; # UTF8 bytes

  my $output = $fif->fill(
    scalarref => \$html,
    fdat => $fdat
  );

=head1 DESCRIPTION

HTML::FillInForm::ForceUTF8 is a subclass of HTML::FillInForm that forces utf8 flag on html and parameters. This allows you to prevent filling garbled result.

=head1 SEE ALSO

L<HTML::FillInForm>

=head1 LICENSE

Copyright (C) Masahiro Nagano.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Masahiro Nagano E<lt>kazeburo@gmail.comE<gt>

=cut

