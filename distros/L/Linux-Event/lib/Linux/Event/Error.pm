package Linux::Event::Error;
use v5.36;
use strict;
use warnings;

use Carp qw(croak);
our $VERSION = '0.010';

sub new ($class, %arg) {
    croak 'code is required' unless exists $arg{code};

    my $self = bless {
        code    => $arg{code},
        name    => defined $arg{name}    ? $arg{name}    : 'EUNKNOWN',
        message => defined $arg{message} ? $arg{message} : '',
    }, $class;

    return $self;
}

sub code    ($self) { return $self->{code} }
sub name    ($self) { return $self->{name} }
sub message ($self) { return $self->{message} }

1;

__END__

=head1 NAME

Linux::Event::Error - Lightweight proactor error object

=head1 SYNOPSIS

  my $err = $op->error;
  warn $err->code;
  warn $err->name;
  warn $err->message;

=head1 DESCRIPTION

C<Linux::Event::Error> is a compact object used by
L<Linux::Event::Proactor> to report failed operations. It stores an errno-style
numeric code, a short symbolic name, and a descriptive message.

=head1 METHODS

=head2 new(%args)

Create a new error object. C<code> is required. C<name> defaults to
C<EUNKNOWN>. C<message> defaults to the empty string.

=head2 code

Return the numeric code.

=head2 name

Return the symbolic name.

=head2 message

Return the descriptive message.

=head1 SEE ALSO

L<Linux::Event::Operation>,
L<Linux::Event::Proactor>

=cut
