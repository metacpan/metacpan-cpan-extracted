package Mail::MtPolicyd::Client::Response;

use Moose;

our $VERSION = '2.05'; # VERSION
# ABSTRACT: a postfix policyd client response class


has 'action' => ( is => 'ro', isa => 'Str', required => 1 );

has 'attributes' => (
	is => 'ro', isa => 'HashRef[Str]',
	default => sub { {} },
);

sub as_string {
	my $self = shift;

	return join("\n",
		map { $_.'='.$self->attributes->{$_} } keys %{$self->attributes},
	)."\n\n";
}

sub new_from_fh {
        my ( $class, $fh ) = ( shift, shift );
        my $attr = {};
        my $complete = 0;
        while( my $line = $fh->getline ) {
                $line =~ s/\r?\n$//;
                if( $line eq '') { $complete = 1 ; last; }
                my ( $name, $value ) = split('=', $line, 2);
                if( ! defined $value ) {
                        die('error parsing response');
                }
                $attr->{$name} = $value;
        }
        if( ! $complete ) {
                die('could not read response');
        }
	if( ! defined $attr->{'action'} ) {
		die('no action found in response');
	}
        my $obj = $class->new(
		'action' => $attr->{'action'},
                'attributes' => $attr,
                @_
        );
        return $obj;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Mail::MtPolicyd::Client::Response - a postfix policyd client response class

=head1 VERSION

version 2.05

=head1 DESCRIPTION

Class to handle a policyd response.

=head2 SYNOPSIS

  use Mail::MtPolicyd::Client::Response;
  my $response = Mail::MtPolicyd::Client::Response->new_from_fh( $conn );

  --

  my $response = Mail::MtPolicyd::Client::Response->new(
    action => 'reject',
    attributes => {
      action => 'reject',
    },
  );

  print $response->as_string;

=head2 METHODS

=over

=item new_from_fh( $filehandle )

Constructor which reads a response from the supplied filehandle.

=item as_string

Returns a stringified version of the response.

=back

=head2 ATTRIBUTES

=over

=item action (required)

The action specified in the response.

=item attributes

Holds a hash with all key/values of the response.

=back

=head1 AUTHOR

Markus Benning <ich@markusbenning.de>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014 by Markus Benning <ich@markusbenning.de>.

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut
