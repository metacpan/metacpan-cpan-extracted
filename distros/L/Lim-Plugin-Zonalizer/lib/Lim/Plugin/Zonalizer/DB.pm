package Lim::Plugin::Zonalizer::DB;

use utf8;
use common::sense;

use Carp;
use Log::Log4perl ();
use Scalar::Util qw(weaken);

use Lim ();
use Lim::Plugin::Zonalizer qw(:status);

=encoding utf8

=head1 NAME

Lim::Plugin::Zonalizer::DB - The database interface for Zonalizer

=head1 SYNOPSIS

  package Lim::Plugin::Zonalizer::DB::MyDatabase;

  use base qw(Lim::Plugin::Zonalizer::DB);

=head1 METHODS

=over 4

=item $db = Lim::Plugin::Zonalizer::DB->new (...)

Create a new database object, arguments are passed to the backend specific
database module via C<Init>.

=cut

sub new {
    my ( $this, %args ) = @_;
    my $class = ref( $this ) ? ref( $this ) : $this;
    my $self = { logger => Log::Log4perl->get_logger };
    bless $self, $class;
    weaken( $self->{logger} );

    $self->Init( %args );

    # uncoverable branch false
    Lim::OBJ_DEBUG and $self->{logger}->debug( 'new ', __PACKAGE__, ' ', $self );
    return $self;
}

sub DESTROY {
    my ( $self ) = @_;

    # uncoverable branch false
    Lim::OBJ_DEBUG and $self->{logger}->debug( 'destroy ', __PACKAGE__, ' ', $self );

    $self->Destroy;
    return;
}

=item $db->Init (...)

Called upon creation of the object, arguments should be handled in the backend
specific database module.

=cut

sub Init {
}

=item $db->Destroy

Called upon destruction of the object.

=cut

sub Destroy {
}

=item $name = $db->Name

Return the name of the module, must be overloaded.

=cut

sub Name {
    confess 'Name is not overloaded';
}

=item $db->ReadAnalysis (parameter => value, ...)

Read analyze objects from the database and return them via the callback provided.

Most arguments are passed through from API calls, see API documentation for
details.

=over 4

=item space => string

The space to read from, see Spaces in API documentation.

=item search => string

=item limit => number

=item sort => string

=item direction => string

=item after => id

=item before => id

=item cb => sub { my ($paging, @analysis) = @_; ... }

The callback subrutin that will be called upon success or failure, if there
was an error then C<$@> will be set with the error.

=over 4

=item $paging

A hash reference with details about the pagination or undef if no pagination
is available (i.e. not enough data).

=over 4

=item previous

The identifier for the previous object.

=item next

The identifier for the next object.

=back

=item @analysis

An array with all the analyze objects found.

=back

=back

=cut

sub ReadAnalysis {
    confess 'ReadAnalysis is not overloaded';
}

=item $db->DeleteAnalysis

Delete all analysis from the database.

=over 4

=item space => string

The space to delete in, see Spaces in API documentation.

=item cb => sub { my ($deleted_analysis) = @_; ... }

The callback subrutin that will be called upon success or failure, if there
was an error then C<$@> will be set with the error.

=over 4

=item $deleted_analysis

The number of delete analyze objects.

=back

=back

=cut

sub DeleteAnalysis {
    confess 'DeleteAnalysis is not overloaded';
}

=item $db->CreateAnalyze (parameter => value, ...)

Create a new analyze object in the database.

=over 4

=item space => string

The space to create in, see Spaces in API documentation.

=item analyze => hash

The analyze object to create, see API documentation for details.

=item cb => sub { my ($analyze) = @_; ... }

The callback subrutin that will be called upon success or failure, if there
was an error then C<$@> will be set with the error.

=over 4

=item $analyze

The analyze object created.

=back

=back

=cut

sub CreateAnalyze {
    confess 'CreateAnalyze is not overloaded';
}

=item $db->ReadAnalyze (parameter => value, ...)

Read a analyze object from the database and return it via the callback provided.

=over 4

=item space => string

The space to read from, see Spaces in API documentation.

=item id => id

The analyze identifier to read.

=item cb => sub { my ($analyze) = @_; ... }

The callback subrutin that will be called upon success or failure, if there
was an error then C<$@> will be set with the error.

