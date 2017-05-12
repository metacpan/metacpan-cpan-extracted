package EntityModel::Definition::JSON;
{
  $EntityModel::Definition::JSON::VERSION = '0.102';
}
use EntityModel::Class {
	_isa		=> [qw{EntityModel::Definition}],
};

=head1 NAME

EntityModel::Definition::JSON - definition support for L<EntityModel>

=head1 VERSION

version 0.102

=head1 SYNOPSIS

See L<EntityModel>.

=head1 DESCRIPTION

See L<EntityModel>.

=head1 METHODS

=cut

use JSON::XS;

=head2 load_file

=cut

sub load_file {
	my $self = shift;
	my $path = shift;

	open my $fh, '<:encoding(utf-8)', $path or die "Failed to open $path - $!";
	my $string = do { local $/; <$fh> };
	close $fh or die "Failed to close $path - $!";
	return $self->parse($string);
}

=head2 load_string

=cut

sub load_string {
	my $self = shift;
	my $string = shift;
	logDebug("Load string [%s]", $string);
	return $self->parse($string);
}

=head2 save_file

Write output to a file.

=cut

sub save_file {
	my $self = shift;
	my %args = @_;
	my $path = delete $args{path} or die "No path provided";

	my $data = JSON::XS->new->encode($args{structure});
	open my $fh, '>:encoding(utf-8)', $path or die "Failed to open $path - $!";
	$fh->print($data);
	close $fh or die "Failed to close $path - $!";
	return $self;
}

=head2 save_string

Return output as a scalar.

=cut

sub save_string {
	my $self = shift;
	my %args = @_;

	return JSON::XS->new->pretty->utf8->encode($self->structure_from_model($args{model}));
}

=head2 parse

Create and parse the L<JSON::XS> object.

=cut

sub parse {
	my $self = shift;
	my $string = shift;
	my $json = JSON::XS->new;
	my $def = $json->decode($string);
	logDebug($def);
	return $def;
}

1;

__END__

=head1 AUTHOR

Tom Molesworth <cpan@entitymodel.com>

=head1 LICENSE

Copyright Tom Molesworth 2008-2011. Licensed under the same terms as Perl itself.
