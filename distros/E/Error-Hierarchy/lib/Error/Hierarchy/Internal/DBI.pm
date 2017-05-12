use 5.008;
use strict;
use warnings;

package Error::Hierarchy::Internal::DBI;
BEGIN {
  $Error::Hierarchy::Internal::DBI::VERSION = '1.103530';
}
# ABSTRACT: DBI-related exception
use parent 'Error::Hierarchy::Internal::CustomMessage';

# DBI exceptions store extra values, but don't use them in the message string.
# They are marked as properties, however, so generic exception handling code
# can introspect them.
__PACKAGE__->mk_accessors(
    qw(
      error err errstr state retval
      )
);
use constant PROPERTIES => (qw(error err errstr state retval));

sub init {
    my ($self, %args) = @_;

    # because we call SUPER::init(), which uses caller() to set
    # package, filename and line of the exception:
    local $Error::Depth = $Error::Depth + 1;
    $self->SUPER::init(%args);
    $self->custom_message($args{error} || $args{errstr});
    $self = $self->transmute_exception;

    # be sure to call this after transmuting as the new class might not want
    # to emit a warning by overriding that method.
    $self->emit_warning;
}
sub transmute_exception { $_[0] }

# Warn the exception so we see it while testing (otherwise it might be
# swallowed by some catch block). In a separate method so subclasses can
# override it.
our $SkipWarning = 0;

sub emit_warning {
    return if $SkipWarning;
    my $self = shift;
    warn "$self";
}

sub handler {
    shift;    # We don't need the class name
    my %args  = @_;
    %args = (
        sth_exception_class => 'Error::Hierarchy::Internal::DBI::STH',
        %args,
    );
    my $sth_exception_class = $args{sth_exception_class};
    sub {
        my ($err, $dbh, $retval) = @_;
        if (ref $dbh) {
            my @context = caller($Error::Depth);

            # Assemble arguments for a handle exception.
            my @params = (
                error               => $err,
                errstr              => $dbh->errstr,
                err                 => $dbh->err,
                state               => $dbh->state,
                retval              => $retval,
                warn                => $dbh->{Warn},
                active              => $dbh->{Active},
                kids                => $dbh->{Kids},
                active_kids         => $dbh->{ActiveKids},
                compat_mode         => $dbh->{CompatMode},
                inactive_destroy    => $dbh->{InactiveDestroy},
                trace_level         => $dbh->{TraceLevel},
                fetch_hash_key_name => $dbh->{FetchHashKeyName},
                chop_blanks         => $dbh->{ChopBlanks},
                long_read_len       => $dbh->{LongReadLen},
                long_trunc_ok       => $dbh->{LongTruncOk},
                taint               => $dbh->{Taint},
                package             => $context[0],
                filename            => $context[1],
                line                => $context[2],
            );
            if (UNIVERSAL::isa($dbh, 'DBI::dr')) {

                # Just throw a driver exception. It has no extra attributes.
                throw Error::Hierarchy::Internal::DBI::DRH(@params);
            } elsif (UNIVERSAL::isa($dbh, 'DBI::db')) {

                # Throw a database handle exception.
                throw Error::Hierarchy::Internal::DBI::DBH(
                    @params,
                    auto_commit    => $dbh->{AutoCommit},
                    db_name        => $dbh->{Name},
                    statement      => $dbh->{Statement},
                    row_cache_size => $dbh->{RowCacheSize}
                );
            } elsif (UNIVERSAL::isa($dbh, 'DBI::st')) {

                # Throw a statement handle exception.
                throw $sth_exception_class(
                    @params,
                    num_of_fields => $dbh->{NUM_OF_FIELDS},
                    num_of_params => $dbh->{NUM_OF_PARAMS},
                    field_names   => $dbh->{NAME},
                    type          => $dbh->{TYPE},
                    precision     => $dbh->{PRECISION},
                    scale         => $dbh->{SCALE},
                    nullable      => $dbh->{NULLABLE},
                    cursor_name   => $dbh->{CursorName},
                    param_values  => $dbh->{ParamValues},
                    statement     => $dbh->{Statement},
                    rows_in_cache => $dbh->{RowsInCache}
                );
            } else {

                # Unknown exception. This shouldn't happen.
                throw Error::Hierarchy::Internal::DBI::Unknown(@params);
            }
        } else {

            # Set up for a base class exception.
            my $exc = 'Error::Hierarchy::Internal::DBI';

            # Make it an unknown exception if $dbh isn't a DBI class
            # name. Probably shouldn't happen.
            #
            unless ($dbh and UNIVERSAL::isa($dbh, 'DBI')) {
                $exc .= '::Unknown';
                eval "require $exc";
            }
            no warnings 'once';
            if ($DBI::lasth) {

                # There was a handle. Get the errors. This may be superfluous,
                # since the handle ought to be in $dbh.
                throw $exc(
                    error  => $err,
                    errstr => $DBI::errstr,
                    err    => $DBI::err,
                    state  => $DBI::state,
                    retval => $retval
                );
            } else {

                # No handle, no errors.
                throw $exc(
                    error  => $err,
                    retval => $retval
                );
            }
        }
    };
}
1;


__END__
=pod

=head1 NAME

Error::Hierarchy::Internal::DBI - DBI-related exception

=head1 VERSION

version 1.103530

=head1 SYNOPSIS

    my $connect_string = '...';
    my $dbuser         = '...';
    my $dbpass         = '...';

    my $dbh = DBI->connect($connect_string, $dbuser, $dbpass,
        { HandleError => Error::Hierarchy::Internal::DBI->handler });

=head1 DESCRIPTION

This class is the main part of the DBI-related exceptions. If you set it as
the error handler in a C<DBI->connect()> call, it will turn the simple string
errors thrown by DBI (and the database) into more meaningful exceptions.

=head1 METHODS

=head2 init

Initializes a newly constructed exception object. It transmutes the exception,
then calls C<emit_warning()> on the object.

=head2 transmute_exception

Give subclasses a chance to turn generic DBI exceptions into something more
specific for their database schema. This method is supposed to bless the
exception into the desired package or create a new one and must return it; it
is called in C<init()>.

=head2 emit_warning

Warns via C<warn()> unless the package global C<SkipWarning> is set.

=head2 handler

Turns the DBI error into the appropriate C<Error::Hierarchy::Internal::DBI::*>
exception object.

=head1 PROPERTIES

This exception class inherits all properties of
L<Error::Hierarchy::Internal::CustomMessage>.

It has the following additional properties.

=over 4

=item C<error>

=item C<err>

=item C<errstr>

=item C<state>

=item C<retval>

=back

=head1 INSTALLATION

See perlmodinstall for information and options on installing Perl modules.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests through the web interface at
L<http://rt.cpan.org/Public/Dist/Display.html?Name=Error-Hierarchy>.

=head1 AVAILABILITY

The latest version of this module is available from the Comprehensive Perl
Archive Network (CPAN). Visit L<http://www.perl.com/CPAN/> to find a CPAN
site near you, or see L<http://search.cpan.org/dist/Error-Hierarchy/>.

The development version lives at L<http://github.com/hanekomu/Error-Hierarchy>
and may be cloned from L<git://github.com/hanekomu/Error-Hierarchy>.
Instead of sending patches, please fork this project using the standard
git and github infrastructure.

=head1 AUTHOR

Marcel Gruenauer <marcel@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2004 by Marcel Gruenauer.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

