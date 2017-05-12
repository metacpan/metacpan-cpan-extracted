package EntityModel::Web::Header;
{
  $EntityModel::Web::Header::VERSION = '0.004';
}
use EntityModel::Class {
	name		=> 'string',
	value		=> 'string',
};

=head1 NAME

EntityModel::Web::Header - HTTP header abstraction

=head1 VERSION

version 0.004

=head1 SYNOPSIS

 use EntityModel::Web::Header;
 my $hdr = EntityModel::Web::Header->new(
 	name => 'Content-Type',
	value => 'text/html',
 );
 print $hdr->as_text;

=head1 DESCRIPTION

=cut

=head1 METHODS

=cut

1;

__END__

=head1 AUTHOR

Tom Molesworth <cpan@entitymodel.com>

=head1 LICENSE

Copyright Tom Molesworth 2009-2011. Licensed under the same terms as Perl itself.
