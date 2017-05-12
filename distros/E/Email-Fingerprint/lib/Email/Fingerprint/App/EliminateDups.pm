package Email::Fingerprint::App::EliminateDups;

use warnings;
use strict;

use Class::Std;

use Carp qw( croak );
use File::Basename;
use Getopt::Long;

use Email::Fingerprint;
use Email::Fingerprint::Cache;

=head1 NAME

Email::Fingerprint::App::EliminateDups - Implements eliminate-dups functionality

=head1 VERSION

Version 0.48

=cut

our $VERSION = '0.48';

=head1 SYNOPSIS

See the manpage for C<eliminate-dups>. This module is not intended to be
used except by that script.

=cut

# Attributes

my %dbname      : ATTR( :get<dbname> );                 # Fingerprint DB name
my %cache       : ATTR( :get<cache> );                  # Actual fingerprint DB

my %dump        : ATTR( :get<dump>,     :default<0> );  # Dump cache contents
my %help        : ATTR( :get<help>,     :default<0> );  # Print usage
my %no_check    : ATTR( :get<no_check>, :default<0> );  # Only purge
my %no_purge    : ATTR( :get<no_purge>, :default<0> );  # Only check
my %strict      : ATTR( :get<strict>,   :default<0> );  # Include body

=head1 METHODS

=head2 new

  $app = new Email::Fingerprint::App::EliminateDups;

Create a new object. Takes no options.

=head2 BUILD

Internal helper method, not called by external users.

=cut
sub BUILD {
    my ($self, $obj_ID, $arg_ref) = @_;

    $self->_init;
}

=head2 run

  $app->run(@ARGV);

Run the eliminate-dups application.

=cut

sub run {
    my $self = shift;

    $self->_process_options(@_);
    $self->open_cache;
    $self->dump_cache;              # No-op if --dump wasn't specified
    $self->check_fingerprint;       # No-op if --no-check option was specified
    $self->purge_cache;             # No-op if --no-purge option was specified
    $self->close_cache;

    # Success
    exit 0;
}

=head2 open_cache

Initialize, open and lock the cache.

=cut

sub open_cache {
    my $self   = shift;
    my $cache  = $self->get_cache;
    my $dbname = $self->get_dbname || '';

    return $cache if $cache;

    # Initialize the cache
    $cache    = new Email::Fingerprint::Cache({
        file     => $dbname,
    });

    # Validate
    if ( not $cache ) {
        $self->_exit_retry( "Couldn't initialize cache \"$dbname\"" );
    }

    # Lock it
    if ( not $cache->lock( block => 1 ) ) {
        $self->_exit_retry( "Couldn't lock \"$dbname\": $!" );
    }

    # Open it
    if ( not $cache->open ) {
        $cache->unlock;
        $self->_exit_retry( "Couldn't open \"$dbname\": $!" );
    }

    $cache{ ident $self } = $cache;
    return $cache;
}

=head2 close_cache

Close and unlock the cache.

=cut

sub close_cache {
    my $self  = shift;
    my $cache = delete $cache{ ident $self };

    if ($cache) {
        $cache->unlock;
        $cache->close;
    }

    1;
}

=head2 dump_cache

Conditionally dump the cache contents and exit.

=cut

sub dump_cache {
    my $self = shift;

    return unless $self->get_dump;
    return unless $self->get_cache;

    # Dump the contents of the hashfile in a human readable format
    $self->get_cache->dump;

    $self->close_cache;
    exit 0;
}

=head2 check_fingerprint

Conditionally check the fingerprint of the message on STDIN.

=cut

sub check_fingerprint {
    my $self = shift;

    return if $self->get_no_check;

    my $checksum =  new Email::Fingerprint({
        input           => \*STDIN,
        checksum        => "Digest::MD5",
        strict_checking => $self->get_strict,
    });

    my $fingerprint = $checksum->checksum;

    # If there's a match, suppress it with exit code 99.
    if (defined $self->get_cache->get_hash->{$fingerprint})
    {
        # Fingerprint matches. Tell qmail to stop current delivery.
        $self->close_cache;
        exit 99;
    }

    # Record the fingerprint
    $self->get_cache->get_hash->{$fingerprint} = time;
}

=head2 purge_cache

Purge the cache of old entries.

=cut

sub purge_cache {
    my $self = shift;
    
    return if $self->get_no_purge;

    $self->get_cache->purge;
}

=head2 _process_options

Process command-line options.

=cut

sub _process_options :PRIVATE {
    my ( $self, @args ) = @_;

    # Fool Getopt::Long. Sigh.
    local @ARGV = @args;

    $self->_init;

    $self->_die_usage if not GetOptions(
        "dump"      => \$dump{ident $self},
        "no-purge"  => \$no_purge{ident $self},
        "no-check"  => \$no_check{ident $self},
        "strict"    => \$strict{ident $self},
        "help"      => \$help{ident $self},
    );

    # Respond to calls for help
    $self->_die_usage if $self->get_help;

    # Set the filename. If omitted, a default is used.
    $dbname{ident $self} = shift @ARGV if @ARGV;
}

=head2 _init

Basic initializer. Called from C<BUILD> and also from
C<_process_options>.

=cut

sub _init :PRIVATE {
    my $self   = shift;
    my $obj_ID = ident $self;

    $dbname{$obj_ID}   = '.maildups';
    $self->close_cache; # A no-op if we don't have a cache yet

    $dump{$obj_ID}     = 0;
    $help{$obj_ID}     = 0;
    $no_purge{$obj_ID} = 0;
    $no_check{$obj_ID} = 0;
    $strict{$obj_ID}   = 0;
}

=head2 die_usage

Exit with a usage message.

=cut

sub _die_usage :PRIVATE {
    my $self     = shift;
    my $progname = basename $0;

    $self->_exit_retry(
         "usage:\t$progname [--strict] [--no-purge] [hashfile]\n"
       . "\t$progname [--dump] [hashfile]\n"
       . "\t$progname [--no-check] [hashfile]"
    );
}

=head2 _exit_retry

Exit with qmail's "temporary error" status code. This forces qmail to
abort delivery attempts and try again later.

=cut

sub _exit_retry :PRIVATE {
    my ( $self, $message ) = @_;

    warn "$message\n";
    exit 111;
}

=head1 AUTHOR

Len Budney, C<< <lbudney at pobox.com> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-email-fingerprint at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Email-Fingerprint>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Email::Fingerprint

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Email-Fingerprint>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Email-Fingerprint>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Email-Fingerprint>

=item * Search CPAN

L<http://search.cpan.org/dist/Email-Fingerprint>

=back

=head1 SEE ALSO

See B<Mail::Header> for options governing the parsing of email headers.

=head1 ACKNOWLEDGEMENTS

Email::Fingerprint is based on the C<eliminate_dups> script by Peter Samuel
and available at L<http://www.qmail.org/>.

=head1 COPYRIGHT & LICENSE

Copyright 2006-2011 Len Budney, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Email::Fingerprint
