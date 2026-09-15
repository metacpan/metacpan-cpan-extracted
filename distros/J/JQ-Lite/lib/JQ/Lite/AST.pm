package JQ::Lite::AST;

use strict;
use warnings;

sub pipeline {
    my ($class, @filters) = @_;
    return bless { type => 'Pipeline', filters => [@filters] },
        'JQ::Lite::AST::Pipeline';
}

sub filter {
    my ($class, $source) = @_;
    return bless { type => 'Filter', source => $source },
        'JQ::Lite::AST::Filter';
}

package JQ::Lite::AST::Pipeline;

use strict;
use warnings;

sub type    { return $_[0]->{type} }
sub filters { return @{ $_[0]->{filters} } }

package JQ::Lite::AST::Filter;

use strict;
use warnings;

sub type   { return $_[0]->{type} }
sub source { return $_[0]->{source} }

1;
