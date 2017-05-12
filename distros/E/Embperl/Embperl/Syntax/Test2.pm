package Embperl::Syntax::Test2;

use Embperl::Syntax qw{:types} ;
use Embperl::Syntax::HTML ;
use File::Spec::Unix;

# We inherit the generic HTML support from Embperl::Syntax::HTML
use vars qw(@ISA);
@ISA = qw(Embperl::Syntax::HTML) ;

sub new {
  my $class = shift;
  my $self = Embperl::Syntax::HTML::new($class);

  # initialise ourselves when an object is created if it hasn't
  # been done already
  if (!$self->{-randomInit}) {
    $self->{-randomInit} = 1;
    init($self);
  }
  return $self;
}

# initialise things and define our new syntax handling
sub init {
  my $self = shift;

  # redefine the tags we want to manipulate attributes for
  $self->AddTag('qq', ['href'], undef, undef, {
      perlcode => q[ {
        # _ep_sa is an apparently undocumented function which
        # allows you to rewrite an attribute of the current node
        # specified by %$n%
        _ep_sa(%$n%, 'href', Embperl::Syntax::Test2::rewrite_url(%&'href%));
      }],
  });

  $self->AddTag('a', ['href'], undef, undef, {
      perlcode => q[ {
        # _ep_sa is an apparently undocumented function which
        # allows you to rewrite an attribute of the current node
        # specified by %$n%
        _ep_sa(%$n%, 'href', Embperl::Syntax::Test2::rewrite_url(%&'href%));
      }],

  });

}

sub rewrite_url 
    { 
    warn "rewrite_url got $_[0]\n" ;
    return "**$_[0]**12**"; 
    }

1 ;
