package JQ::Lite::Error;

use strict;
use warnings;
use overload '""' => 'as_string', fallback => 1;

sub new {
    my ($class, %args) = @_;
    my $message = defined $args{message} ? "$args{message}" : '';
    $message =~ s/\s+\z//;
    return bless { message => $message }, $class;
}

sub message  { return $_[0]->{message} }
sub category { return 'unknown' }
sub as_string { return $_[0]->message }

package JQ::Lite::Error::Input;
use parent -norequire, 'JQ::Lite::Error';
sub category { return 'input' }

package JQ::Lite::Error::Parse;
use parent -norequire, 'JQ::Lite::Error';
sub category { return 'parse' }

package JQ::Lite::Error::Evaluation;
use parent -norequire, 'JQ::Lite::Error';
sub category { return 'evaluation' }

1;

__END__

=head1 NAME

JQ::Lite::Error - structured exceptions for the JQ::Lite Library API

=head1 DESCRIPTION

Library errors stringify to their original human-readable message while also
providing stable classes and a C<category> method for machine-readable handling.

=head1 METHODS

=head2 message

Returns the human-readable error message.

=head2 category

Returns C<input>, C<parse>, or C<evaluation> for the documented subclasses.

=cut
