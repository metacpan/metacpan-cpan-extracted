package HTML::TreeBuilderX::ASP_NET::Types;
use strict;
use warnings;

use MooseX::Types -declare => [qw( htmlAnchorTag htmlFormTag HTMLElement )];

class_type HTMLElement, { class => 'HTML::Element' };

subtype htmlAnchorTag
	, as HTMLElement
	, where { $_->tag eq 'a' }
;

subtype htmlFormTag
	, as HTMLElement
	, where { $_->tag eq 'form' }
;

no MooseX::Types;

1;
