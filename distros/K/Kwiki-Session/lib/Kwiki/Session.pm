package Kwiki::Session;
use Kwiki::Plugin -Base;
use CGI::Session;

our $VERSION = '0.01';

const class_id => 'session';
const class_title => 'Session';

field session => -init => '$self->load_session()';

sub load {
    $self->session
}

sub load_session {
    my $jar     = $self->hub->cookie->read("Session");
    my $session = CGI::Session->new(undef, $jar->{id} || undef,
				    {Directory=>$self->plugin_directory});
    $self->hub->cookie->write("Session", { id => $session->id() } );
    return $session;
}

__END__

=head1 NAME

  Kwiki::Session - Session support in your Kwiki plugin

=head1 SYNOPSIS

    # Install Kwiki::Session as a plugin
    > kwiki -add Kwiki::Sesssion

    # Return a CGI::Session object
    my $session = $self->hub->session->load;

=head1 DESCRIPTION


This class help out when a Kwiki plugin writer wants session support.  It has
only one method called "load", which will automatically recover the correct
session id, and create one if necessary. "load" method returns a
C<CGI::Session> object, so please read the documentation in CGI::Session in
order to use this object.

Please that, this module itself is also a kwiki plugin, and has to be installed
to your kwiki site if you want your own module to use it very easily. If you
put "Kwiki::Session" in your "plugins" file, you can just use this line
to retrieve your session:

    my $session = $self->hub->session->load;

Otherwise, it would take like this long to load it:

    sub init {
        $self->hub->config->add_field('session' => 'Kwiki::Session');
    }

For simple purpose, just put "Kwiki::Session" into your "plugins" file. It
doesn't provide any extra actions or widgets or any templates, just convienent
access programming interface.

=head1 SEE ALSO

L<CGI::Session>

=head1 COPYRIGHT

Copyright 2005 by Kang-min Liu <gugod@gugod.org>.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

See <http://www.perl.com/perl/misc/Artistic.html>

=cut

