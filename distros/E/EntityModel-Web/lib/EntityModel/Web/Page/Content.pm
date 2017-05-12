package EntityModel::Web::Page::Content;
{
  $EntityModel::Web::Page::Content::VERSION = '0.004';
}
use EntityModel::Class {
	section		=> 'string',
	template	=> 'string',
};

=head1 NAME



=head1 SYNOPSIS

=head1 VERSION

version 0.004

=head1 DESCRIPTION

=cut

use Data::Dumper;

=head1 METHODS

=cut

sub new {
	my $class = shift;
	my $self = $class->SUPER::new;
	my %args = @_;
	if(defined(my $section = delete $args{section})) {
		$self->{section} = $section;
	}
	if(defined(my $tmpl = delete $args{template})) {
		$self->{template} = $tmpl;
	}
	return $self;
}

1;

__END__

=head1 AUTHOR

Tom Molesworth <cpan@entitymodel.com>

=head1 LICENSE

Copyright Tom Molesworth 2009-2011. Licensed under the same terms as Perl itself.
