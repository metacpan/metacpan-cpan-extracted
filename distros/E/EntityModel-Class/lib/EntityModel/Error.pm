package EntityModel::Error;
$EntityModel::Error::VERSION = '0.016';
use strict;
use warnings;

=head1 NAME

EntityModel::Error - generic error object

=head1 VERSION

Version 0.016

=head1 DESCRIPTION

Uses some overload tricks and C< AUTOLOAD > to allow chained method calls without needing to wrap in eval.

=head1 METHODS

=cut

use EntityModel::Log ':all';
use Data::Dumper;

use overload
	'bool' => sub {
		my $self = shift;
		logWarning('Error: [%s], chain was [%s]',
			Data::Dumper::Dumper($self->{message}),
			join(',', map {
				$_->{method} // 'unknown'
			} @{ $self->{chain} })
		);
		return 0;
	},
	'ne' => sub { 1 },
	'eq' => sub { 0 },
	'fallback' => 1;

=head2 new

Instantiate a new L<EntityModel::Error> object. Takes the following parameters:

=over 4

=item * $parent - the parent error which raised this one

=item * $msg - error message, string

=item * $opt (optional) - hashref of options

=back

=cut

sub new {
	my ($class, $parent, $msg, $opt) = @_;
	$msg = $parent if @_ < 3;
	$opt ||= { };

	logWarning($msg) if $opt->{warning};
	logError($msg) if $opt->{error};
	logInfo("Had error [%s] from %S", $msg);

	my $self = bless {
		message		=> $msg,
		parent		=> $parent,
		chain		=> [ ]
	}, $class;
	return $self;
}

our $AUTOLOAD;

sub AUTOLOAD {
	my $self = shift;
	my ($method) = $AUTOLOAD;
	$method =~ s/^.*:://g;
	return if $method eq 'DESTROY';

	logWarning('Bad method [%s] called in error, original message [%s] with object [%s]',
		$method,
		$self->{message},
		$self->{parent}
	) unless eval { $self->{parent}->can($method) };

	push @{$self->{chain}}, {method => $method };
	return $self;
}

1;

__END__

=head1 AUTHOR

Tom Molesworth <cpan@entitymodel.com>

=head1 LICENSE

Copyright Tom Molesworth 2008-2014. Licensed under the same terms as Perl itself.
