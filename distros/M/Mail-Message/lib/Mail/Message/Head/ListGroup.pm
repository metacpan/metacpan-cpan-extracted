# Copyrights 2001-2020 by [Mark Overmeer <markov@cpan.org>].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.02.
# This code is part of distribution Mail-Message.  Meta-POD processed with
# OODoc into POD and HTML manual-pages.  See README.md
# Copyright Mark Overmeer.  Licensed under the same terms as Perl itself.

package Mail::Message::Head::ListGroup;
use vars '$VERSION';
$VERSION = '3.009';

use base 'Mail::Message::Head::FieldGroup';

use strict;
use warnings;

use List::Util 'first';


sub init($$)
{   my ($self, $args) = @_;
    $self->SUPER::init($args);

    my $address = $args->{address};
       if(!defined $address) { ; }
    elsif(!ref $address || !$address->isa('Mail::Message::Field::Address'))
    {   require Mail::Message::Field::Address;
        my $mi   = Mail::Message::Field::Address->coerce($address);

        $self->log(ERROR =>
                "Cannot convert \"$address\" into an address object"), return
            unless defined $mi;

        $address = $mi;
    }
    $self->{MMHL_address}  = $address          if defined $args->{address};

    $self->{MMHL_listname} = $args->{listname} if defined $args->{listname};
    $self->{MMHL_rfc}      = $args->{rfc}      if defined $args->{rfc};
    $self->{MMHL_fns}      = [];
    $self;
}

#------------------------------------------


sub from($)
{   my ($class, $from) = @_;
    my $head = $from->isa('Mail::Message::Head') ? $from : $from->head;
    my $self = $class->new(head => $head);

    return () unless $self->collectFields;

    my ($type, $software, $version, $field);
    if(my $communigate = $head->get('X-ListServer'))
    {   ($software, $version) = $communigate =~ m/^(.*)\s+LIST\s*([\d.]+)\s*$/i;
        $type    = ($software =~ m/Pro/ ? 'CommuniGatePro' : 'CommuniGate');
    }
    elsif(my $mailman = $head->get('X-Mailman-Version'))
    {   $version = "$mailman";
        $type    = 'Mailman';
    }
    elsif(my $majordomo = $head->get('X-Majordomo-Version'))
    {   $version = "$majordomo";
        $type    = 'Majordomo';
    }
    elsif(my $ecartis = $head->get('X-Ecartis-Version'))
    {   ($software, $version) = $ecartis =~ m/^(.*)\s+(v[\d.]+)/;
        $type    = 'Ecartis';
    }
    elsif(my $listar = $head->get('X-Listar-Version'))
    {   ($software, $version) = $listar =~ m/^(.*?)\s+(v[\w.]+)/;
        $type    = 'Listar';
    }
    elsif(defined($field = $head->get('List-Software'))
          && $field =~ m/listbox/i)
    {   ($software, $version) = $field =~ m/^(\S*)\s*(v[\d.]+)\s*$/;
        $type    = 'Listbox';
    }
    elsif($field = first { m!LISTSERV-TCP/IP!s } $head->get('Received'))
    {   # Listserv is hard to recognise
        ($software, $version) = $field =~
            m!\( (LISTSERV-TCP/IP) \s+ release \s+ (\S+) \)!xs;
        $type = 'Listserv';
    }
    elsif(defined($field = $head->get('X-Mailing-List'))
          && $field =~ m[archive/latest])
    {   $type    = 'Smartlist' }
    elsif(defined($field = $head->get('Mailing-List')) && $field =~ m/yahoo/i )
    {   $type    = 'YahooGroups' }
    elsif(defined($field) && $field =~ m/(ezmlm)/i )
    {   $type    = 'Ezmlm' }
    elsif(my $fml = $head->get('X-MLServer'))
    {   ($software, $version) = $fml =~ m/^\s*(\S+)\s*\[\S*\s*([^\]]*?)\s*\]/;
        $type    = 'FML';
    }
    elsif(defined($field = $head->get('List-Subscribe')
                        || $head->get('List-Unsubscribe'))
          && $field =~ m/sympa/i)
    {   $type    = 'Sympa' }
    elsif(first { m/majordom/i } $head->get('Received'))
    {   # Majordomo is hard to recognize
        $type    = "Majordomo";
    }
    elsif($field = $head->get('List-ID') && $field =~ m/listbox\.com/i)
    {   $type    = "Listbox" }

    $self->detected($type, $software, $version);
    $self;
}

