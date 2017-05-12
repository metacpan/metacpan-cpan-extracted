package Maypole::Application;

use strict;
use warnings;

use UNIVERSAL::require;
use Maypole;
use Maypole::Config;

our $VERSION = '2.11';

sub import {
    shift; # not interested in this - we manipulate the caller's @ISA directly
    my @plugins = @_;
    my $caller = caller(0);
    
    my $frontend = 'Apache::MVC' if $ENV{MOD_PERL};
    
    $frontend = 'Maypole::HTTPD::Frontend' if $ENV{MAYPOLE_HTTPD};
    
    my $masonx;
    if ( grep { /^MasonX$/ } @plugins )
    {
        $masonx++;
        @plugins = grep { ! /^MasonX$/ } @plugins;
        $frontend = 'MasonX::Maypole';
    }
    
    $frontend ||= 'CGI::Maypole';
    
    $frontend->require or die "Loading $frontend frontend failed: $@";

    my $autosetup=0;
    my $autoinit=0;
    my @plugin_modules;

    foreach (@plugins) 
    {
        if    (/^\-Setup$/) { $autosetup++; }
        elsif (/^\-Init$/)  { $autoinit++ }
        elsif (/^\-Debug(\d*)$/) {
            my $d = $1 || 1;
            no strict 'refs';
            *{"$caller\::debug"} = sub { $d };
            warn "Debugging (level $d) enabled for $caller";
        }
        elsif (/^-.*$/) { warn "Unknown flag: $_" }
        else {
            my $plugin = "Maypole::Plugin::$_";
            if ($plugin->require) {
                push @plugin_modules, "Maypole::Plugin::$_";
                warn "Loaded plugin: $plugin for $caller"
                    if $caller->can('debug') && $caller->debug;
            } else {
                die qq(Loading plugin "$plugin" for $caller failed: )
                    . $UNIVERSAL::require::ERROR;
            }
        }
    }
    
    no strict 'refs';
    push @{"${caller}::ISA"}, @plugin_modules, $frontend;
    $caller->config(Maypole::Config->new);
    $caller->config->masonx({}) if $masonx;
    $caller->setup() if $autosetup;
    $caller->init() if $autosetup && $autoinit;
}

1;

=head1 NAME

Maypole::Application - Universal Maypole Frontend

=head1 SYNOPSIS

    use Maypole::Application;

    use Maypole::Application qw(Config::YAML);

    use Maypole::Application qw(-Debug Config::YAML -Setup);

    use Maypole::Application qw(Config::YAML Loader -Setup -Debug);

    use Maypole::Application qw(-Debug2 MasonX AutoUntaint);

=head1 DESCRIPTION

This is a universal frontend for mod_perl1, mod_perl2, HTML::Mason and CGI.

Automatically determines the appropriate frontend for your environment (unless
you want to use L<MasonX::Maypole>, in which case include C<MasonX> in the
arguments).

Loads plugins supplied in the C<use> statement. 

Responds to flags supplied in the C<use> statement. 

Initializes the application's configuration object. 

You can omit the Maypole::Plugin:: prefix from plugins. So
Maypole::Plugin::Config::YAML becomes Config::YAML.

    use Maypole::Application qw(Config::YAML);

You can also set special flags like -Setup, -Debug and -Init.

    use Maypole::Application qw(-Debug Config::YAML -Setup);

The position of plugins in the chain is important, because they are
loaded/executed in the same order they appear.

=head1 FRONTEND

Under mod_perl (1 or 2), selects L<Apache::MVC>. 

Otherwise, selects L<CGI::Maypole>.

If C<MasonX> is specified, sets L<MasonX::Maypole> as the frontend. This
currently also requires a mod_perl environment.

=head1 FLAGS

=over

=item -Setup

    use Maypole::Application qw(-Setup);

is equivalent to

    use Maypole::Application;
    MyApp->setup;

Note that no options are passed to C<setup()>. You must ensure that the
required model config parameters are set in C<MyApp-E<gt>config>. See
L<Maypole::Config> for more information.

=item -Init

    use Maypole::Application qw(-Setup -Init);
    
is equivalent to

    use Maypole::Application;
    MyApp->setup;
    MyApp->init;
    
Note that the C<-Setup> flag is required for the C<-Init> flag to work.

In persistent environments (e.g. C<mod_perl>), it is useful to call C<init> 
once in the parent server, rather than at the beginning of the first request
to each child server, in order to share the view code loaded during C<init>. 
Note that you must supply all the config data to your app before calling 
C<setup> and C<init>, probably by using one of the C<Maypole::Plugin::Config::*> 
plugins.

=item -Debug

    use Maypole::Application qw(-Debug);

is equivalent to

    use Maypole::Application;
    sub debug { 1 }

You can specify a higher debug level by saying C<-Debug2> etc. 

=back

=head1 AUTHOR

Sebastian Riedel, C<sri@oook.de>
Idea by Marcus Ramberg, C<marcus@thefeed.no>

=head1 LICENSE

You may distribute this code under the same terms as Perl itself.

=cut
