
package Embperl::Syntax::Test;

use strict;
use Embperl::Syntax qw{:types} ;
use Embperl::Syntax::HTML ;
use base qw(Embperl::Syntax::HTML);


sub new 
    {
    my $class = shift;
    my $self = Embperl::Syntax::HTML::new($class);

    if (!$self->{-testInit}) 
        {
        $self->{-testInit} = 1;
        init($self);
        }
    return $self;
    }

sub init {
  my $self = shift;

  $self->AddTagInside('testname', ['type'], undef, undef, {
                perlcode => q[{
                                _ep_rp(%$x%, "test syntax %&'type%");
                }]
  });

}


1;
