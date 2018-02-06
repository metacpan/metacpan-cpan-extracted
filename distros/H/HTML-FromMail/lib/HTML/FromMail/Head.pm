# Copyrights 2003-2018 by [Mark Overmeer <markov@cpan.org>].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.02.
# This code is part of distribution HTML-FromMail.  Meta-POD processed with
# OODoc into POD and HTML manual-pages.  See README.md
# Copyright Mark Overmeer.  Licensed under the same terms as Perl itself.

package HTML::FromMail::Head;
use vars '$VERSION';
$VERSION = '0.12';

use base 'HTML::FromMail::Page';

use strict;
use warnings;

use HTML::FromMail::Field;


sub init($)
{   my ($self, $args) = @_;
    $args->{topic} ||= 'head';

    $self->SUPER::init($args) or return;

    $self;
}


sub fields($$)
{   my ($thing, $realhead, $args) = @_;
    my $head = $realhead->clone;   # we are probably going to remove lines

    my $lg = $args->{remove_list_group};
    $head->removeListGroup    if $lg || !defined $lg;

    my $sg = $args->{remove_spam_groups};
    $head->removeSpamGroups   if $sg || !defined $sg;

    my $rg = $args->{remove_resent_groups};
    $head->removeResentGroups if $rg || !defined $rg;

    my @fields;
    if(my $select = $args->{select})
    {   my @select = split /\|/, $select;
        @fields    = map {$head->grepNames($_)} @select;
    }
    elsif(my $ignore = $args->{ignore})
    {   my @ignore = split /\|/, $ignore;
        local $"   = ")|(?:";
        my $skip   = qr/^(?:@ignore)/i;
        @fields    = grep { $_->name !~ $skip } $head->orderedFields;
    }
    else
    {   @fields    = $head->orderedFields;
    }

    map {$_->study} @fields;
}

1;
