package Devel::Chitin::Exception;

use strict;
use warnings;

our $VERSION = '0.22';
use base 'Devel::Chitin::Location';

sub _required_properties {
    my $class = shift;
    my @inh_props = $class->SUPER::_required_properties;
    push @inh_props, 'exception';
    return @inh_props;
}

BEGIN {
    __PACKAGE__->_make_accessors();
}

1;

__END__

=pod

=head1 NAME

Devel::Chitin::Exception - A class to represent an exception

=head1 SYNOPSIS

  my $exp = Devel::Chitin::Exception->new(
                package     => 'main',
                subroutine  => 'main::foo,
                filename    => '/usr/local/bin/program.pl',
                line        => 10,
                exception   => 'You cannot do that!');
  printf("On line %d of %s, exception in subroutine %s: %s\n",
        $exp->line,
        $exp->filename,
        $exp->subroutine,
        $exp->exception);

=head1 DESCRIPTION

This class is used to represent a exception with location in the debugged
program.  It is a subclass of Devel::Chitin::Location.

=head1 METHODS

  Devel::Chitin::Exception->new(%params)

Construct a new instance.  The following parameters are accepted.  The values
should be self-explanatory.  All parameters except callsite are required.

=over 4

=item package

=item filename

=item line

=item subroutine

=item callsite

=item exception

=back

Each construction parameter also has a read-only method to retrieve the value.

=head1 SEE ALSO

L<Devel::Chitin::Location>, L<Devel::Chitin>

=head1 AUTHOR

Anthony Brummett <brummett@cpan.org>

=head1 COPYRIGHT

Copyright 2017, Anthony Brummett.  This module is free software. It may
be used, redistributed and/or modified under the same terms as Perl itself.

