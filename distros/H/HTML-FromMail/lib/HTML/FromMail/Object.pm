# Copyrights 2003,2004,2007 by Mark Overmeer.
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 1.00.

use strict;
use warnings;

package HTML::FromMail::Object;
use vars '$VERSION';
$VERSION = '0.11';
use base 'Mail::Reporter';


sub init($)
{   my ($self, $args) = @_;

    $self->SUPER::init($args) or return;

    unless(defined($self->{HFO_topic} = $args->{topic}))
    {   $self->log(INTERNAL => 'No topic defined for '.ref($self));
        exit 1;
    }

    $self->{HFO_settings} = $args->{settings} || {};
    $self;
}


sub topic() { shift->{HFO_topic} }


sub settings(;$)
{  my $self  = shift;
   my $topic = @_ ? shift : $self->topic;
   return {} unless defined $topic;
   $self->{HFO_settings}{$topic} || {};
}


sub plain2html($)
{   my $self   = shift;
    my $string = join '', @_;
    for($string)
    {   s/\&/\&amp;/g;
        s/\</\&lt;/g;
        s/\>/\&gt;/g;
        s/"/\&quot;/g;
    }
    $string;
}

1;
