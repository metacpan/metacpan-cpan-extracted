package JSPL::Boxed;

use strict;
use warnings;
use Scalar::Util ();

sub __new {
    my ($pkg, $content, $jsvalue) = @_;
    my $boxed = bless \[$content, JSPL::Context::current(), $jsvalue,
	                #0xAA55
		       ], $pkg;
    Scalar::Util::weaken(${$boxed}->[1]);
    return $boxed;
}

sub __content {
    #die "Bad mark, Boxed::content\n" unless ${$_[0]}->[3] == 0xAA55;
    ${$_[0]}->[0];
}

sub __context {
    #die "Bad mark, Boxed::context\n" unless ${$_[0]}->[3] == 0xAA55;
    ${$_[0]}->[1];
}

sub __jsvalue {
    #die "Bad mark, Boxed::jsvalue\n" unless ${$_[0]}->[3] == 0xAA55;
    ${$_[0]}->[2];
}

sub DESTROY {
    my $self = shift;

    if(ref(${$self}->[0]) && $self->__context) {
	$self->__content->free_root($self->__context);
    } else { # Was finalized in JS side.
	undef @$$self;
    }
}
JSPL::_boot_('JSPL::RawObj');

1;
__END__
    
=head1 NAME

JSPL::Boxed - Encapsulates all javascript object reflected to perl space in order
to syncronize SM garbage colector and perl reference counting system.

=head1 DESCRIPTION

** This is for internal use only **

=begin PRIVATE

=head1 PRIVATE INTERFACE

=head2 CLASS METHODS

=over 4

=item __new ( $content, $context, $jsvalue )

Creates a new "boxed" value.

=back

=head2 INSTANCE METHODS

=over

=item __content

Returns a JSPL::RawOBJ (raw JSObject * wrapped)

=item __context

Returns the JSPL::Context that create this wrapper

=item __jsvalue

Returns a JSPL::JSVAL (raw jsval wrapped)

=back

=end PRIVATE

=cut
