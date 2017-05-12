
package Launcher::Cascade::FileReader;

=head1 NAME

Launcher::Cascade::FileReader - a class to read a file or the output of a command, locally or through ssh.

=head1 SYNOPSIS

    use Launcher::Cascade::FileReader;

    my $f = new Launcher::Cascade::FileReader
	-path => q{date '+%H:%M:%S' |},
	-host => q{host.domain},
    ;
    my $fh = $f->open();
    while ( <$fh> ) {
	print; # what time is it over there?
    }
    close $fh;

=head1 DESCRIPTION

The purpose of this class is to provide a file handle that gives access to a
file or the output of a command. If a host() is provided, the file or the
command are fetched through ssh, otherwise, run locally. The class takes care
of escaping quote characters as appropriate.

=cut

use strict;
use warnings;

use base qw( Launcher::Cascade );

use Launcher::Cascade::ListOfStrings::Context;

=head2 Attributes

=over 4

=item B<path>

The path to the file to open. If the last character is a vertical bar (or
"pipe", ASCII 0x7c), path() will be considered a command and run. The standard
ouput will be available in the filehandle returned by method open().

=item B<host>

If set, the path() will be considered remote, i.e., the command actually run by
method open() will be a C<ssh host ...>. Either the content of the remote file
or the standard output of the remote command will be made available in the
filehandle returned by open().

=item B<user>

The remote user to login as. When omitted, ssh(1) will login with the same user
as the local user.

=item B<filehandle>

The filehandle as returned by method open().

=item B<context>

An array reference containing the line that matched the pattern given to method
search(), plus lines of context if either of context_after() or
context_before() are not null.

=item B<context_after>

=item B<context_before>

Determines the number of lines to include in context() after, respectively
before, a pattern has been matched. The number of lines in context() should be
context_before() + 1 + context_after(), unless the end of the file was reached
too soon to provide enough context after the match.

Both attributes default to 0, so the default context contains only one line,
the one that matched the pattern.

=back

=cut

Launcher::Cascade::make_accessors qw( path host user filehandle );
Launcher::Cascade::make_accessors_with_defaults
    context_before => 0,
    context_after  => 0,
;

sub _context_arguments {

    my $self = shift;

    my $header = '-' x 0;
    #$header .= ' Excerpt from ' . $self->path();
    #$header .= ' on host ' . $self->host() if $self->host();
    
    return (-string_before => $header);
}
sub context {

    my $self = shift;

    my $old = $self->{_context} ||= new Launcher::Cascade::ListOfStrings::Context
        -list => [],
        $self->_context_arguments(),
    ;
    if ( @_ ) {
        if ( UNIVERSAL::isa($_[0], 'Launcher::Cascade::ListOfStrings::Context') ) {
            $self->{_context} = $_[0];
        }
        else {
            $self->{_context} = new Launcher::Cascade::ListOfStrings::Context
                -list => $_[0],
                $self->_context_arguments(),
            ;
        }
    }
    return $old;
}

=head2 Methods

=over 4

=item B<open>

Opens the file or command specified by attribute path(), possible over ssh on
remote host(), and returns a filehandle make its content (for a file) or
standard output (for a command) available for reading.

=cut

sub open {

    my $self = shift;
    my $filename = $self->_prepare_command();

    open my $fh, $filename or die "Cannot read $filename: $!";
    $self->filehandle($fh);
    return $fh;
}

=item B<close>

Closes the filehandle.

=cut

sub close {

    my $self = shift;

    if ( ! CORE::close $self->filehandle(undef) ) {
        my $path = $self->path();
        my $cmd = $path;
        $cmd = '' unless $cmd =~ s/\s*\|$//;

        my $what = $self->host() ? 'ssh to host ' . $self->host()
                 : $cmd          ? "external command ($cmd)"
                 :                 "closing of file $path"
                 ;
        if ( $! ) {
            die "$what failed: $!";
        }
        else {
            die "$what returned status $?";
        }
   }
}

sub _remote_cat {

    my $self = shift;
    my $path = shift;
    return "cat $path";
}

sub _prepare_command {

    my $self = shift;

    my $path = $self->path();

    if ( $self->host() ) {
	$path =~ s/'/'\\''/g;
	if ( $path !~ s/\s*\|$// ) {
	    $path = $self->_remote_cat($path);
	}
	my $user = $self->user() || '';
	my $host = $self->host();
	$user .= '@' if $user;
	return "ssh $user$host '$path' |";
    }
    else {
	$path = "< $path" unless $path =~ /\|$/;
	return $path;
    }
}

=item B<search> I<PATTERN>, I<PATTERN>, ...

Search the filehandle for I<PATTERN>s and returns the index of the one that
matched (starting with 0), or C<-1> if the end of file was reached before any
pattern could be matched.

I<PATTERN>s should be regular expressions, possibly pre-compiled with the
C<qr//> operator.

After a search(), the context() attribute contains an arrayref containing the
line that matched, plus a number of context lines before and after the match,
as defined by the context_after() and context_before() attributes.

The filehandle is closed after the search().

=cut

sub search {

    my $self = shift;

    my @pattern = @_;

    # a buffer to contain the context before the match
    my @fifo = ();
    my $fifo_size = $self->context_before() + 1;

    my $result = -1;

    # Let's open the file if not yet done
    my $fh = $self->filehandle() || $self->open();
    LINE: while ( <$fh> ) {
	# Store the line in the context buffer
	push @fifo, $_;
	shift @fifo if @fifo > $fifo_size;

	# try all patterns
	for ( my $i = 0 ; $i < @pattern ; $i++ ) {
	    if ( /$pattern[$i]/ ) {
		$result = $i;
		last LINE;
	    }
	}
    }

    # Now fetch the context after the match
    $fifo_size += $self->context_after();
    while ( defined($_ = <$fh>) && @fifo < $fifo_size ) {
	push @fifo, $_;
    }

    $self->context(\@fifo);
    $self->close();
    return $result;
}

=back

=head1 BUGS AND CAVEATS

=over 4

=item *

ssh(1) must be in one of directories listed in the C<PATH> environment variable.

=item *

there is nothing provided for non-interactive logging. The DSA or RSA key pairs
should be properly generated and ssh configured to avoid interactive login.

=back

=head1 SEE ALSO

L<Launcher::Cascade>.

=head1 AUTHOR

Cédric Bouvier C<< <cbouvi@cpan.org> >>

=head1 COPYRIGHT & LICENSE

Copyright (C) 2006 Cédric Bouvier, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

1; # end of Launcher::Cascade::FileReader
