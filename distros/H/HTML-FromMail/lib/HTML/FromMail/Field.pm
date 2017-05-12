# Copyrights 2003,2004,2007 by Mark Overmeer.
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 1.00.

use strict;
use warnings;

package HTML::FromMail::Field;
use vars '$VERSION';
$VERSION = '0.11';
use base 'HTML::FromMail::Page';

use Mail::Message::Field::Full;


sub init($)
{   my ($self, $args) = @_;
    $args->{topic} ||= 'field';

    $self->SUPER::init($args) or return;

    $self;
}


sub fromHead($$@)
{   my ($self, $head, $name, $args) = @_;
    $head->study($name);
}


sub htmlName($$$)
{   my ($self, $field, $args) = @_;
    return unless defined $field;

    my $reform = $args->{capitals} || $self->settings->{names}
              || 'UNCHANGED';

    $self->plain2html($reform ? $field->wellformedName : $field->Name);
}


sub htmlBody($$$)
{   my ($self, $field, $args) = @_;

    my $settings = $self->settings;

    my $wrap    = $args->{wrap} || $settings->{wrap};
    my $content = $args->{content}
               || $settings->{content}
               || (defined $wrap && 'REFOLD')
               || 'DECODED';

    if($field->isa('Mail::Message::Field::Addresses'))
    {   my $how = $args->{address} || $settings->{address} || 'MAILTO';
        return $self->addressField($field, $how, $args)
           unless $how eq 'PLAIN';
    }

    return $self->plain2html($field->unfoldedBody)
       if $content eq 'UNFOLDED';

    $field->setWrapLength($wrap || 78)
       if $content eq 'REFOLD';

    $self->plain2html($field->foldedBody);
}


sub addressField($$$)
{   my ($self, $field, $how, $args) = @_;
    return $self->plain2html($field->foldedBody) if $how eq 'PLAIN';

    return join ",<br />"
            , map {$_->address}
                $field->addresses if $how eq 'ADDRESS';
    
    return join ",<br />"
            , map {$_->phrase || $_->address}
                $field->addresses if $how eq 'PHRASE';
    
    if($how eq 'MAILTO')
    {   my @links;
        foreach my $address ($field->addresses)
        {   my $addr   = $address->address;
            my $phrase = $address->phrase || $addr;
            push @links, qq[<a href="mailto:$addr">$phrase</a>];
        }
        return join ",<br />", @links;
    }

    if($how eq 'LINK')
    {   my @links;
        foreach my $address ($field->addresses)
        {   my $addr   = $address->address;
            my $phrase = $address->phrase || '';
            push @links, qq[$phrase &lt;<a href="mailto:$addr">$addr</a>&gt;];
        }
        return join ",<br />", @links;
    }

    $self->log(ERROR => "Don't know address field formatting '$how'");
    '';
}


sub htmlAddresses($$)
{   my ($self, $field, $args) = @_;
    return undef unless $field->can('addresses');

    my @addrs;
    foreach my $address ($field->addresses)
    {  my %addr = 
        ( email   => $address->address
        , address => $self->plain2html($address->string)
        );

       if(defined(my $phrase = $address->phrase))
       {   $addr{phrase} = $self->plain2html($phrase);
       }

       push @addrs, \%addr;
    }

    \@addrs;
}


1;
