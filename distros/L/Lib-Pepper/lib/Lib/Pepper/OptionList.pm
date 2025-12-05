package Lib::Pepper::OptionList;
#---AUTOPRAGMASTART---
use v5.42;
use strict;
use diagnostics;
use mro 'c3';
use English;
use Carp qw[carp croak confess cluck longmess shortmess];
our $VERSION = 0.5;
use autodie qw( close );
use Array::Contains;
use utf8;
use Data::Dumper;
use Data::Printer;
#---AUTOPRAGMAEND---


use Lib::Pepper;
use Lib::Pepper::Exception;
use Lib::Pepper::Constants qw(:special);

sub new($class, $handle = undef) {
    my $self = {
        handle => undef,
        owned  => 0,
    };

    bless $self, $class;

    if(defined $handle) {
        # Wrap an existing handle
        $self->{handle} = $handle;
        $self->{owned} = 0;
    } else {
        # Create a new option list
        my ($result, $newHandle) = Lib::Pepper::pepOptionListCreate();
        Lib::Pepper::Exception->checkResult($result, 'pepOptionListCreate');
        $self->{handle} = $newHandle;
        $self->{owned} = 1;
    }

    return $self;
}

sub getHandle($self) {
    return $self->{handle};
}

sub getString($self, $key) {
    if(!defined $key) {
        croak('getString: key parameter is required');
    }

    my ($result, $value) = Lib::Pepper::pepOptionListGetStringElement($self->{handle}, $key);
    Lib::Pepper::Exception->checkResult($result, "getString('$key')");

    return $value;
}

sub getInt($self, $key) {
    if(!defined $key) {
        croak('getInt: key parameter is required');
    }

    my ($result, $value) = Lib::Pepper::pepOptionListGetIntElement($self->{handle}, $key);
    Lib::Pepper::Exception->checkResult($result, "getInt('$key')");

    return $value;
}

sub getChild($self, $key) {
    if(!defined $key) {
        croak('getChild: key parameter is required');
    }

    my ($result, $childHandle) = Lib::Pepper::pepOptionListGetChildOptionListElement($self->{handle}, $key);
    Lib::Pepper::Exception->checkResult($result, "getChild('$key')");

    # Wrap the child handle in a new OptionList object (non-owned)
    return Lib::Pepper::OptionList->new($childHandle);
}

sub addString($self, $key, $value) {
    if(!defined $key) {
        croak('addString: key parameter is required');
    }
    if(!defined $value) {
        croak('addString: value parameter is required');
    }

    my $result = Lib::Pepper::pepOptionListAddStringElement($self->{handle}, $key, $value);
    Lib::Pepper::Exception->checkResult($result, "addString('$key')");

    return $self;
}

sub addInt($self, $key, $value) {
    if(!defined $key) {
        croak('addInt: key parameter is required');
    }
    if(!defined $value) {
        croak('addInt: value parameter is required');
    }

    my $result = Lib::Pepper::pepOptionListAddIntElement($self->{handle}, $key, $value);
    Lib::Pepper::Exception->checkResult($result, "addInt('$key')");

    return $self;
}

sub addChild($self, $key, $childOptionList) {
    if(!defined $key) {
        croak('addChild: key parameter is required');
    }
    if(!defined $childOptionList || !ref($childOptionList) || !$childOptionList->isa('Lib::Pepper::OptionList')) {
        croak('addChild: childOptionList must be a Lib::Pepper::OptionList object');
    }

    my $childHandle = $childOptionList->getHandle();
    my $result = Lib::Pepper::pepOptionListAddChildOptionListElement($self->{handle}, $key, $childHandle);
    Lib::Pepper::Exception->checkResult($result, "addChild('$key')");

    return $self;
}

sub getElementList($self) {
    my ($result, $elementList) = Lib::Pepper::pepOptionListGetElementList($self->{handle});
    Lib::Pepper::Exception->checkResult($result, 'getElementList');

    # Parse comma-separated list
    if(!defined $elementList || $elementList eq '') {
        return [];
    }

    my @elements = split(/,/, $elementList);
    return \@elements;
}

sub toHashref($self) {
    my $elements = $self->getElementList();
    my $hashref = {};

    for my $key (@{$elements}) {
        # Try to get as int first
        my ($result, $value) = Lib::Pepper::pepOptionListGetIntElement($self->{handle}, $key);

        if(Lib::Pepper::Exception->isSuccess($result)) {
            $hashref->{$key} = $value;
            next;
        }

        # Try as string
        ($result, $value) = Lib::Pepper::pepOptionListGetStringElement($self->{handle}, $key);

        if(Lib::Pepper::Exception->isSuccess($result)) {
            $hashref->{$key} = $value;
            next;
        }

        # Try as child option list
        ($result, my $childHandle) = Lib::Pepper::pepOptionListGetChildOptionListElement($self->{handle}, $key);

        if(Lib::Pepper::Exception->isSuccess($result)) {
            my $childList = Lib::Pepper::OptionList->new($childHandle);
            $hashref->{$key} = $childList->toHashref();
            next;
        }

        # If we get here, we couldn't get the value
        carp("Warning: Could not retrieve value for key '$key'");
    }

    return $hashref;
}

sub fromHashref($class, $hashref) {
    if(!defined $hashref || ref($hashref) ne 'HASH') {
        croak('fromHashref: hashref parameter must be a hash reference');
    }

    my $optionList = $class->new();

    for my $key (sort keys %{$hashref}) {
        my $value = $hashref->{$key};

        if(!defined $value) {
            # Skip undefined values
            next;
        } elsif(ref($value) eq 'HASH') {
            # Nested hash - create child option list
            my $childList = $class->fromHashref($value);
            $optionList->addChild($key, $childList);
        } elsif(ref($value) eq '') {
            # Scalar value - use key prefix to determine type: i=int, s=string, h=handle/child
            if($key =~ /^i/) {
                $optionList->addInt($key, $value);
            } else {
                $optionList->addString($key, $value);
            }
        } else {
            croak("fromHashref: unsupported value type for key '$key': " . ref($value));
        }
    }

    return $optionList;
}

