# Copyrights 2001-2023 by [Mark Overmeer <markov@cpan.org>].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.03.
# This code is part of distribution Mail-Message.  Meta-POD processed with
# OODoc into POD and HTML manual-pages.  See README.md
# Copyright Mark Overmeer.  Licensed under the same terms as Perl itself.

package Mail::Message::Head::FieldGroup;
use vars '$VERSION';
$VERSION = '3.015';

use base 'Mail::Reporter';

use strict;
use warnings;


sub new(@)
{   my $class = shift;

    my @fields;
    push @fields, shift while ref $_[0];

    $class->SUPER::new(@_, fields => \@fields);
}

sub init($$)
{   my ($self, $args) = @_;
    $self->SUPER::init($args);

    my $head = $self->{MMHF_head}
      = $args->{head} || Mail::Message::Head::Partial->new;

    $self->add($_)                            # add specified object fields
        foreach @{$args->{fields}};

    $self->add($_, delete $args->{$_})        # add key-value paired fields
        foreach grep m/^[A-Z]/, keys %$args;

    $self->{MMHF_version}  = $args->{version}  if defined $args->{version};
    $self->{MMHF_software} = $args->{software} if defined $args->{software};
    $self->{MMHF_type}     = $args->{type}     if defined $args->{type};

    $self->{MMHF_fns}      = [];
    $self;
}

#------------------------------------------


sub implementedTypes() { shift->notImplemented }

#------------------------------------------


sub from($) { shift->notImplemented }

#------------------------------------------


sub clone()
{   my $self = shift;
    my $clone = bless %$self, ref $self;
    $clone->{MMHF_fns} = [ $self->fieldNames ];
    $clone;
}

#------------------------------------------


sub head() { shift->{MMHF_head} }

#------------------------------------------


sub attach($)
{   my ($self, $head) = @_;
    $head->add($_->clone) for $self->fields;
    $self;
}

#------------------------------------------


sub delete()
{   my $self   = shift;
    my $head   = $self->head;
    $head->removeField($_) foreach $self->fields;
    $self;
}

#------------------------------------------


sub add(@)
{   my $self = shift;
    my $field = $self->head->add(@_) or return ();
    push @{$self->{MMHF_fns}}, $field->name;
    $self;
}

#------------------------------------------


sub fields()
{   my $self = shift;
    my $head = $self->head;
    map { $head->get($_) } $self->fieldNames;
}

#------------------------------------------


sub fieldNames() { @{shift->{MMHF_fns}} }

#------------------------------------------


sub addFields(@)
{   my $self = shift;
    my $head = $self->head;

    push @{$self->{MMHF_fns}}, @_;
    @_;
}

#------------------------------------------


sub version() { shift->{MMHF_version} }

#------------------------------------------


sub software() { shift->{MMHF_software} }

#------------------------------------------


sub type() { shift->{MMHF_type} }

#------------------------------------------


sub detected($$$)
{   my $self = shift;
    @$self{ qw/MMHF_type MMHF_software MMHF_version/ } = @_;
}

#------------------------------------------


sub collectFields(;$) { shift->notImplemented }

#------------------------------------------


sub print(;$)
{   my $self = shift;
    my $out  = shift || select;
    $_->print($out) foreach $self->fields;
}

#------------------------------------------


sub details()
{   my $self     = shift;
    my $type     = $self->type || 'Unknown';

    my $software = $self->software;
    undef $software if defined($software) && $type eq $software;
    my $version  = $self->version;
    my $release
      = defined $software
      ? (defined $version ? " ($software $version)" : " ($software)")
      : (defined $version ? " ($version)"           : '');

    my $fields   = scalar $self->fields;
    "$type $release, $fields fields";
}

#------------------------------------------

1;
