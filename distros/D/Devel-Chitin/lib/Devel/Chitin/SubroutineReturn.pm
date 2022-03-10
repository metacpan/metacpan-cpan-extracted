package Devel::Chitin::SubroutineReturn;

use strict;
use warnings;

our $VERSION = '0.19';
use base 'Devel::Chitin::Location';

sub _required_properties {
    my $class = shift;
    my @inh_props = $class->SUPER::_required_properties;
    push @inh_props, 'wantarray';
    return @inh_props;
}

# This is a custom accessor because it's read/write
sub rv {
    my $self = shift;
    if (@_) {
        $self->{rv} = shift;
    };
    return $self->{rv};
}

BEGIN {
    __PACKAGE__->_make_accessors();
}

1;

__END__

=pod

=head1 NAME

Devel::Chitin::Exception - A class to represent a subroutine call return

=head1 SYNOPSIS

  my $exp = Devel::Chitin::SubroutineReturn->new(
                package     => 'main',
                subroutine  => 'main::foo,
                filename    => '/usr/local/bin/program.pl',
                line        => 10,
                wantarray   => 0,
                rv          => 'It worked!');
  printf("On line %d of %s, subroutine %s returned: %s\n",
        $exp->line,
        $exp->filename,
        $exp->subroutine,
        $exp->rv);

=head1 DESCRIPTION

This class is used to represent the occurance of a subroutine returning to its
caller.  It is a subclass of Devel::Chitin::Location.  They are primarily used
in the optional callback triggered from C<stepout()>.

=head1 METHODS

  Devel::Chitin::SubroutineReturn->new(%params)

Construct a new instance.  The following parameters are accepted.  The values
should be self-explanatory.  All parameters except callsite are required.

=over 4

=item package

=item filename

=item line

=item subroutine

=item callsite

=item rv

=back

Each construction parameter also has a read-only method to retrieve the value.

The C<rv()> method is special - it can be changed by passing a new value as
the method argument.  When this behavior is used as part of a callback from
a C<stepout()>, the actual return value from the function can be changed in
the running program.

=head1 SEE ALSO

L<Devel::Chitin::Location>, L<Devel::Chitin>

=head1 AUTHOR

Anthony Brummett <brummett@cpan.org>

=head1 COPYRIGHT

Copyright 2021, Anthony Brummett.  This module is free software. It may
be used, redistributed and/or modified under the same terms as Perl itself.

