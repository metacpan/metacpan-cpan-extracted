package Email::MIME::Kit::Assembler::Borg;
use Moose;

with 'Email::MIME::Kit::Role::Assembler';

use Email::MIME::Creator;

my $i = 1;

has number => (
  is       => 'ro',
  default  => sub { $i++ },
  init_arg => undef,
);

sub assemble {
  my ($self, $stash) = @_;
  
  my $num   = $self->number;
    my $email = Email::MIME->create(
    attributes => {
      content_type => 'text/plain',
    },
    header => [
      From    => 'drone@borg.cube',
      To      => 'earth@sector.000',
      Subject => 'You have no chance to survive, make your time.',
    ],
    body   => <<'END_OF_BODY',
We are borg.  You will be assimilated.  We will add your stash to our own.
END_OF_BODY
  );

  return $email;
}

no Moose;
1;
