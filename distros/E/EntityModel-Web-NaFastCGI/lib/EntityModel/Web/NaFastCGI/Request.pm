package EntityModel::Web::NaFastCGI::Request;
BEGIN {
  $EntityModel::Web::NaFastCGI::Request::VERSION = '0.002';
}
use EntityModel::Class {
	_isa		=> [qw(EntityModel::Web::Request)],
};

=head1 NAME

EntityModel::Web::NaFastCGI::Request - abstraction for incoming HTTP request

=head1 VERSION

version 0.002

=head1 SYNOPSIS

 use EntityModel::Web::Request;
 my $req = EntityModel::Web::Request->new(
 );

=head1 DESCRIPTION

=cut

sub new {
	my $class = shift;
	my $r = shift;
	my $param = $r->params;
	my $self = $class->SUPER::new(
		method	=> lc $param->{REQUEST_METHOD},
		path	=> $param->{PATH_INFO},
		version	=> '1.1',
		header	=> [
			{ name => 'Host',	value => $param->{HTTP_HOST} },
			{ name => 'User-Agent', value => $param->{HTTP_USER_AGENT} },
		]
	);
	return $self;
}

1;

__END__

=head1 AUTHOR

Tom Molesworth <cpan@entitymodel.com>

=head1 LICENSE

Copyright Tom Molesworth 2009-2011. Licensed under the same terms as Perl itself.
