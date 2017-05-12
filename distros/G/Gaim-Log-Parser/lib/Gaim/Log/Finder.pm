###########################################
package Gaim::Log::Finder;
###########################################
use strict;
use warnings;
use Log::Log4perl qw(:easy);
use File::Find ();

our $VERSION = "0.02";

###########################################
sub new {
###########################################
    my($class, @options) = @_;

    my ($home) = glob "~";

    my $start_dir;

    for (qw(.purple .gaim)) {
        my $dir = "$home/$_";

        if(-d $dir) {
            $start_dir = "$dir/logs";
            last;
        }
    }

    my $self = {
        start_dir => $start_dir,
        callback  => sub { 1 },
        @options,
    };

    return bless $self, $class;
}

###########################################
sub find {
###########################################
    my($self, $start_dir) = @_;

    $start_dir = $self->{start_dir} unless
        defined $start_dir;

    File::Find::find sub { $self->wanted() },
        $start_dir;
}

###########################################
sub wanted {
###########################################
    my($self) = @_;
    
    return if $File::Find::name =~ m#$self->{start_dir}/(.*?)/(.*?)/.system/#;
    my $path = $File::Find::name;

    my($protocol, $local_user, $remote_user, $file) =
            $path =~ m#$self->{start_dir}/(.*?)/(.*?)/(.*?)/(.*\.txt)$#;

    if(defined $file) {
        $self->{callback}->($self, 
            $File::Find::name,
            $protocol,
            $local_user,
            $remote_user,
            $file
        );
    }
}

1;

__END__

=head1 NAME

Gaim::Log::Finder - Find Gaim's Log Files

=head1 SYNOPSIS

    use Gaim::Log::Finder;

    my $finder = Gaim::Log::Finder->new(
        callback => sub { print "Found $_[1]\n"; }
    );

    $finder->find();

=head1 DESCRIPTION

Gaim::Log::Finder traverses through all known Gaim log file hierarchies
and calls back to the previously defined callback function every time
it finds a Gaim log file.

=head2 Methods

=over 4

=item C<my $finder = Gaim::Log::Finder->new(callback =E<gt> $coderef)>

The callback function that gets passed in as a code reference
will be called later for every log file found (see below).

The finder will start in the C<.gaim/logs> directory under the
current user's home directory. If it finds C<.purple/logs>, which is the
log file location for gaim > 2.0 logs, it will use that instead.
If, for some reason you want to start
at a different location, pass it in as C<start_dir>:

    my $finder = Gaim::Log::Finder->new(
        callback  => sub { print "Found $_[0]\n"; },
        start_dir => "/tmp",
    );

=item C<my $finder = $parser-E<gt>find()>

Starts the finder, and will call the previously defined callback function
every time it finds a Gaim log file. It will pass the following parameters
to the callback function:

    sub gaim_log_callback {
        my($self, $logfile, $protocol, $local_user, 
           $remote_user, $file) = @_;
        # ...
    }

C<$self> is an object reference to the finder itself. C<$logfile> is the 
full path to the logfile. C<$protocol> is the IM transport mechanism/provider 
used, this could be C<yahoo>, C<aim>, C<jabber> or similar. C<$local_user>
is the local user's userid. C<$local_user> is the user's id who's at the
other end of the conversation. C<$file> is the name of the text file.

=back

=head1 LEGALESE

Copyright 2007 by Mike Schilli, all rights reserved.
This program is free software, you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 AUTHOR

2007, Mike Schilli <cpan@perlmeister.com>
