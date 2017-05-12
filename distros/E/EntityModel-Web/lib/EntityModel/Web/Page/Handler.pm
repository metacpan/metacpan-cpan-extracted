package EntityModel::Web::Page::Handler;
{
  $EntityModel::Web::Page::Handler::VERSION = '0.004';
}
use EntityModel::Class {
	type		=> 'string',
	method		=> 'string',
};

=head1 NAME



=head1 SYNOPSIS

=head1 VERSION

version 0.004

=head1 DESCRIPTION

=cut

use Data::Dumper;

use overload
	'&{}' => sub {
		my ($self, @args) = @_;
		sub {
			my $resp = shift;
			logWarning("Req: %s, we are holding: %s", $resp->request, join ',', map $_ // 'undef', @_);
			my $req = $resp->request;
			logWarning("Header - %s: %s", $_->name, $_->value) for $req->header->list;
			logWarning("POST: " . $_ . " => " . $req->post->{$_}) for sort $req->post->keys;
			logWarning("GET " . $_ . " => " . $req->get->{$_}) for sort $req->get->keys;
		}
	},
	fallback => 1;

=head1 METHODS

=cut

sub new {
	my $class = shift;
	my $self = $class->SUPER::new;
	my %args = %{$_[0]};
	$self->$_($args{$_}) for sort keys %args;
	logWarning("Have type %s with method %s", $self->type, $self->method);
	return $self;
}

1;

__END__

=head1 AUTHOR

Tom Molesworth <cpan@entitymodel.com>

=head1 LICENSE

Copyright Tom Molesworth 2009-2011. Licensed under the same terms as Perl itself.
