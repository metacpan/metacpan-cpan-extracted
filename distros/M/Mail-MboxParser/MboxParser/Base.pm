# Mail::MboxParser - object-oriented access to UNIX-mailboxes
# base-class for all other classes in Mail::MboxParser
#
# Copyright (C) 2001  Tassilo v. Parseval
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.

# Version: $Id: Base.pm,v 1.6 2002/02/21 09:06:14 parkerpine Exp $

package Mail::MboxParser::Base;

require 5.004;

use strict;
use vars qw($VERSION);
$VERSION = "0.07";

sub new(@) {
    my ($class, @args) = @_;

    if ($class eq __PACKAGE__) {
	use Carp;
	my $package = __PACKAGE__;
	croak <<USAGE;
$package should not really be instantiated directly. 
Instead, create one of its derived subclasses such as Mail::MboxParser.
USAGE
    }
    my $self = bless {}, $class;
    $self->init(@args);
}

sub error() { shift->{LAST_ERR} }

sub log() { shift->{LAST_LOG} }

sub reset_last { 
    my $self = shift;
    ($self->{LAST_ERR}, $self->{LAST_LOG}) = (undef, undef);
}

1;

__END__

=head1 NAME

Mail::MboxParser::Base - base clase for all other classes

=head1 DESCRIPTION

Nothing to describe nor to document here. Read L<Mail::MboxParser> on how to use the module.

=head1 VERSION

This is version 0.55.

=head1 AUTHOR AND COPYRIGHT

Tassilo von Parseval <tassilo.von.parseval@rwth-aachen.de>

Copyright (c)  2001-2005 Tassilo von Parseval.
This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
