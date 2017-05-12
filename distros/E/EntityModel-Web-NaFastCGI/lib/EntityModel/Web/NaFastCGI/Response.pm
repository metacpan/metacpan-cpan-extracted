package EntityModel::Web::NaFastCGI::Response;
BEGIN {
  $EntityModel::Web::NaFastCGI::Response::VERSION = '0.002';
}
use EntityModel::Class {
	_isa	=> [qw(EntityModel::Web::Response)],
	fcgi	=> 'EntityModel::Web::NaFastCGI',
	context	=> 'EntityModel::Web::Context',
};

=head1 NAME

EntityModel::Web::Response - handle response to web request

=head1 VERSION

version 0.002

=head1 SYNOPSIS

=head1 DESCRIPTION

=cut

=head1 METHODS

=cut

sub new {
	my ($class, $ctx, $r) = @_;
	my $self = $class->SUPER::new;
	$self->{context} = $ctx;
	$self->{fcgi} = $r;
	return $self;
}

=head2 process

Do the processing.

FIXME 200 response only at the moment, clearly this isn't good enough.

=cut

sub process {
	my $self = shift;
	my $r = $self->fcgi;
	$r->print_stdout("Status: 200 OK\r\n" .
		"Content-Type: text/html\r\n" .
		"\r\n" .
		$self->context->process
	);
	$r->finish;
	return $self;
}

1;

__END__

=head1 AUTHOR

Tom Molesworth <cpan@entitymodel.com>

=head1 LICENSE

Copyright Tom Molesworth 2009-2011. Licensed under the same terms as Perl itself.