=over 4

=item $analyze

The analyze object read.

=back

=back

=cut

sub ReadAnalyze {
    confess 'ReadAnalyze is not overloaded';
}

=item $db->UpdateAnalyze (parameter => value, ...)

Update a analyze object in the database.

=over 4

=item space => string

The space to update in, see Spaces in API documentation.

=item analyze => hash

The updated analyze object, this object must have been read from the database.

=item cb => sub { my ($analyze) = @_; ... }

The callback subrutin that will be called upon success or failure, if there
was an error then C<$@> will be set with the error.

=over 4

=item $analyze

The updated analyze object.

=back

=back

=cut

sub UpdateAnalyze {
    confess 'UpdateAnalyze is not overloaded';
}

=item $db->DeleteAnalyze (parameter => value, ...)

Delete a analyze object from the database.

=over 4

=item space => string

The space to delete in, see Spaces in API documentation.

=item id => id

The analyze identifier to delete.

=item cb => sub { ... }

The callback subrutin that will be called upon success or failure, if there
was an error then C<$@> will be set with the error.

=back

=cut

sub DeleteAnalyze {
    confess 'DeleteAnalyze is not overloaded';
}

=item $db->ValidateAnalyze ($analyze)

Validate a analyze object and confess if there are any problems.

=over 4

=item $analyze

The analyze object to validate.

=back

=cut

sub ValidateAnalyze {
    my ( $self, $analyze ) = @_;

    unless ( ref( $analyze ) eq 'HASH' ) {
        confess 'analyze is not HASH';
    }
    foreach ( qw(id fqdn status progress created updated ipv4 ipv6) ) {
        unless ( defined $analyze->{$_} ) {
            confess 'analyze->' . $_ . ' is not defined';
        }
    }
    unless ( $analyze->{fqdn} =~ /^(?:[a-zA-Z0-9-]+\.)*[a-zA-Z0-9-]+\.$/o ) {
        confess 'analyze->fqdn invalid';
    }
    foreach ( qw(progress created updated) ) {
        unless ( $analyze->{$_} == ( $analyze->{$_} + 0 ) ) {
            confess 'analyze->' . $_ . ' is not a numeric value';
        }
    }
    unless ( grep { $analyze->{status} eq $_ } ( STATUS_RESERVED, STATUS_QUEUED, STATUS_ANALYZING, STATUS_DONE, STATUS_FAILED, STATUS_STOPPED, STATUS_UNKNOWN ) ) {
        confess 'analyze->status is invalid';
    }
    if ( exists $analyze->{policy} ) {
        unless ( ref( $analyze->{policy} ) eq 'HASH' ) {
            confess 'analyze->policy is not HASH';
        }
        foreach ( qw(name display) ) {
            unless ( defined $analyze->{policy}->{$_} ) {
                confess 'analyze->policy->' . $_ . ' is not defined';
            }
        }
        foreach ( qw(description) ) {
            if ( exists $analyze->{policy}->{$_} and !defined $analyze->{policy}->{$_} ) {
                confess 'analyze->policy->' . $_ . ' is not defined';
            }
        }
    }
    if ( exists $analyze->{error} ) {
        unless ( ref( $analyze->{error} ) eq 'HASH' ) {
            confess 'analyze->error is not HASH';
        }
        foreach ( qw(code message) ) {
            unless ( defined $analyze->{error}->{$_} ) {
                confess 'analyze->error->' . $_ . ' is not defined';
            }
        }
    }
    if ( exists $analyze->{summary} ) {
        unless ( ref( $analyze->{summary} ) eq 'HASH' ) {
            confess 'analyze->summary is not HASH';
        }
        foreach ( qw(notice warning error critical) ) {
            unless ( defined $analyze->{summary}->{$_} ) {
                confess 'analyze->summary->' . $_ . ' is not defined';
            }
            unless ( $analyze->{summary}->{$_} == ( $analyze->{summary}->{$_} + 0 ) ) {
                confess 'analyze->{summary}->' . $_ . ' is not a numeric value';
            }
        }
    }
    if ( exists $analyze->{results} ) {
        eval { $self->ValidateResults( $analyze->{results} ); };
        if ( $@ ) {
            confess 'analyze->results is invalid: ' . $@;
        }
    }
    if ( exists $analyze->{ns} ) {
        unless ( ref( $analyze->{ns} ) eq 'ARRAY' ) {
            confess 'analyze->ns is not ARRAY';
        }
        my $count = 1;
        foreach my $ns ( @{ $analyze->{ns} } ) {
            unless ( ref( $ns ) eq 'HASH' ) {
                confess 'analyze->ns[' . $count . '] is not HASH';
            }
            foreach ( qw(fqdn) ) {
                unless ( defined $ns->{$_} ) {
                    confess 'analyze->ns[' . $count . ']->' . $_ . ' is not defined';
                }
            }
            foreach ( qw(ip) ) {
                if ( exists $ns->{$_} and !defined $ns->{$_} ) {
                    confess 'analyze->ns[' . $count . ']->' . $_ . ' is not defined';
                }
            }
            $count++;
        }
    }
    if ( exists $analyze->{ds} ) {
        unless ( ref( $analyze->{ds} ) eq 'ARRAY' ) {
            confess 'analyze->ds is not ARRAY';
        }
        my $count = 1;
        foreach my $ds ( @{ $analyze->{ds} } ) {
            unless ( ref( $ds ) eq 'HASH' ) {
                confess 'analyze->ds[' . $count . '] is not HASH';
            }
            foreach ( qw(keytag algorithm type digest) ) {
                unless ( defined $ds->{$_} ) {
                    confess 'analyze->ds[' . $count . ']->' . $_ . ' is not defined';
                }
            }
            $count++;
        }
    }
    if ( exists $analyze->{meta_data} ) {
        unless ( ref( $analyze->{meta_data} ) eq 'ARRAY' ) {
            confess 'analyze->meta_data is not ARRAY';
        }
        my $count = 1;
        foreach my $meta_data ( @{ $analyze->{meta_data} } ) {
            unless ( ref( $meta_data ) eq 'HASH' ) {
                confess 'analyze->meta_data[' . $count . '] is not HASH';
            }
            foreach ( qw(key value) ) {
                unless ( defined $meta_data->{$_} ) {
                    confess 'analyze->meta_data[' . $count . ']->' . $_ . ' is not defined';
                }
            }
            $count++;
        }
    }
    return;
}

