# Copyrights 2001-2023 by [Mark Overmeer].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.03.
# This code is part of distribution Mail-Box.  Meta-POD processed with
# OODoc into POD and HTML manual-pages.  See README.md
# Copyright Mark Overmeer.  Licensed under the same terms as Perl itself.

package Mail::Box::Search::SpamAssassin;
use vars '$VERSION';
$VERSION = '3.010';

use base 'Mail::Box::Search';

use strict;
use warnings;

use Mail::SpamAssassin;
use Mail::Message::Wrapper::SpamAssassin;

#-------------------------------------------


sub init($)
{   my ($self, $args) = @_;

    $args->{in}  ||= 'MESSAGE';
    $args->{label} = 'spam' unless exists $args->{label};

    $self->SUPER::init($args);

    $self->{MBSS_rewrite_mail}
       = defined $args->{rewrite_mail} ? $args->{rewrite_mail} : 1;

    $self->{MBSS_sa}
       = defined $args->{spamassassin} ? $args->{spamassassin}
       : Mail::SpamAssassin->new($args->{sa_options} || {});

    $self;
}

#-------------------------------------------


sub assassinator() { shift->{MBSS_sa} }

#-------------------------------------------

sub searchPart($)
{   my ($self, $message) = @_;

    my @details = (message => $message);
   
    my $sa      = Mail::Message::Wrapper::SpamAssassin->new($message)
        or return;

    my $status  = $self->assassinator->check($sa);

    my $is_spam = $status->is_spam;
    $status->rewrite_mail if $self->{MBSS_rewrite_mail};

    if($is_spam)
    {   my $deliver = $self->{MBS_deliver};
        $deliver->( {@details, status => $status} ) if defined $deliver;
    }

    $is_spam;
}

#-------------------------------------------

sub inHead(@) {shift->notImplemented}

#-------------------------------------------

sub inBody(@) {shift->notImplemented}

#-------------------------------------------

1;
