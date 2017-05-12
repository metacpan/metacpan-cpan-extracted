package TestTransform;

use base qw(PPI::Transform);

sub new
{
	my $self = shift;
	my $class = ref($self) || $self;
	return bless [ $_[0] ], $class;
}

sub document
{
	my ($self, $doc) = @_;
	my $words = $doc->find('PPI::Token::Word');
	foreach my $word (@$words) {
                my $content = $word->content;
                $_ = $content;
		$self->[0]->();
		$word->set_content($_);
	}
}

1;
