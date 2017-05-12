# post.al -- Methods to post articles.  -*- perl -*-
# $Id: post.al,v 0.1 1998/02/19 00:32:49 eagle Exp $
#
# Copyright 1998 by Russ Allbery <rra@stanford.edu>
#
# This program is free software; you may redistribute it and/or modify it
# under the same terms as Perl itself.  This is a News::Gateway module and
# requires News::Gateway to be used.

package News::Gateway;

############################################################################
# Methods
############################################################################

# Post the message through NNTP.  Returns undef if posting succeeds and the
# error message if it fails.
sub post {
    my ($self, $server) = @_;
    
    # If a server is provided and isn't a Net::NNTP connection, open one.
    if ($server && !ref $server) {
        eval { require Net::NNTP };
        if ($@) { $self->error ("Unable to load Net::NNTP: $@") }
        $server = Net::NNTP->new ($server);
        unless ($server) { return "Unable to connect to server $server" }
    }

    # Actually do the POST and return any resulting error messages.
    eval { $$self{article}->post () };
    if ($@) {
        my $error = $@;
        chomp $error;
        return $error;
    } else {
        return undef;
    }
}

# Post the message through IHAVE.  We take a Net::NNTP connection or a
# machine name or IP address as an optional argument and pass an open
# Net::NNTP connection into News::Article::ihave() if one is provided.
# Returns undef on success or the error message on failure.  Note that the
# article must already have a Path and Message-ID to use this posting
# method.
sub post_ihave {
    my ($self, $server) = @_;

    # If a server is provided and isn't a Net::NNTP connection, open one.
    if ($server && !ref $server) {
        eval { require Net::NNTP };
        if ($@) { $self->error ("Unable to load Net::NNTP: $@") }
        $server = Net::NNTP->new ($server);
        unless ($server) { return "Unable to connect to server $server" }
    }

    # Actually do the IHAVE and return any resulting error messages.
    eval { $$self{article}->ihave ($server) };
    if ($@) {
        my $error = $@;
        chomp $error;
        return $error;
    } else {
        return undef;
    }
}

# Post the message through a program, returning undef on success and the
# output of the program on failure.
sub post_program {
    my ($self, @program) = @_;

    # Load in the modules we require to do this and then try to run the
    # program we were told to use.
    eval { require IPC::Open3 };
    if ($@) { $self->error ("Unable to load IPC::Open3: $@") }
    eval { require FileHandle };
    if ($@) { $self->error ("Unable to load FileHandle: $@") }
    my $input = new FileHandle;
    my $output = new FileHandle;
    eval { IPC::Open3::open3 ($input, $output, $output, @program) };
    if ($@) { return "Cannot execute @program: $!\n" }

    # Okay, that was successful.  Feed the post to the program.
    $$self{article}->write ($input);
    close $input;

    # Now check our error status and our output.
    if ($? != 0) {
        my @error = <$output>;
        push (@error, "@program exited with status $?\n");
        return (wantarray ? @error : join ('', @error));
    } else {
        return undef;
    }
}

1;
