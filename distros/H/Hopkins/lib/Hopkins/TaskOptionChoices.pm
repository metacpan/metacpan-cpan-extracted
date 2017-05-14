package Hopkins::TaskOptionChoices;

use strict;

=head1 NAME

Hopkins::TaskOptionChoices - task option choices object

=head1 DESCRIPTION

Hopkins::TaskOptionChoices represents the possible choices
for a task option.

=cut

use base 'Class::Accessor::Fast';

use LWP::UserAgent;
use JSON;

__PACKAGE__->mk_accessors(qw(type src root name value choice));

my $mimemap = { json => 'application/json', xml => 'text/xml' };

sub new
{
	my $self = shift->SUPER::new(@_);

	$self->name('name')		if not defined $self->name;
	$self->value('value')	if not defined $self->value;

	return $self;
}

sub all { return @{ shift->choice || [] } }

sub fetch
{
	my $self = shift;

	if ($self->src) {
		my $parser	= 'parse_' . $self->type;
		my $type	= $mimemap->{$self->type};
		my $ua		= new LWP::UserAgent;
		my $res		= $ua->get($self->src, 'Content-Type' => $type);

		$self->choice($self->$parser($res->content));
	}
}

sub parse_json
{
	my $self	= shift;
	my $content	= shift;

	my $json	= new JSON;
	my $ref		= $json->decode($content);
	my @choices	= ();

	$ref = $ref->{$self->root} if $self->root and ref $ref eq 'HASH';

	return [] if ref $ref ne 'ARRAY';

	foreach my $href (@$ref) {
		next if not ref $href eq 'HASH';

		push @choices, { name => $href->{$self->name}, value => $href->{$self->value} };
	}



#use Data::Dumper;
#$Data::Dumper::Indent=1;
#	print STDERR Dumper($href);

	return [ sort { $a->{name} cmp $b->{name} } @choices ];


	#print STDERR "CONTENT=$content\n";
}

=back

=head1 AUTHOR

Mike Eldridge <diz@cpan.org>

=head1 LICENSE

=cut

1;

