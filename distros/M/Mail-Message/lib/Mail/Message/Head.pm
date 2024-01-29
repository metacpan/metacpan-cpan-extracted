# Copyrights 2001-2023 by [Mark Overmeer <markov@cpan.org>].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.03.
# This code is part of distribution Mail-Message.  Meta-POD processed with
# OODoc into POD and HTML manual-pages.  See README.md
# Copyright Mark Overmeer.  Licensed under the same terms as Perl itself.

package Mail::Message::Head;
use vars '$VERSION';
$VERSION = '3.015';

use base 'Mail::Reporter';

use strict;
use warnings;

use Mail::Message::Head::Complete;
use Mail::Message::Field::Fast;

use Carp;
use Scalar::Util 'weaken';


use overload qq("") => 'string_unless_carp'
           , bool   => 'isEmpty';

# To satisfy overload in static resolving.
sub toString() { shift->load->toString }
sub string()   { shift->load->string }

sub string_unless_carp()
{   my $self = shift;
    return $self->toString unless (caller)[0] eq 'Carp';

    (my $class = ref $self) =~ s/^Mail::Message/MM/;
    "$class object";
}

#------------------------------------------


sub new(@)
{   my $class = shift;

    return Mail::Message::Head::Complete->new(@_)
       if $class eq __PACKAGE__;

    $class->SUPER::new(@_);
}
 
sub init($)
{   my ($self, $args) = @_;

    $self->SUPER::init($args);

    $self->{MMH_field_type} = $args->{field_type}
        if $args->{field_type};

    $self->message($args->{message})
        if defined $args->{message};

    $self->{MMH_fields}     = {};
    $self->{MMH_order}      = [];
    $self->{MMH_modified}   = $args->{modified} || 0;
    $self;
}


sub build(@)
{   shift;
    Mail::Message::Head::Complete->build(@_);
}

#------------------------------------------


sub isDelayed { 1 }


sub modified(;$)
{   my $self = shift;
    return $self->isModified unless @_;
    $self->{MMH_modified} = shift;
}


sub isModified() { shift->{MMH_modified} }


sub isEmpty { scalar keys %{shift->{MMH_fields}} }


sub message(;$)
{   my $self = shift;
    if(@_)
    {    $self->{MMH_message} = shift;
         weaken($self->{MMH_message});
    }

    $self->{MMH_message};
}


sub orderedFields() { grep defined $_, @{shift->{MMH_order}} }


sub knownNames() { keys %{shift->{MMH_fields}} }

#------------------------------------------


sub get($;$)
{   my $known = shift->{MMH_fields};
    my $value = $known->{lc(shift)};
    my $index = shift;

    if(defined $index)
    {   return ! defined $value      ? undef
             : ref $value eq 'ARRAY' ? $value->[$index]
             : $index == 0           ? $value
             :                         undef;
    }
    elsif(wantarray)
    {   return ! defined $value      ? ()
             : ref $value eq 'ARRAY' ? @$value
             :                         ($value);
    }
    else
    {   return ! defined $value      ? undef
             : ref $value eq 'ARRAY' ? $value->[-1]
             :                         $value;
    }
}

sub get_all(@) { my @all = shift->get(@_) }   # compatibility, force list
sub setField($$) {shift->add(@_)} # compatibility


sub study($;$)
{   my $self = shift;
    return map {$_->study} $self->get(@_)
       if wantarray;

    my $got  = $self->get(@_);
    defined $got ? $got->study : undef;
}

#------------------------------------------



sub isMultipart()
{   my $type = shift->get('Content-Type', 0);
    $type && scalar $type->body =~ m[^multipart/]i;
}

#------------------------------

sub read($)
{   my ($self, $parser) = @_;

    my @fields = $parser->readHeader;
    @$self{ qw/MMH_begin MMH_end/ } = (shift @fields, shift @fields);

    my $type   = $self->{MMH_field_type} || 'Mail::Message::Field::Fast';

    $self->addNoRealize($type->new( @$_ ))
        for @fields;

    $self;
}


#  Warning: fields are added in addResentGroup() as well!
sub addOrderedFields(@)
{   my $order = shift->{MMH_order};
    foreach (@_)
    {   push @$order, $_;
        weaken( $order->[-1] );
    }
    @_;
}


sub load($) {shift}


sub fileLocation()
{   my $self = shift;
    @$self{ qw/MMH_begin MMH_end/ };
}


sub moveLocation($)
{   my ($self, $dist) = @_;
    $self->{MMH_begin} -= $dist;
    $self->{MMH_end}   -= $dist;
    $self;
}


sub setNoRealize($)
{   my ($self, $field) = @_;

    my $known = $self->{MMH_fields};
    my $name  = $field->name;

    $self->addOrderedFields($field);
    $known->{$name} = $field;
    $field;
}


sub addNoRealize($)
{   my ($self, $field) = @_;

    my $known = $self->{MMH_fields};
    my $name  = $field->name;

    $self->addOrderedFields($field);

    if(defined $known->{$name})
    {   if(ref $known->{$name} eq 'ARRAY') { push @{$known->{$name}}, $field }
        else { $known->{$name} = [ $known->{$name}, $field ] }
    }
    else
    {   $known->{$name} = $field;
    }

    $field;
}

#------------------------------------------


1;
