package File::Tail::Scribe;

use Log::Dispatch::Scribe;
use Moose;
extends "File::Tail::Dir";

our $VERSION = '0.13';

has scribe_options => (
    is => 'ro',
    isa => 'HashRef',
    default => sub { {} },
    );

has 'msg_filter' => (
    is => 'rw', 
    isa => 'CodeRef', 
    default => sub { \&_default_msg_filter },
    );

has 'default_level' => (
    is => 'rw',
    isa => 'Str',
    default => 'info',
    );

has '_log' => (
    is => 'ro',
    isa => 'Log::Dispatch::Scribe',
    lazy_build => 1,
    handles => [ qw/ log log_message /],
    );

sub _build__log {
    my $self = shift;

    return Log::Dispatch::Scribe->new(%{$self->scribe_options});
}

sub process {
    my ($self, $filename, $lines) = @_;
    
    my $filter = $self->msg_filter;
    for my $line (@$lines) {
	my ($level, $category, $message) = $filter->($self, $filename, $line);
	$self->log( message  => $message, 
		    level    => $level,
		    category => $category,
	    ) if $message;
    }
}

sub _default_msg_filter {
    my $self = shift;
    my $filename = shift;
    my $line = shift;

    $filename =~ s{^.*/}{}; # remove leading dirs
    $filename =~ s{\.[^.]*$}{}; # remove extension

    return ($self->default_level, $filename || 'default', $line);
}

no Moose;

__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME

File::Tail::Scribe - Monitor and send the tail of files to a Scribe logging system.


=head1 SYNOPSIS

  use File::Tail::Scribe;

  my $log = File::Tail::Scribe->new(
    directories => $args{dirs},
    msg_filter => sub {
        my ($self, $filename, $line) = @_;
        return ('info', 'httpd', "$filename\t$line");
        },
    );

  $log->watch_files();

=head1 DESCRIPTION

Basically this module connects L<File::Tail::Dir> to L<Log::Dispatch::Scribe>.

It monitors files in a given directory (or set of directories), such as Apache
log files in /var/log/httpd, and as the log files are written to, takes the
changes and sends them to a running instance of the Scribe logging system.

=head1 PREREQUISITES

The Scribe and Thrift Perl modules from their respective source distributions
are required and not available as CPAN dependencies.  Further information is
available here:
<http://notes.jschutz.net/109/perl/perl-client-for-facebooks-scribe-logging-software>

=head1 CONSTRUCTOR

=head2 new

  $tailer = File::Tail::Scribe->new(%options);

Creates a new instance.  Options are:

=over 4

=item * directories, filter, exclude, follow_symlinks, sleep_interval, statefilename, no_init, max_age

See the equivalent options in L<File::Tail::Dir>:
L<File::Tail::Dir/directories>, L<File::Tail::Dir/filter>,
L<File::Tail::Dir/exclude>, L<File::Tail::Dir/follow_symlinks>,
L<File::Tail::Dir/sleep_interval>, L<File::Tail::Dir/statefilename>,
L<File::Tail::Dir/no_init>, L<File::Tail::Dir/max_age>.  

=item * scribe_options 

This is a hash containing all of the options to pass to <Log::Dispatch::Scribe/new>.

=item * msg_filter

An optional coderef that can be used to preprocess messages before they are sent
to Scribe.  The code is passed ($self, $filename, $line), i.e. the
File::Tail::Scribe instance, the filename of the file that changed, and the line
of text that was added.  It must return ($level, $category, $message), i.e. the
log level (info, debug etc), the Scribe category, and the log line that will be
sent to Scribe.  An example:

  msg_filter => sub {
    my $self = shift;
    my $filename = shift;
    my $line = shift;
    $filename =~ s{^.*/}{};		      # remove leading dirs
    $filename =~ s{\.[^.]*$}{};               # remove extension
    $filename ||= 'default';                  # in case everything gets removed

    return ('info', 'httpd', "$filename\t$line");
  };


If no msg_filter is provided, the log level is given by default_level, the
category is the filename after removing leading paths and filename extensions,
and the message is the log line as given.

=item * default_level

Default logging level.  May be set to any valid L<Log::Dispatch> level (debug,
info, notice, warning, error, critical, alert, emergency).  Defaults to 'info'.

=back

=head1 METHODS

B<File::Tail::Scribe> provides the same methods as L<File::Tail::Dir>, plus the following:

=over 4

=item * msg_filter

=item * default_level

Set/get the L</msg_filter> and L</default_level> attributes as described above.

=back

=head1 SEE ALSO

=over 4

=item * L<tail_to_scribe.pl>, a program that uses this module

=item * L<http://notes.jschutz.net/109/perl/perl-client-for-facebooks-scribe-logging-software>

=item * L<http://github.com/facebook/scribe/>

=item * L<Log::Dispatch::Scribe>

=back

=head1 AUTHOR

Jon Schutz, C<< <jon at jschutz.net> >>  L<http://notes.jschutz.net>

=head1 BUGS

Please report any bugs or feature requests to C<bug-file-tail-scribe at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=File-Tail-Scribe>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc File::Tail::Scribe


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=File-Tail-Scribe>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/File-Tail-Scribe>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/File-Tail-Scribe>

=item * Search CPAN

L<http://search.cpan.org/dist/File-Tail-Scribe/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2010 Jon Schutz, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

