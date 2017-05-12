package Filter::Encoding;

$VERSION = '0.01';

use utf8 ();
use Filter::Util::Call qw 'filter_add filter_read';
use Encode 'find_encoding';

sub dy {
    require Carp;
    goto &Carp::croak;
}

sub import {
    shift;
    return unless @_;

    unless (@_ == 1) {
	dy "Too many arguments to Filter::Encoding->import()";
    }
    my $enc = find_encoding($_[0]);
    unless ( defined $enc ) {
        dy __PACKAGE__.": Unknown encoding '$_[0]'";
    }

    import utf8;
    filter_add(
        sub {
            my $status = filter_read();
            if ( $status > 0 ) {
                $_ = $enc->decode( $_, 1 );

		# Currently does nothing, but if perl switches to a saner
		# model this may become necessary.
		utf8'encode $_;
            }
            $status;
        }
    );
   _:
}

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~!()__END__()!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head1 NAME

Filter::Encoding - Write your script in any encoding

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

  use Filter::Encoding 'MacRoman';
  # Code that follows can be written in MacRoman encoding.

=head1 DESCRIPTION

This module allows your code to be written in any ASCII-based encoding.
Just pass the name of the encoding as an argument to C<use
Filter::Encoding>.  The source code will be decoded and treated as though it had been written in UTF-8 with C<use utf8> in effect.  That's all this
module does.

It is intended as a simpler, saner replacement for L<encoding.pm|encoding>,
one that does not change the up- and downgrading of strings or touch your
file handles.

=head1 DIAGNOSTICS

=item Too many arguments to Filter::Encoding->import()

C<use Filter::Encoding> (which implies C<< ->import >>) only allows one
argument.

=item Filter::Encoding: Unknown encoding '%s'

The encoding must be one recognized by the C<Encode> module.

=head1 PREREQUISITES

perl 5.8.0 or later

=head1 AUTHOR & COPYRIGHT

Copyright (C) 2016 Father Chrysostomos <sprout [at] cpan
[dot] org>

This program is free software; you may redistribute it, modify it, or both
under the same terms as perl.

=head1 ACKNOWLEDGEMENTS

Much of the code was based on the filter feature of
L<encoding.pm|encoding>.

=head1 SEE ALSO

L<Encode>, L<encoding>