=item $db->ValidateResults ($results)

Validate a set of result objects and confess if there are any problems.

=over 4

=item $results

An array ref with the result objects to validate.

=back

=cut

sub ValidateResults {
    my ( $self, $results ) = @_;

    unless ( ref( $results ) eq 'ARRAY' ) {
        confess 'results is not ARRAY';
    }
    my $count = 1;
    foreach ( @$results ) {
        eval { $self->ValidateResult( $_ ); };
        if ( $@ ) {
            confess 'result[' . $count . '] is invalid: ' . $@;
        }
        $count++;
    }
    return;
}

=item $db->ValidateResult ($result)

Validate a result object and confess if there are any problems.

=over 4

=item $result

The result object to validate.

=back

=cut

sub ValidateResult {
    my ( $self, $result ) = @_;

    unless ( ref( $result ) eq 'HASH' ) {
        confess 'result is not HASH';
    }
    foreach ( qw(_id level module tag timestamp) ) {
        unless ( defined $result->{$_} ) {
            confess 'result->' . $_ . ' is not defined';
        }
    }
    foreach ( qw(_id timestamp) ) {
        unless ( $result->{$_} == ( $result->{$_} + 0 ) ) {
            confess 'result->' . $_ . ' is not a numeric value';
        }
    }
    if ( exists $result->{args} ) {
        unless ( ref( $result->{args} ) eq 'HASH' ) {
            confess 'result->args is not HASH';
        }
    }
    return;
}

=back

=head1 AUTHOR

Jerry Lundström, C<< <lundstrom.jerry@gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to L<https://github.com/jelu/lim-plugin-zonalizer/issues>.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Lim::Plugin::Zonalizer::DB

You can also look for information at:

=over 4

=item * Lim issue tracker (report bugs here)

L<https://github.com/jelu/lim-plugin-zonalizer/issues>

=back

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

Copyright 2015-2016 Jerry Lundström
Copyright 2015-2016 IIS (The Internet Foundation in Sweden)

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1;    # End of Lim::Plugin::Zonalizer::DB
