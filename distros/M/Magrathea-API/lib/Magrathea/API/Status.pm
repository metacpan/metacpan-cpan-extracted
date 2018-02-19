package Magrathea::API::Status;

use strict;
use warnings;
use 5.10.0;

use version 0.77; our $VERSION = qv('v0.9.0');
use experimental qw{ switch };

use Phone::Number;
use Attribute::Boolean;

use Carp;

use overload q("") => \&stringify;

=head1 NAME

Magrathea::API::Status - A status return for a number

=cut

sub get_type($)
{
    my $type = shift;
    given ($type)
    {
	when (/^[Ss]:/)
	{
	    return 'sip';
	}
	when (/^I:/)
	{
	    return 'iax2';
	}
	when (/^F:/)
	{
	    return 'fax2email';
	}
	when (/^V:/)
	{
	    return 'voice2email';
	}
	when (/^\d+$/)
	{
	    return 'divert';
	}
	default {
	    return 'unallocated';
	}
    }
}

=head1 CLASS FUNCTIONS

=head2 new

Usually only called by L<Magrathea::API>.

    my $status = new Magrathea:API::Status($status);

=cut

sub new
{
    my $class = shift;
    my $string = shift;
    return undef if $string =~ /^\s*$/;
    my ($number, $status, $expiry, $target) = split /\s/, $string;
    my $type = get_type $target;
    $target =~ s/.:(.*)/$1/;
    $target = new Phone::Number($target) if $type eq 'divert';
    my $active:Boolean = $status eq 'Y';
    my $self = {
	number	=> new Phone::Number($number),
	active	=> $active,
	expiry	=> $expiry,
	type	=> $type,
	target	=> $target,
	entry	=> 1,
    };
    bless $self, $class;
}

sub AUTOLOAD
{
    my $self = shift;
    my $value = shift;
    (my $name = our $AUTOLOAD) =~ s/.*://;
    croak "Unknown command: $name" unless defined $self->{$name};
    $self->{$name} = $value if defined $value;
    return $self->{$name};
}

sub stringify
{
    my $self = shift;
    return sprintf '%s %s', $self->type, $self->target;
}

sub DESTROY { }

__END__

=head1 DOCUMENTATION

For documentation on this module, please see L<Magrathrea::API>.

=head1 AUTHOR

Cliff Stanford, E<lt>cliff@may.beE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by Cliff Stanford

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.

=cut

