# Copyrights 2003-2018 by [Mark Overmeer <markov@cpan.org>].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.02.
# This code is part of distribution HTML-FromMail.  Meta-POD processed with
# OODoc into POD and HTML manual-pages.  See README.md
# Copyright Mark Overmeer.  Licensed under the same terms as Perl itself.

package HTML::FromMail::Object;
use vars '$VERSION';
$VERSION = '0.12';

use base 'Mail::Reporter';

use strict;
use warnings;


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
