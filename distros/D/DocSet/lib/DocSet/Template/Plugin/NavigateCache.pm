package DocSet::Template::Plugin::NavigateCache;

use strict;
use warnings;

use vars qw(@ISA);
use Template::Plugin;
@ISA = qw(Template::Plugin);

use DocSet::NavigateCache ();

sub new {
    my $class   = shift;
    my $context = shift;
    DocSet::NavigateCache->new(@_);
}

1;

__END__
