package Jifty::Plugin::GoogleAnalytics;
use base qw/Jifty::Plugin/;

use warnings;
use strict;

=head1 NAME

Jifty::Plugin::GoogleAnalytics - Replace "</body>" by Google Analytics Javascript code dynamically.

=cut

our $VERSION = '0.01';
our $JS;

use Text::OutputFilter;

=head1 FUNCTIONS

=head2 init

=cut

sub init {
    my ($self, %arg) = @_;

    my $orig_out_method = \&Jifty::Dispatcher::render_template;
    $JS = $arg{javascript} || "";
    unless ($JS) {
        warn 'Google Analytics js code is null. Check Jifty::Plugin::GoogleAnalytics configuration.';
        return 1;
    }

    {
        no warnings qw/redefine/;
        *Jifty::Dispatcher::render_template = sub {
            unless (defined Jifty->web->request->argument('use_google_analytics')) {
                Jifty->web->request->argument(use_google_analytics=>1); # default
            }
            tie *STDOUT, "Text::OutputFilter", 0, *STDOUT, \&_replace;
            $orig_out_method->(@_);
            untie *STDOUT;
        };
        Jifty->log->info("Jifty::Dispatcher::render_template() was redefined by Jifty::Plugin::GoogleAnalytics.");
    }

    1;
}

sub _replace {
    if ($_[0] =~ m|</body>|o) {
        my $html   = Jifty->handler->apache->content_type =~ m/html/o;
        my $enable = Jifty->web->request->argument("use_google_analytics");
        if ($html and $enable) {
            $_[0] =~ s|</body>|$JS</body>|o;
        }
    }
    $_[0];
}

=head1 USAGE

Add the following to your site_config.yml

 framework:
   Plugins:
     - GoogleAnalytics: 
        javascript: |
          <script type="text/javascript">
              var gaJsHost = (("https:" == document.location.protocol) ? "https://ssl." : "http://www.");
              document.write(unescape("%3Cscript src='" + gaJsHost + "google-analytics.com/ga.js' type='text/javascript'%3E%3C/script%3E"));
          </script>
          <script type="text/javascript">
              var pageTracker = _gat._getTracker("UA-*******-*");
              pageTracker._initData();
              pageTracker._trackPageview();
          </script>

If you need disable it in some cases, then

    # in Mason template
    ...
    <%init>
    Jifty->web->request->argument( use_google_analytics => 0 );
    </%init>
    ...

    # in Template::Declare
    ...
    template "example" => page {
        set use_google_analytics => 0;
    };

    # in YourApp::Dispatcher (Mason template only)
    ...
    on qr{^/download} => [
        run => {
            set use_google_analytics => 0;
        },
    ];
    ...

=head1 SEE ALSO

L<Jifty>, L<Text::OutputFilter>

=head1 AUTHOR

bokutin, C<< <bokutin at cpan.org> >>

=head1 COPYRIGHT & LICENSE

Copyright 2008 bokutin, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Jifty::Plugin::GoogleAnalytics
