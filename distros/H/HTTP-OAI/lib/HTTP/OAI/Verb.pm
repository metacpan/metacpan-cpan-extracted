package HTTP::OAI::Verb;

@ISA = qw( HTTP::OAI::MemberMixin HTTP::OAI::SAX::Base );

use strict;

our $VERSION = '4.09';

# back compatibility
sub toDOM {
    shift->dom;
}

sub errors {
    shift->_multi('error',@_);
}

sub xslt {
    my ($self,$xslt) = @_;
    $self->{xslt} = $xslt if defined($xslt);
    $self->{xslt};
}

for(qw( parse_string parse_file ))
{
  no strict;
  my $fn = $_;
  *$fn = sub {
  my( $self, $io ) = @_;

  my $r = HTTP::OAI::Response->new(
  verb => $self->verb,
  handlers => $self->{handlers},
  );
  $r->$fn( $io );
  if( $r->is_error )
  {
  die "Error parsing: ".$r->code." ".$r->message;
  }
  elsif( $r->error )
  {
  $self->errors( $r->error );
  }
  else
  {
  my $content = ($r->content)[-1];
  # HACK HACK HACK
  %$self = %$content;
  }
  };
}

sub verb
{
  my $class = ref($_[0]);
  $class =~ s/^.*:://;
  return $class;
}

sub generate
{
  my( $self, $driver ) = @_;

  if( $self->xslt ) {
	  $driver->processing_instruction({
	    'Target' => 'xml-stylesheet',
	    'Data' => 'type=\'text/xsl\' href=\''. $self->xslt . '\''
	  });
	}

  $driver->start_element( 'OAI-PMH',
  'xsi:schemaLocation' => 'http://www.openarchives.org/OAI/2.0/ http://www.openarchives.org/OAI/2.0/OAI-PMH.xsd',
  );
  $driver->start_element( $self->verb );
  $self->generate_body( $driver );
  $driver->end_element( $self->verb );
  $driver->end_element( 'OAI-PMH' );
}

1;