#------------------------------------------


sub rfc()
{  my $self = shift;
   return $self->{MMHL_rfc} if defined $self->{MMHL_rfc};

   my $head = $self->head;
     defined $head->get('List-Post') ? 'rfc2369'
   : defined $head->get('List-Id')   ? 'rfc2919'
   :                                    undef;
}

#------------------------------------------


sub address()
{   my $self = shift;
    return $self->{MMHL_address} if exists $self->{MMHL_address};

    my $type = $self->type || 'Unknown';
    my $head = $self->head;

    my ($field, $address);
    if($type eq 'Smartlist' && defined($field = $head->get('X-Mailing-List')))
    {   $address = $1 if $field =~ m/\<([^>]+)\>/ }
    elsif($type eq 'YahooGroups')
    {   $address = $head->get('X-Apparently-To')->unfoldedBody }
    elsif($type eq 'Listserv')
    {   $address = $head->get('Sender') }

    $address ||= $head->get('List-Post') || $head->get('Reply-To')
             || $head->get('Sender');
    $address = $address->study if ref $address;

       if(!defined $address) { ; }
    elsif(!ref $address)
    {   $address =~ s/\bowner-|-(?:owner|bounce|admin)\@//i;
        $address = Mail::Message::Field::Address->new(address => $address);
    }
    elsif($address->isa('Mail::Message::Field::Addresses'))
    {   # beautify
        $address     = ($address->addresses)[0];
        my $username = defined $address ? $address->username : '';
        if($username =~ s/^owner-|-(owner|bounce|admin)$//i)
        {   $address = Mail::Message::Field::Address->new
               (username => $username, domain => $address->domain);
        }
    }
    elsif($address->isa('Mail::Message::Field::URIs'))
    {   my $uri  = first { $_->scheme eq 'mailto' } $address->URIs;
        $address = defined $uri
                 ? Mail::Message::Field::Address->new(address => $uri->to)
                 : undef;
    }
    else  # Don't understand life anymore :-(
    {   undef $address;
    }

    $self->{MMHL_address} = $address;
}

#------------------------------------------


sub listname()
{   my $self = shift;
    return $self->{MMHL_listname} if exists $self->{MMHL_listname};

    my $head = $self->head;

    # Some lists have a field with the name only
    my $list = $head->get('List-ID') || $head->get('X-List')
            || $head->get('X-ML-Name');

    my $listname;
    if(defined $list)
    {   $listname = $list->study->decodedBody;
    }
    elsif(my $address = $self->address)
    {   $listname = $address->phrase || $address->address;
    }

    $self->{MMHL_listname} = $listname;
}

#------------------------------------------


my $list_field_names
  = qr/ ^ (?: List|X-Envelope|X-Original ) - 
      | ^ (?: Precedence|Mailing-List|Approved-By ) $
      | ^ X-(?: Loop|BeenThere|Sequence|List|Sender|MLServer ) $
      | ^ X-(?: Mailman|Listar|Egroups|Encartis|ML ) -
      | ^ X-(?: Archive|Mailing|Original|Mail|ListServer ) -
      | ^ (?: Mail-Followup|Delivered|Errors|X-Apperently ) -To $
      /xi;

sub isListGroupFieldName($) { $_[1] =~ $list_field_names }

#------------------------------------------


sub collectFields()
{   my $self = shift;
    my @names = map { $_->name } $self->head->grepNames($list_field_names);
    $self->addFields(@names);
    @names;
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

    my $address  = $self->address || 'unknown address';
    my $fields   = scalar $self->fields;
    "$type at $address$release, $fields fields";
}

#------------------------------------------


1;
