package IO::Iron::ClientBase;

## no critic (Documentation::RequirePodAtEnd)
## no critic (Documentation::RequirePodSections)
## no critic (Subroutines::RequireArgUnpacking)

use 5.010_000;
use strict;
use warnings;

# Global creator
BEGIN {
    # No exports
}

# Global destructor
END {
}

# ABSTRACT: Base package for Client Libraries to Iron services IronCache, IronMQ and IronWorker.

our $VERSION = '0.14'; # VERSION: generated by DZP::OurPkgVersion

use Log::Any qw{$log};
use Hash::Util 0.06 qw{lock_keys unlock_keys};
use Carp::Assert::More;
use English '-no_match_vars';

sub new {
    my ($class) = @_;
    $log->tracef( 'Entering new(%s)', $class );
    my $self = {};

    # These config items are used every time when a connection to REST is made.
    my @self_keys = (    ## no critic (CodeLayout::ProhibitQuotedWordLists)
        'project_id',               # The ID of the project to use for requests.
        'connection',               # Reference to a IO::Iron::Connection object.
        'last_http_status_code',    # Contains the HTTP return code after a successful call to the remote host.
    );
    bless $self, $class;
    lock_keys( %{$self}, @self_keys );

    $log->tracef( 'Exiting new: %s', $self );
    return $self;
}

sub project_id            { return $_[0]->_access_internal( 'project_id',            $_[1] ); }
sub connection            { return $_[0]->_access_internal( 'connection',            $_[1] ); }
sub last_http_status_code { return $_[0]->_access_internal( 'last_http_status_code', $_[1] ); }

# INTERNAL METHODS
# For use in the inheriting subclass

sub _access_internal {
    my ( $self, $var_name, $var_value ) = @_;
    $log->tracef( 'Entering _access_internal(%s, %s)', $var_name, $var_value );
    if ( defined $var_value ) {
        $self->{$var_name} = $var_value;
        return $self;
    }
    else {
        return $self->{$var_name};
    }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::Iron::ClientBase - Base package for Client Libraries to Iron services IronCache, IronMQ and IronWorker.

=head1 VERSION

version 0.14

=head1 SYNOPSIS

	# new() in the inheriting sub class.

	sub new {
		my ($class, $params) = @_;
		my $self = IO::Iron::ClientBase->new();
		# Add more keys to the self hash.
		my @self_keys = (
				'caches',        # References to all objects created of class IO::Iron::IronCache::Cache.
				legal_keys(%{$self}),
		);
		unlock_keys(%{$self});
		lock_keys_plus(%{$self}, @self_keys);
		my @caches;
		$self->{'caches'} = \@caches;

		unlock_keys(%{$self});
		bless $self, $class;
		lock_keys(%{$self}, @self_keys);

		return $self;
	}

=for stopwords config Mikko Koivunalho

=head1 METHODS

=head2 new

Creator function.

Declares the mandatory items of self hash.

=head2 Getters/setters

Set or get a property.
When setting, returns the reference to the object.

=over 8

=item project_id   project_id from config.

=item connection   The Connection module.

=item last_http_status_code

=back

=head1 AUTHOR

Mikko Koivunalho <mikko.koivunalho@iki.fi>

=head1 BUGS

Please report any bugs or feature requests to bug-io-iron@rt.cpan.org or through the web interface at:
 http://rt.cpan.org/Public/Dist/Display.html?Name=IO-Iron

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by Mikko Koivunalho.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

The full text of the license can be found in the
F<LICENSE> file included with this distribution.

=cut
