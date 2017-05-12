package FileUpload::Filename;
use strict;
use warnings;

use Carp qw(carp croak);
use HTTP::BrowserDetect;
use File::Basename ();
use List::Util qw(first);

BEGIN {
    if (!defined &DEBUG ) {
        eval "sub DEBUG { 0 }";
    }
    if (!defined &VERBOSE ) {
        eval "sub VERBOSE { 1 }";
    }
};

our $VERSION = '0.02';


my $BROWSER_TO_BASENAME = {
    windows => 'MSWin32',
    mac     => 'MacOS',
    os2     => 'os2',
    unix    => 'unix',
    vms     => 'VMS',
    amiga   => 'AmigaOS',
};


sub name {
    my $class = shift;
    my $args  = shift;

    my $filename = exists $args->{'filename'} ? $args->{'filename'}
                 : croak 'Must provide a file name'
                 ;
    my $agent
        = exists $args->{'agent'}        ? $args->{'agent'}                   :
          exists $ENV{'HTTP_USER_AGENT'} ? $ENV{'HTTP_USER_AGENT'}            :
                                           croak "Can't get a UA to work with";

    my $browser = HTTP::BrowserDetect->new($agent);

    my ($os) = first { $browser->$_ } keys %{ $BROWSER_TO_BASENAME };

    unless ($os) {
        carp "Can't determine OS for given User Agent, defaulting to Unix\n"
            if VERBOSE;
        $os = 'unix';
    }

    if ( DEBUG ) {
        print "DEBUG => Agent: $agent\n" if $agent;
        print "DEBUG => OS: $os\n"       if $os;
    };

    File::Basename::fileparse_set_fstype( $BROWSER_TO_BASENAME->{$os} );

    my $name = File::Basename::basename($filename);
    $name =~ tr/a-zA-Z0-9.&+-/_/cs;

    return $name;
}




1;


__END__

=head1 NAME

FileUpload::Filename - Return the name of an uploaded file

=head1 SYNOPSIS

my $filename = FileUpload::Filename->name({ filename => $file });

print $filename;

=head1 DESCRIPTION

As you can read on L<CGI>, some browsers, when uploading a file, return the
path to the file, using the path conventions of their OS. This could be
annoying if you want to use the same name.

This module makes use of L<HTTP::BrowserDetect> to know which OS the
client is running in order to set the right FS type for L<File::Basename>.

It also tries to normalize the filename by substituting spaces, colons, and
all this usual stuff, with underscores.

E.g.:

 C:\My Music\Cool Artist - Great Song.mp3 -> Cool_Artist_-_Great_Song.mp3

=head1 METHODS

=head2 name

 my $name = FileUpload::Filename->name({
    filename  => $cgi->param('uploaded_file'),  # Required
    agent     => $ENV{'HTTP_USER_AGENT'},       # Optional
 });

=head1 DIAGNOSTICS

=head2 Must provide a file name

You have called the method without providing the required parameter. See
L</name>.

=head2 Can't get a UA to work with

You haven't provided a UA, or you don't have a HTTP_USER_AGENT environment
variable.

=head2 Can't determine OS for given User Agent, defaulting to Unix

This is a warning message that informs that it will use the Unix file
conventions to try to get a clean file name.

This happens if the L<HTTP::BrowserDetect> fails to identify the users OS.

=head1 NOTES

=head2 VERBOSE - Turn off warning messages

Just put the following before calling this module.

 sub FileUpload::Filename::VERBOSE { 0 };

Example:

 sub FileUpload::Filename::VERBOSE { 0 };
 use FileUpload::Filename;

=head2 DEBUG - Turn on debugging messages

Just put the following before calling this module.

 sub FileUpload::Filename::DEBUG { 1 };

Example:

 sub FileUpload::Filename::DEBUG { 1 };
 use FileUpload::Filename;

=head1 AUTHOR

Florian Merges E<lt>fmerges@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Florian Merges

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.7 or,
at your option, any later version of Perl 5 you may have available.

=cut
