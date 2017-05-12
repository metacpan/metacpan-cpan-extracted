package HTML::ScriptLoader;

use 5.008008;
use strict;
use warnings;

require Exporter;
use AutoLoader qw(AUTOLOAD);
use Carp;
use URI::Escape;

=head1 NAME

HTML::ScriptLoader - Perl extension for loading scripts on a web page

=head1 SYNOPSIS

    use HTML::ScriptLoader;
    my $scripts = HTML::ScriptLoader->new(
        {
            'other-script'  => {
                'uri'           => 'http://example.com/other-script.js'
            },
            'myscript'      => {
                'uri'           => '/static/js/myscript.js',
                'deps'          => ['other-script'],
                'params'        => {
                    'apikey'        => 'very-secret',
                },
            },
        }
    );

    $scripts->add_script('myscript');

    $ttvars->{'javascripts'} = $scripts->scripts;

    # In your templates (TT)
    <head>
        [% FOREACH js IN javascripts %]
        <script type="text/javascript" src="[% js.url %]" />
        [% END %]
        <!-- ... -->
    </head>


=head1 DESCRIPTION

This package handles script loading with dependency support.

The available scripts can be setup in a configuration file and added on
runtime. When a script is needed, you call on L</add_script>, and the script
and all its dependencies will be loaded, in order of dependency.

Recursive dependencies are not allowed and will throw an exception.

=head2 EXPORT

None by default.

=cut

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use HTML::ScriptLoader ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

our $VERSION = '1.01';


=head1 METHODS

=head2 new(C<\%attrs>)

Constructor.

It will return the reference to a blessed object of this package.

The C<\%attrs> parameter should contain a HASHREF
with the scripts you want to use for your site.

=cut

sub new {
    my ( $class, $scripts ) = @_;
    $class      = ref $class || $class;
    $scripts    ||= {};

    my %self = (
        '_scripts'   => $scripts,
        '_loaded'    => [],
    );

    my $self = bless \%self, $class;
    return $self;
}

=head2 add_script(C<@scripts>)

This prepares a script, or a list of scripts, for use on a web page.
It will resolve all dependencies, ready for use in a template.

=cut

sub add_script {
    my ( $self, @scripts ) = @_;

    for my $script (@scripts) {
        next if $self->is_loaded($script);

        croak("No script named $script exists")
            unless $self->available->{$script};

        my @deps = $self->_find_dependencies($script);

        croak(
            "We do not allow recursive dependencies between scripts"
        ) if grep { $script eq $_ } @deps;

        # Add dependencies
        $self->add_script(@deps);

        # Add it to the loaded stack
        push @{ $self->{'_loaded'} }, $script;
    }
}

=head2 is_loaded(C<$script>)

This method checks if a script has already been loaded.

=cut

sub is_loaded {
    my ( $self, $script ) = @_;

    return unless $self->loaded;

    croak "Missing script parameter"
        unless $script;

    return 1 if grep { $script eq $_ } $self->loaded;
    return;
}

=head2 _find_dependencies(C<$script>)

This takes the name of a script as a parameter and looks up all dependencies
that this script depends on.

The list of dependencies is returned.

=cut

sub _find_dependencies {
    my ( $self, $script ) = @_;

    my $scriptconf  = $self->available->{$script};
    my @deps        = @{ $scriptconf->{'deps'} || [] };

    return @deps;
}

=head2 scripts

This method returns an ARRAYREF of all scripts that have been loaded.
It will add all the query parameters to the URI's.

=cut

sub scripts {
    my ( $self ) = @_;

    my @scripts = ();
    for my $scriptname ($self->loaded) {
        my $script  = $self->available->{$scriptname};

        $script->{'name'}   = $scriptname;
        my $url             = $script->{'uri'};
        my %params          = %{ $script->{'params'} || {} };

        my @params          = ();
        while (my ($key, $val) = each %params) {
            push @params, sprintf("%s=%s",
                uri_escape($key),
                uri_escape($val)
            );
        }

        my $strparams       = join '&', @params;

        $url = "$url?$strparams"
            if $strparams;

        $script->{'url'}    = $url;
        push @scripts, $script;
    }

    return \@scripts;
}

=head2 loaded

This is an accessor for an ARRAY of scripts that has been loaded and ready
for use on a web site, with all dependencies resolved.

=cut

sub loaded {
    my ( $self ) = @_;
    return @{ $self->{'_loaded'} };
}

=head2 available

This is an accessor for a HASHREF of scripts that is available for this object.
Dependencies have not been resolved.

=cut

sub available {
    my ( $self ) = @_;
    return $self->{'_scripts'};
}


=head1 AUTHOR

Knut-Olav Hoven, E<lt>knut-olav@hoven.wsE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by Knut-Olav Hoven

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut

1;
__END__
