package MasonX::Maypole::Application;

use strict;
use warnings;
use UNIVERSAL::require;
use Maypole;
use Maypole::Config;

our @ISA;
our $VERSION = '2.09';

sub import {
    my ( $class, @plugins ) = @_;
    my $caller = caller(0);
    
    my $frontend = 'Apache::MVC' if $ENV{MOD_PERL};
    
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
    my @plugin_modules;
    {
        foreach (@plugins) {
            if    (/^\-Setup$/) { $autosetup++; }
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
    }
    no strict 'refs';
    push @{"${caller}::ISA"}, @plugin_modules, $frontend;
    $caller->config(Maypole::Config->new);
    $caller->config->masonx({}) if $masonx;
    $caller->setup() if $autosetup;
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

You can omit the Maypole::Plugin:: prefix from plugins.
So Maypole::Plugin::Config::YAML becomes Config::YAML.

    use Maypole::Application qw(Config::YAML);

You can also set special flags like -Setup and -Debug.

    use Maypole::Application qw(-Debug Config::YAML -Setup);

The position of plugins and flags in the chain is important,
because they are loaded/executed in the same order they appear.

=head2 -Setup

    use Maypole::Application qw(-Setup);

is equivalent to

    use Maypole::Application;
    MyApp->setup;

Note that no options are passed to C<setup()>. You must ensure that the
required model config parameters are set in C<MyApp-E<gt>config>. See
L<Maypole::Config> for more information.

=head2 -Debug

    use Maypole::Application qw(-Debug);

is equivalent to

    use Maypole::Application;
    sub debug { 1 }

You can specify a higher debug level by saying C<-Debug2> etc. 

=head1 AUTHOR

Sebastian Riedel, C<sri@oook.de>
Idea by Marcus Ramberg, C<marcus@thefeed.no>

=head1 LICENSE

You may distribute this code under the same terms as Perl itself.

=cut
