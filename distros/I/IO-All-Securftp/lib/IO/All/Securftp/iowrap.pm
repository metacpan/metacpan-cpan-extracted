package IO::All::Securftp::iowrap;

use warnings;
use strict;

=head1 NAME

IO::All::Securftp::iowrap - provides I/O wrapper for better integration of Net::SFTP::Foreign into IO::All

=head1 DESCRIPTION

IO::All::Securftp::iowrap is the handler for IO::All for opened sftp connections for reading and writing.

=cut

use Carp qw(croak);
use Net::SFTP::Foreign;
use Scalar::Util qw(blessed);
use URI;

use namespace::clean;

our $VERSION = "0.001";

{package # ...
 URI::securftp;

 use parent "URI::ssh";
}

=head1 METHODS

=head2 new

Extracts user/port from URI, if any - and passes parsed URI to C<< Net::SFTP::Foreign->new >> together with optional specified C<new> hash in C<%options>:

  IO::All::Securftp::iowrap->new($self->name, {
    new => {
      timeout => ...,
    },
    get_content => {
      conversion => ...,
    },
    put_content => {
      atomic => 1,
    }
  });

For details regarding the options to new, get_content and put_content see L<Net::SFTP::Foreign>.

=cut

sub new
{
    @_ == 2 or @_ == 3 or croak('IO::All::Securftp::iowrap->new($name, \%options?)');
    my $class = shift;
    my $name = shift;
    my %options;
    @_ and %options = %{ shift @_ };
    my %obj;

    $obj{uri} = blessed $name ? $name : URI->new($name);
    $obj{options} = \%options;

    defined $obj{uri}->userinfo and $options{user} //= $obj{uri}->userinfo;
    defined $obj{uri}->_port and $options{port} //= $obj{uri}->_port;

    my %new_opts = ( $options{new} ? ( %{$options{new}}) : () );
    $obj{sftp} = Net::SFTP::Foreign->new($obj{uri}->host, %new_opts);

    bless \%obj, $class;
}

sub _fetch
{
    my $self = shift;
    my $fh;
    my %fetch_opts = ( $self->{options}->{get_content} ? ( %{$self->{options}->{get_content}}) : () );
    $self->{_cnt} = $self->{sftp}->get_content($self->{uri}->path, %fetch_opts);
    CORE::open $fh, "<", \$self->{_cnt};
    $self->{content} = $fh;
}

sub _preappend
{
    my $self = shift;
    my $fh;
    my %fetch_opts = ( $self->{options}->{get_content} ? ( %{$self->{options}->{get_content}}) : () );
    $self->{_cnt} = $self->{sftp}->get_content($self->{uri}->path, %fetch_opts);
    CORE::open $fh, ">>", \$self->{_cnt};
    $self->{dirty} = 1;
    $self->{content} = $fh;
}

sub _preput
{
    my $self = shift;
    my $fh;
    $self->{_cnt} = "";
    CORE::open $fh, ">", \$self->{_cnt};
    $self->{dirty} = 1;
    $self->{content} = $fh;
}

=head2 getline

Reads a single line from remote file

=cut

sub getline
{
    my $self = shift;
    $self->{content} or $self->_fetch;
    $self->{content}->getline;
}

=head2 getlines

Reads all lines from remote file

=cut

sub getlines
{
    my $self = shift;
    $self->{content} or $self->_fetch;
    $self->{content}->getlines;
}

=head2 print

Print given lines to remote file

=cut

sub print
{
    my $self = shift;
    $self->{content} or $self->_fetch;
    $self->{content}->print(@_);
}

=head2 close

Closes remote connection, flush buffers before when necessary

=cut

sub close
{
    my $self = shift;
    my %put_opts = ( $self->{options}->{put_content} ? ( %{$self->{options}->{put_content}}) : () );
    $self->{dirty} and $self->{sftp}->put_content($self->{_cnt}, $self->{uri}->path, %put_opts);
    delete @$self{qw(dirty sftp _cnt uri content)};
    return;
}

=head2 DESTROY

=cut

sub DESTROY
{
    $_[0]->close;
}

=head1 AUTHOR

Jens Rehsack, C<< <rehsack at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-IO-All-Securftp at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=IO-All-Securftp>.
I will be notified, and then you'll automatically be notified of progress
on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc IO::All::Securftp

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=IO-All-Securftp>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/IO-All-Securftp>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/IO-All-Securftp>

=item * Search CPAN

L<http://search.cpan.org/dist/IO-All-Securftp/>

=back

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

Copyright 2015 Jens Rehsack.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=head1 SEE ALSO

=cut

1; # end of IO::All::Securftp::iowrap