sub DESTROY($self) {
    # Note: We don't free the handle here because the Pepper library
    # manages option list memory internally. Option lists are typically
    # freed when the instance they're associated with is freed.
    # Only free if we explicitly own it (future enhancement)
    return;
}

1;

__END__

=head1 NAME

Lib::Pepper::OptionList - Object-oriented wrapper for Pepper option lists

=head1 SYNOPSIS

    use Lib::Pepper::OptionList;

    # Create a new option list
    my $options = Lib::Pepper::OptionList->new();

    # Add values
    $options->addString('sHostName', '192.168.1.100:20007');
    $options->addInt('iTerminalType', 118);
    $options->addInt('iAmount', 10_050);  # 100.50 EUR in cents

    # Create nested option list
    my $childOptions = Lib::Pepper::OptionList->new();
    $childOptions->addString('sValue', 'test');
    $options->addChild('hChild', $childOptions);

    # Retrieve values
    my $hostname = $options->getString('sHostName');
    my $amount = $options->getInt('iAmount');
    my $child = $options->getChild('hChild');

    # Convert to/from hashref
    my $hashref = $options->toHashref();
    my $newOptions = Lib::Pepper::OptionList->fromHashref($hashref);

    # Get list of all keys
    my $elements = $options->getElementList();

=head1 DESCRIPTION

Lib::Pepper::OptionList provides an object-oriented interface to Pepper option lists.
Option lists are key-value stores used throughout the Pepper API for passing
configuration and receiving results.

This class wraps the low-level XS functions and provides convenient methods for
working with option lists, including conversion to/from Perl hashrefs.

=head1 METHODS

=head2 new([$handle])

Constructor. Creates a new option list or wraps an existing handle.

    my $options = Lib::Pepper::OptionList->new();           # Create new
    my $wrapped = Lib::Pepper::OptionList->new($handle);    # Wrap existing

Parameters:
- $handle: Optional. Existing option list handle to wrap.

Returns: Lib::Pepper::OptionList object

=head2 getHandle()

Returns the underlying C handle for this option list.

    my $handle = $options->getHandle();

Returns: Integer handle value

=head2 getString($key)

Retrieves a string value from the option list.

    my $hostname = $options->getString('sHostName');

Parameters:
- $key: The option key to retrieve

Returns: String value

Throws: Exception if key not found or wrong type

=head2 getInt($key)

Retrieves an integer value from the option list.

    my $amount = $options->getInt('iAmount');

Parameters:
- $key: The option key to retrieve

Returns: Integer value

Throws: Exception if key not found or wrong type

=head2 getChild($key)

Retrieves a child option list.

    my $child = $options->getChild('hTicket');

Parameters:
- $key: The option key to retrieve

Returns: Lib::Pepper::OptionList object

Throws: Exception if key not found or wrong type

=head2 addString($key, $value)

Adds a string value to the option list.

    $options->addString('sPosNumber', 'POS-001');

Parameters:
- $key: The option key
- $value: The string value

Returns: $self (for method chaining)

=head2 addInt($key, $value)

Adds an integer value to the option list.

    $options->addInt('iAmount', 10_000);

Parameters:
- $key: The option key
- $value: The integer value

Returns: $self (for method chaining)

=head2 addChild($key, $childOptionList)

Adds a child option list.

    my $child = Lib::Pepper::OptionList->new();
    $child->addString('sValue', 'test');
    $options->addChild('hChild', $child);

Parameters:
- $key: The option key
- $childOptionList: Lib::Pepper::OptionList object

Returns: $self (for method chaining)

=head2 getElementList()

Returns an array reference of all keys in the option list.

    my $keys = $options->getElementList();
    for my $key (@$keys) {
        print "Key: $key\n";
    }

Returns: Array reference of key strings

=head2 toHashref()

Converts the option list to a Perl hashref. Nested option lists
become nested hashes.

    my $hashref = $options->toHashref();

Returns: Hash reference

=head2 fromHashref($hashref)

Class method. Creates a new option list from a Perl hashref.
Values are automatically typed (integer vs string). Nested hashes
become child option lists.

    my $options = Lib::Pepper::OptionList->fromHashref({
        sHostName => '192.168.1.100:20007',
        iAmount => 10_000,
        hConfig => {
            sValue => 'test',
        },
    });

Parameters:
- $hashref: Hash reference to convert

Returns: New Lib::Pepper::OptionList object

=head1 NAMING CONVENTIONS

Pepper option list keys use Hungarian notation prefixes:

- s: String values (e.g., sHostName, sPosNumber)
- i: Integer values (e.g., iAmount, iTerminalType)
- h: Handle/child option lists (e.g., hTicket, hConfig)

=head1 WARNING: AI USE

Warning, this file was generated with the help of the 'Claude' AI (an LLM/large
language model by the USA company Anthropic PBC) in November 2025. It was not
reviewed line-by-line by a human, only on a functional level. It is therefore
not up to the usual code quality and review standards. Different copyright laws
may also apply, since the program was not created by humans but mostly by a machine,
therefore the laws requiring a human creative process may or may not apply. Laws
regarding AI use are changing rapidly. Before using the code provided in this
file for any of your projects, make sure to check the current version of your
local laws.

=head1 AUTHOR

Rene Schickbauer, E<lt>cavac@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2025 by Rene Schickbauer

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.42.0 or,
at your option, any later version of Perl 5 you may have available.

=cut
