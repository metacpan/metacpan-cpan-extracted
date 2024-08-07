package Git::Repository::Log;
$Git::Repository::Log::VERSION = '1.314';
use strict;
use warnings;
use 5.006;

# a few simple accessors
for my $attr (
    qw(
    commit diff_from tree
    author author_name author_email
    committer committer_name committer_email
    author_localtime author_tz author_gmtime
    committer_localtime committer_tz committer_gmtime
    raw_message message subject body
    gpgsig
    extra
    )
    )
{
    no strict 'refs';
    *$attr = sub { return $_[0]{$attr} };
}
for my $attr (qw( parent mergetag )) {
    no strict 'refs';
    *$attr = sub { return @{ $_[0]{$attr} || [] } };
}

sub new {
    my ( $class, @args ) = @_;
    my $self = bless { parent => [] }, $class;

    # pick up key/values from the list
    while ( my ( $key, $value ) = splice @args, 0, 2 ) {
        if ( $key =~ /^(?:parent|mergetag)$/ ) {
            push @{ $self->{$key} }, $value;
        }
        else {
            $self->{$key} = $value;
        }
    }

    # special case
    ($self->{commit}, $self->{diff_from}) = $self->{commit} =~ /^(\S+)(?: \(from (\S+)\))?/;

    # compute other keys
    $self->{raw_message} = $self->{message};
    $self->{message} =~ s/^    //gm;
    @{$self}{qw( subject body )}
        = ( split( /\n/m, $self->{message}, 2 ), '', '' );
    $self->{body} =~ s/\A\s//gm;

    # author and committer details
    for my $who (qw( author committer )) {
        $self->{$who} =~ /^(.*) <(.*)> (.*) (([-+])(..)(..))$/;
        my @keys = ( "${who}_name", "${who}_email", "${who}_gmtime",
            "${who}_tz" );
        @{$self}{@keys} = ( $1, $2, $3, $4 );
        $self->{"${who}_localtime"} = $self->{"${who}_gmtime"}
            + ( $5 eq '-' ? -1 : 1 ) * ( $6 * 3600 + $7 * 60 );
    }

    return $self;
}

1;

__END__

=pod

=head1 NAME

Git::Repository::Log - Class representing git log data

=head1 SYNOPSIS

    # load the Log plugin
    use Git::Repository 'Log';

    # get the log for last commit
    my ($log) = Git::Repository->log( '-1' );

    # get the author's email
    print my $email = $log->author_email;

=head1 DESCRIPTION

C<Git::Repository::Log> is a class whose instances represent
log items from a B<git log> stream.

=head1 CONSTRUCTOR

This method shouldn't be used directly. L<Git::Repository::Log::Iterator>
should be the preferred way to create C<Git::Repository::Log> objects.

=head2 new

Create a new C<Git::Repository::Log> instance, using the list of key/values
passed as parameters. The supported keys are (from the output of
C<git log --pretty=raw>):

=over 4

=item commit

The commit id (ignoring the extra information added by I<--decorate>).

=item tree

The tree id.

=item parent

The parent list, separated by spaces.

=item author

The author information.

=item committer

The committer information.

=item message

The log message (including the 4-space indent normally output by B<git log>).

=item gpgsig

The commit signature.

=item mergetag

The mergetag information.

=item diff_from

The commit from which the diff was taken.

This is the extra C<from> information on the commit header that is
added by B<git> when the log contains a diff (using the C<-p> or
C<--name-status> option). In this case, C<git log> may show the same
commit several times.

=item extra

Any extra text that might be added by extra options passed to B<git log>
(e.g. C<-p> or C<--name-status>).

=back

Note that since C<git tag --pretty=raw> does not provide the C<encoding>
header (and provides the message properly decoded), this information
will not be available via L<Git::Repository::Plugin::Log>.

=head1 ACCESSORS

The following accessors methods are recognized. They all return scalars,
except for C<parent()>, which returns a list.

=head2 Commit information

=over 4

=item commit

=item tree

=item parent

=back

=head2 Author and committer information

=over 4

=item author

=item committer

The original author/committer line

=item author_name

=item committer_name

=item author_email

=item committer_email

=back

=head2 Date information

=over 4

=item author_gmtime

=item committer_gmtime

=item author_localtime

=item committer_localtime

=item author_tz

=item committer_tz

=back

=head2 Log information

=over 4

=item raw_message

The log message with the 4-space indent output by B<git log>.

=item message

The unindented version of the log message.

=item subject

=item body

=back

=head2 Signature-related information

=over 4

=item gpgsig

=item mergetag

=back

=head2 Extra information

=over 4

=item extra

=back

=head1 COPYRIGHT

Copyright 2010-2016 Philippe Bruhat (BooK), all rights reserved.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
