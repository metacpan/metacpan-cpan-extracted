package Jmespath;
use strict;
use warnings;
use Jmespath::Parser;
use Jmespath::Visitor;
use JSON qw(encode_json decode_json);
use Try::Tiny;
use v5.14;
our $VERSION = '0.02';
use utf8;
use Encode;

sub compile {
  my ( $class, $expression ) = @_;
  return Jmespath::Parser->new->parse( Encode::encode_utf8($expression) );
}

sub search {
  my ( $class, $expression, $data, $options ) = @_;
  my ($result);
  try {
    $result = Jmespath::Parser->new->parse( $expression )
      ->search( $data, $options );
  } catch {
    $_->throw;
  };
  return $result if not defined $result;

  # JSON block result
  if ( ( ref ($result) eq 'HASH'  ) or
       ( ref ($result) eq 'ARRAY' ) ) {
    try {
      $result = JSON->new
        ->utf8(1)
        ->allow_nonref
        ->space_after
        ->allow_blessed(1)
        ->convert_blessed(1)
        ->encode( $result );
      return $result;
    } catch {
      Jmespath::ValueException->new( message => "cannot encode" )->throw;
    };
  }

  if ( $result =~ /[0-9]+/ ) {
    return $result;
  }

  # Unquoted string result
  if ( $ENV{JP_UNQUOTED} == 0 or
       not defined $ENV{JP_UNQUOTED} ) {
    $result = q{"} . $result . q{"};
  }
  return $result;
}

1;

__END__

=head1 NAME

Jmespath - Enabling easy querying for JSON structures.

