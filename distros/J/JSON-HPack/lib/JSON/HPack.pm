package JSON::HPack;

use common::sense;
use constant FIRST => 0;
use JSON::Any;

our $VERSION = q(0.0.3);


=head1 NAME 

JSON-HPack - JSON Homogeneous Collections Compressor 

=head1 SYNOPSIS

  use JSON::HPack; 

  JSON::HPack->pack( [ 
    {
      name => 'Larry Wall',
      nick  => 'timtowtdi' 
    }
  ] );

  # - OR -

  JSON::HPack->dump( [
    {
      name => 'Larry Wall',
      nick  => 'timtowtdi' 
    }
  ] )

  # To Unpack
  JSON::HPack->unpack(
    [ 2, 'name', 'nick', 'Larry Wall', 'timtowdi' ]
  )

  # - OR use JSON string directly
  JSON::HPack->load( $json_string )

=head1 DESCRIPTION

JSON HPack perl implementation is based on other implementations available on Github L<https://github.com/WebReflection/JSONH>

Usually a database result set, stored as list of objects where all of them contains the same amount 
of keys with identical name. This is a basic homogeneous collection example: 

  [{"a":"A","b":"B"},{"a":"C","b":"D"},{"a":"E","b":"F"}] 

We all have exchange over the network one or more homogenous collections at least once. JSON::HPack is able to 
pack the example into: 

  [2,"a","b","A","B","C","D","E","F"] 

and unpack it into original collection at light speed.

=head2 C<pack> 


  $packed_structure = JSON::HPack->pack( $unpacked_structure );


=head2 C<unpack> 


  $unpacked_structure = JSON::HPack->unpack( $packed_structure );


=head2 C<dump> 


  $packed_json = JSON::HPack->dump( $unpacked_structure );


=head2 C<load> 


  $unpacked_structure = JSON::HPack->load( $packed_json );


=head1 BUGS

Please report them.

=cut




sub pack {
  my ( $class, $aoh ) = @_;

  my %first     = %{ $aoh->[FIRST] };
  my $key_size  = scalar( keys( %first ) );
  my @keys      = keys( %first );

  [
    $key_size,
    @keys, 
    map {
      my $this = $_;
      map {
        $this->{$_}
      } @keys
    } @{ $aoh }[ 0 .. ( scalar( @$aoh ) - 1 ) ] 
  ];

}

sub unpack {
  my ( $class, $pa ) = @_;

  my ( $results, @keys )  = ( 
    [ ],
    @{ $pa }[ 1 .. $pa->[ FIRST ] ]
  );

  my ( $start, $length ) = ( scalar( @keys ) ) x 2;

  LOOP: while( ( $start + 1 + $length ) <= @$pa ) {
    my @values = @{ $pa }[ $start + 1 .. ( $start + $length ) ];

    my %hash = (
      map {
       $keys[ $_ ] => $values[ $_ ] 
      } ( 0 .. ( $length - 1 ) ) 
    );

    push( @$results, { %hash } );

    $start += $length;
  }

  $results;

}


sub load {
  my ( $class, $string ) = @_;

  $class->unpack( 
    JSON::Any
      ->new
      ->jsonToObj( $string )
  );
}

sub dump {
  my ( $class, $struct ) = @_;

  JSON::Any->new
    ->objToJson(
      $class->pack( $struct )
    );

}




1;
__END__
