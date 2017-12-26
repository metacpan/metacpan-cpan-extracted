# Copyrights 2001-2017 by [Mark Overmeer].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.02.

use strict;

package Mail::Message::Head::Partial;
use vars '$VERSION';
$VERSION = '3.005';

use base 'Mail::Message::Head::Complete';

use Scalar::Util 'weaken';


sub removeFields(@)
{   my $self  = shift;
    my $known = $self->{MMH_fields};

    foreach my $match (@_)
    {
        if(ref $match)
             { $_ =~ $match && delete $known->{$_} foreach keys %$known }
        else { delete $known->{lc $match} }
    }

    $self->cleanupOrderedFields;
}


sub removeFieldsExcept(@)
{   my $self   = shift;
    my $known  = $self->{MMH_fields};
    my %remove = map { ($_ => 1) } keys %$known;

    foreach my $match (@_)
    {   if(ref $match)
        {   $_ =~ $match && delete $remove{$_} foreach keys %remove;
        }
        else { delete $remove{lc $match} }
    }

    delete @$known{ keys %remove };

    $self->cleanupOrderedFields;
}

#------------------------------------------


sub removeResentGroups()
{   my $self = shift;
    require Mail::Message::Head::ResentGroup;

    my $known = $self->{MMH_fields};
    my $found = 0;
    foreach my $name (keys %$known)
    {   next unless Mail::Message::Head::ResentGroup
                         ->isResentGroupFieldName($name);
        delete $known->{$name};
        $found++;
    }

    $self->cleanupOrderedFields;
    $self->modified(1) if $found;
    $found;
}

#------------------------------------------


sub removeListGroup()
{   my $self = shift;
    require Mail::Message::Head::ListGroup;

    my $known = $self->{MMH_fields};
    my $found = 0;
    foreach my $name (keys %$known)
    {   next unless Mail::Message::Head::ListGroup->isListGroupFieldName($name);
        delete $known->{$name};
	$found++;
    }

    $self->cleanupOrderedFields if $found;
    $self->modified(1) if $found;
    $found;
}

#------------------------------------------


sub removeSpamGroups()
{   my $self = shift;
    require Mail::Message::Head::SpamGroup;

    my $known = $self->{MMH_fields};
    my $found = 0;
    foreach my $name (keys %$known)
    {   next unless Mail::Message::Head::SpamGroup->isSpamGroupFieldName($name);
        delete $known->{$name};
	$found++;
    }

    $self->cleanupOrderedFields if $found;
    $self->modified(1) if $found;
    $found;
}

#------------------------------------------


sub cleanupOrderedFields()
{   my $self = shift;
    my @take = grep { defined $_ } @{$self->{MMH_order}};
    weaken($_) foreach @take;
    $self->{MMH_order} = \@take;
    $self;
}

#------------------------------------------


#------------------------------------------

1;
