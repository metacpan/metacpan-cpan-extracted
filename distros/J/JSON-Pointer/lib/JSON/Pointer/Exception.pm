package JSON::Pointer::Exception;

use 5.008_001;
use strict;
use warnings;
use overload (
    q|""| => "to_string"
);

use Carp ();
use Exporter qw(import);

our $VERSION = '0.07';
our @EXPORT_OK = qw(
   ERROR_INVALID_POINTER_SYNTAX
   ERROR_POINTER_REFERENCES_NON_EXISTENT_VALUE
);

our %EXPORT_TAGS = (
    all => [ @EXPORT_OK ],
);

sub ERROR_INVALID_POINTER_SYNTAX                 { 1; }
sub ERROR_POINTER_REFERENCES_NON_EXISTENT_VALUE  { 2; }

our %MESSAGE_BUNDLES = (
    ERROR_INVALID_POINTER_SYNTAX() 
        => "Invalid pointer syntax (pointer: %s)",
    ERROR_POINTER_REFERENCES_NON_EXISTENT_VALUE()
        => "A pointer that references a non-existent value (pointer: %s)",
);

sub new {
    my ($class, %opts) = @_;
    $opts{context}->last_error($opts{code});
    bless {
        code    => $opts{code},
        context => $opts{context},
    } => $class
}

sub throw {
    Carp::croak(shift->new(@_));
}

sub code {
    shift->{code};
}

sub context {
    shift->{context};
}

sub to_string {
    my $self = shift;
    sprintf($MESSAGE_BUNDLES{$self->{code}}, $self->{context}{pointer});
}

1;
__END__

=head1 NAME

JSON::Pointer::Exception - Exception class for JSON::Pointer

=head1 VERSION

This document describes JSON::Pointer::Exception version 0.07

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=head2 new(%opts) : JSON::Pointer::Exception

=head2 throw(%opts)

=head2 code :Int

=head2 context :JSON::Pointer::Context

=head2 to_string :Str

=head1 CONSTANTS

=head2 ERROR_INVALID_POINTER_SYNTAX

=head2 ERROR_POINTER_REFERENCES_NON_EXISTENT_VALUE

=head1 DEPENDENCIES

Perl 5.8.1 or later.

=head1 BUGS

All complex software has bugs lurking in it, and this module is no
exception. If you find a bug please either email me, or add the bug
to cpan-RT.

=head1 SEE ALSO

=over

=item L<perl>

=back

=head1 AUTHOR

Toru Yamaguchi E<lt>zigorou at cpan.orgE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2013, Toru Yamaguchi. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
