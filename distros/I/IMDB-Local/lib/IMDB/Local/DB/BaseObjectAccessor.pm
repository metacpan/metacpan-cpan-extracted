package IMDB::Local::DB::BaseObjectAccessor;

#
# todo - do we need this extra layer ?
#

use Class::Accessor;
use base qw(Class::Accessor);

sub add_accessors($@)
{
    my $self=shift;
    push(@{$self->{__FIELDS__}}, @_);
    $self->SUPER::mk_accessors(@_);
}

sub get_accessors($)
{
    my $self=shift;
    return @{$self->{__FIELDS__}};
}
1;

