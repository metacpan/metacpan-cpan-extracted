package EntityModel::Web::Apache2::Response;
BEGIN {
  $EntityModel::Web::Apache2::Response::VERSION = '0.001';
}
use EntityModel::Class {
	_isa	=> [qw(EntityModel::Web::Response)],
	apache	=> 'Apache2::RequestRec',
	context	=> 'EntityModel::Web::Context',
};

=head1 NAME

EntityModel::Web::Response - handle response to web request

=head1 VERSION

version 0.001

=head1 SYNOPSIS

=head1 DESCRIPTION

=cut

=head1 METHODS

=cut

sub new {
	my ($class, $ctx, $r) = @_;
	my $self = $class->SUPER::new;
	$self->{context} = $ctx;
	$self->{apache} = $r;
	return $self;
}

sub process {
	my $self = shift;
	my $r = $self->apache;
	$r->content_type('text/html');
	$r->print($self->context->process);
	return Apache2::Const::OK;
}

1;

__END__

=head1 AUTHOR

Tom Molesworth <cpan@entitymodel.com>

=head1 LICENSE

Copyright Tom Molesworth 2009-2011. Licensed under the same terms as Perl itself.