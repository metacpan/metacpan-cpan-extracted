#
# Mail::SPF::Exception
# Mail::SPF exception classes.
#
# (C) 2006 Julian Mehnle <julian@mehnle.net>
# $Id: Exception.pm 36 2006-12-09 19:01:46Z Julian Mehnle $
#
##############################################################################

package Mail::SPF::Exception;

use warnings;
use strict;

use base 'Error', 'Mail::SPF::Base';

use constant TRUE   => (0 == 0);
use constant FALSE  => not TRUE;

sub new {
    my ($self, $text) = @_;
    local $Error::Depth = $Error::Depth + 1;
    return $self->SUPER::new(
        defined($text) ? (-text => $text) : ()
    );
}

sub stringify {
    my ($self) = @_;
    my $text = $self->SUPER::stringify;
    $text .= sprintf(" (%s) at %s line %d.\n", $self->name, $self->file, $self->line)
        if $text !~ /\n$/s;
    return $text;
}

sub name {
    my ($self) = @_;
    my $class = ref($self) || $self;
    return $class =~ /^Mail::SPF::(\w+)$/ ? $1 : $class;
}


# Generic Exceptions
##############################################################################

# Tried to call a class method as an instance method:
package Mail::SPF::EClassMethod;
our @ISA = qw(Mail::SPF::Exception);

sub new {
    my ($self) = @_;
    local $Error::Depth = $Error::Depth + 2;
    return $self->SUPER::new(
        sprintf('Pure class method %s called as an instance method', (caller($Error::Depth - 1))[3])
    );
}

# Tried to call an instance method as a class method:
package Mail::SPF::EInstanceMethod;
our @ISA = qw(Mail::SPF::Exception);

sub new {
    my ($self) = @_;
    local $Error::Depth = $Error::Depth + 2;
    return $self->SUPER::new(
        sprintf('Pure instance method %s called as a class method', (caller($Error::Depth - 1))[3])
    );
}

# Abstract class cannot be instantiated:
package Mail::SPF::EAbstractClass;
our @ISA = qw(Mail::SPF::Exception);

sub new {
    my ($self) = @_;
    local $Error::Depth = $Error::Depth + 2;
    return $self->SUPER::new('Abstract class cannot be instantiated');
}

# Missing required method option:
package Mail::SPF::EOptionRequired;
our @ISA = qw(Mail::SPF::Exception);

# Invalid value for method option:
package Mail::SPF::EInvalidOptionValue;
our @ISA = qw(Mail::SPF::Exception);

# Read-only value:
package Mail::SPF::EReadOnlyValue;
our @ISA = qw(Mail::SPF::Exception);


# Miscellaneous Errors
##############################################################################

# DNS error:
package Mail::SPF::EDNSError;
our @ISA = qw(Mail::SPF::Exception);

# DNS timeout:
package Mail::SPF::EDNSTimeout;
our @ISA = qw(Mail::SPF::EDNSError);

# Record selection error:
package Mail::SPF::ERecordSelectionError;
our @ISA = qw(Mail::SPF::Exception);

# No acceptable record found:
package Mail::SPF::ENoAcceptableRecord;
our @ISA = qw(Mail::SPF::ERecordSelectionError);

# Redundant acceptable records found:
package Mail::SPF::ERedundantAcceptableRecords;
our @ISA = qw(Mail::SPF::ERecordSelectionError);

# No unparsed text available:
package Mail::SPF::ENoUnparsedText;
our @ISA = qw(Mail::SPF::Exception);

# Unexpected term object encountered:
package Mail::SPF::EUnexpectedTermObject;
our @ISA = qw(Mail::SPF::Exception);

# Processing limit exceeded:
package Mail::SPF::EProcessingLimitExceeded;
our @ISA = qw(Mail::SPF::Exception);

# Missing required context for macro expansion:
package Mail::SPF::EMacroExpansionCtxRequired;
our @ISA = qw(Mail::SPF::EOptionRequired);


# Parser Errors
##############################################################################

# Nothing to parse:
package Mail::SPF::ENothingToParse;
our @ISA = qw(Mail::SPF::Exception);

# Generic syntax error:
package Mail::SPF::ESyntaxError;
our @ISA = qw(Mail::SPF::Exception);

# Invalid record version:
package Mail::SPF::EInvalidRecordVersion;
our @ISA = qw(Mail::SPF::ESyntaxError);

# Invalid scope:
package Mail::SPF::EInvalidScope;
our @ISA = qw(Mail::SPF::ESyntaxError);

# Junk encountered in record:
package Mail::SPF::EJunkInRecord;
our @ISA = qw(Mail::SPF::ESyntaxError);

# Invalid term:
package Mail::SPF::EInvalidTerm;
our @ISA = qw(Mail::SPF::ESyntaxError);

# Junk encountered in term:
package Mail::SPF::EJunkInTerm;
our @ISA = qw(Mail::SPF::ESyntaxError);

# Invalid modifier:
package Mail::SPF::EInvalidMod;
our @ISA = qw(Mail::SPF::EInvalidTerm);

# Duplicate global modifier:
package Mail::SPF::EDuplicateGlobalMod;
our @ISA = qw(Mail::SPF::EInvalidMod);

# Invalid mechanism:
package Mail::SPF::EInvalidMech;
our @ISA = qw(Mail::SPF::EInvalidTerm);

# Invalid mechanism qualifier:
package Mail::SPF::EInvalidMechQualifier;
our @ISA = qw(Mail::SPF::EInvalidMech);

# Missing required <domain-spec> in term:
package Mail::SPF::ETermDomainSpecExpected;
our @ISA = qw(Mail::SPF::ESyntaxError);

# Missing required <ip4-network> in term:
package Mail::SPF::ETermIPv4AddressExpected;
our @ISA = qw(Mail::SPF::ESyntaxError);

# Missing required <ip4-cidr-length> in term:
package Mail::SPF::ETermIPv4PrefixLengthExpected;
our @ISA = qw(Mail::SPF::ESyntaxError);

# Missing required <ip6-network> in term:
package Mail::SPF::ETermIPv6AddressExpected;
our @ISA = qw(Mail::SPF::ESyntaxError);

# Missing required <ip6-cidr-length> in term:
package Mail::SPF::ETermIPv6PrefixLengthExpected;
our @ISA = qw(Mail::SPF::ESyntaxError);

# Invalid macro string:
package Mail::SPF::EInvalidMacroString;
our @ISA = qw(Mail::SPF::ESyntaxError);

# Invalid macro:
package Mail::SPF::EInvalidMacro;
our @ISA = qw(Mail::SPF::EInvalidMacroString);


package Mail::SPF::Exception;

TRUE;
