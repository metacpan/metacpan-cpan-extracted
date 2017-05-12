package JavaScript::Generator;

use strict;
use warnings;

use base 'JavaScript::Boxed';

my $NF = undef;

sub next {
  my $self = shift;

  ## this just gives a function we can use to do all the hard work...
  my $NF   ||= $self->context->eval(q!function(aGenerator) { var n = aGenerator.next(); return n; }!);

  return $NF->( $self );
}

1;
__END__

=head1 NAME

JavaScript::Generator - Boxed Perl object of a JavaScript generator

=head1 DESCRIPTION

Generators were introduced in JavaScript 1.7. When you 'yield' from JS you'll be returned 
an instance of this class that you can use to retrieve the next value from the generator.

For example

  function fib() {  
    var i = 0, j = 1;  
    while (true) {  
      yield i;  
      var t = i;  
      i = j;  
      j += t;  
    }  
  }  
  
  var g = fib();  
  for (var i = 0; i < 10; i++) {  
    document.write(g.next() + "<br>\n");  
  }  

=head1 INTERFACE

=head2 INSTANCE METHODS

=over 4

=item next

Retrieve the next value.

=back

=cut
