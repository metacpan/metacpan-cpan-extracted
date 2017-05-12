package EWS::Calendar::Viewer;
BEGIN {
  $EWS::Calendar::Viewer::VERSION = '1.111982';
}

use strict;
use warnings FATAL => 'all';

use File::ShareDir ();
use Try::Tiny;
use MRO::Compat;
use Catalyst qw/
    ConfigLoader
    Static::Simple
/;

# skip s3krits from dumped data
sub dump_these {
    my $c = shift;
    my @variables = $c->next::method(@_);
    return grep { $_->[0] !~ m/^(?:Config|Stash)$/ } @variables;
}

__PACKAGE__->config({
    name => 'EWS::Calendar::Viewer',
    static => {
        include_path => [
            try {
                File::ShareDir::dist_dir('EWS-Calendar-Viewer')
            } catch {
                './share'
            }
        ],
    },
});

__PACKAGE__->setup;

1;


=pod

=head1 NAME

EWS::Calendar::Viewer - View Your MS Exchange Calendar as a Standalone Web App

=head1 VERSION

version 1.111982

=head1 SYNOPSIS

I recommend you use something like L<App::BundleDeps> to deploy this under a
fastcgi server environment. Configure the application like so:

 privacy_level = limited
 start_of_week = 1
 
 <Model::EWSClient>
     <args>
         server   = myserver.example.com
         username = oliver
         password = s3kr1t # or in EWS_PASS environment variable
     </args>
 </Model::EWSClient>

And then start the Catalyst application, perhaps using one of the bundled
server scripts.

=head1 CONFIGURATION

=head2 privacy_level

This can be set to C<public> to show only your free/busy status, C<limited> to
show the title of the event as well, or C<private> to show all details of the
event in a tooltip.

=head2 start_of_week

Set this to a number from 0 to 6 representing Sunday through to Saturday
respectively.

=head2 EWS Client

You'll need to set the server fully qualified domain name, and username for
the calendar's account. The password can be set in the file using the
C<password> option or via the environment variable C<EWS_PASS>.

If the Exchange server uses NTLM Negotiated Auth then also pass the following:

 <Model::EWSClient>
     <args>
         use_negotiated_auth = 1
     </args>
 </Model::EWSClient>

Obviously, this setting is in addition to the other C<args> mentioned above.
If you're unsure whether NTLM is required, try it without and if you get an
C<Error: Unauthorised> response then you probably need the setting.

=head1 QUICK START SCRIPT

This application brings with it a lightweight web server environment, so you
can get up and running quickly. First, install the module and its
dependencies.

Then create a configuration file as in the L</SYNOPSIS> section, above, and
save it in your current directory as C<ews_calendar_viewer_local.conf>.
Finally, run the C<ews_calendar_viewer_server.pl> script. It listens on port
3000 by default but you can change that (see C<--help>):

 $> EWS_PASS=s3kr1t ews_calendar_viewer_server.pl
 [info] EWS::Calendar::Viewer powered by Catalyst 5.80032
 You can connect to your server at http://localhost:3000

=head1 AUTHOR

Oliver Gorwits <oliver@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Oliver Gorwits.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

# ABSTRACT: View Your MS Exchange Calendar as a Standalone Web App

