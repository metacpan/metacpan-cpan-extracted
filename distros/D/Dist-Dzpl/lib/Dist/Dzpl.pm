package Dist::Dzpl;
BEGIN {
  $Dist::Dzpl::VERSION = '0.0020';
}
# ABSTRACT: An alternative configuration format (.pl)  and invoker for Dist::Zilla 

use strict;
use warnings;


# You can actually interact with Dist::Zilla from within your configuration .pl, allowing you to easily tweak your Zilla specification on the fly

use Moose;

use Dist::Dzpl::Parser;

use Dist::Zilla::Chrome::Term;
use Dist::Zilla::Util;
use Class::MOP;
use Moose::Autobox;
use Carp;

has zilla => qw/ is ro required 1 isa Dist::Zilla /;

sub from_file {
    my $self = shift;
    my $file = shift;
    $file = './' unless defined $file;

    my $source;
    if ( -f $file ) {
        $source = $file;
    }
    elsif ( -d $file ) {
        my @try = qw/ dzpl dz.pl dist.pl /;
        for ( map { "$file/$_" } @try ) {
            -e $_ and ( $source = $_ ) and last;
        }
        croak "Could not find ", join( ' or ', map { "\"$_\"" } @try ), " in $file" unless $source;
    }
    else {
        croak "Missing file";
    }
    croak "Could not read \"$source\"" unless -r $source;

    my $dzpl = $self->_from_file_sandbox( $source );
    die "Error while loading $source: $@" if $@;
    return $dzpl;
}

sub _from_file_sandbox {
    my $self = shift;
    my $file = shift;

    my $package = $file;
    $package =~ s/([^A-Za-z0-9_])/sprintf("_%2x", unpack("C", $1))/eg;

    return eval sprintf <<'_END_', $package;
package Dist::Dzpl::Sandbox::%s;
{
    require Dzpl;
    do $file;
    Dzpl->dzpl_from_package( __PACKAGE__ ) or die $@;
}
_END_
}

sub from_arguments {
    my $self = shift;
    my $zilla = Dist::Dzpl::Parser->parse( @_ );
    return __PACKAGE__->new( zilla => $zilla );
}

sub run {
    my $self = shift;
    my @arguments = @_;

    my $zilla = $self->zilla;
    # TODO This should only be run once...
    $zilla->_setup_default_plugins;

    return unless @arguments;

    my $do = shift @arguments;

    if ( $do eq 'dzil' ) {
        require Dist::Zilla::App;
        my $app = Dist::Zilla::App->new;
        $app->{__chrome__} = $zilla->chrome;
        $app->{__PACKAGE__}{zilla} = $zilla; # Cover case 1...
        $app->{'Dist::Zilla::App'}{zilla} = $zilla; # ...and case 2
        {
            local @ARGV = @arguments;
            $app->run;
        }
    }
    else {
        die "Dist::Zilla cannot do \"$do\"" unless $zilla->can( $do );
        warn "Dropping arguments [@arguments]" if @arguments;
        return $zilla->$do;
    }
}

sub _include_plugin_bundle {
    my $self = shift;
    my $name = shift;
    my $package = shift;
    my $payload = shift;
    my $filter = shift;

    Class::MOP::load_class( $package );

    my @bundle = $package->bundle_config({ 
        name => $name,
        zilla => $self->zilla,
        payload => $payload,
    });

    for my $plugin ( @bundle ) {
        my ( $name, $package, $payload ) = @$plugin;
        next if $filter && $package =~ $filter;
        $self->_include_plugin( $name, $package, $payload );
    }
}

sub _include_plugin {
    my $self = shift;
    my $name = shift;
    my $package = shift;
    my $payload = shift;

    Class::MOP::load_class( $package );

    my @arguments;
    if ( ref $payload eq 'HASH' ) {
        push @arguments, payload => $payload;
    }
    elsif ( ref $payload eq 'ARRAY' ) {
        push @arguments, @$payload;
    }
    elsif ( defined $payload ) {
        die "Invalid payload ($payload)";
    }

    $self->zilla->plugins->push( $package->new( 
        plugin_name => $name,
        zilla => $self->zilla,
        @arguments,
    ) );
}

sub plugin {
    my $self = shift;
    
    while( @_ ) {
        my $name_package = shift;
        my ($package, $name) = $name_package =~ m{\A\s*(?:([^/\s]+)\s*/\s*)?(\S+)\z};
        $package = $name unless defined $package and length $package;
        $package = Dist::Zilla::Util->expand_config_package_name( $package );
        Class::MOP::load_class( $package );
        my $includer = '_include_plugin';
        my $payload = {};
        $payload = shift if ref $_[0] eq 'HASH' || ref $_[0] eq 'ARRAY';
        my @arguments = ( $name, $package, $payload );
        if ( $package->does( 'Dist::Zilla::Role::PluginBundle' ) ) {
            $includer = '_include_plugin_bundle';
            my $filter = shift if ref $_[0] eq 'Regexp';
            push @arguments, $filter;
        }
        $self->$includer( @arguments );
    }

}

sub prune {
    my $self = shift;
    my $pruner = shift;

    require Dist::Dzpl::Plugin::Prune;
    $self->zilla->plugins->push( Dist::Dzpl::Plugin::Prune->new(
        plugin_name => 'Dist::Dzpl::Plugin::Prune',
        payload => {},
        zilla => $self->zilla,
        pruner => $pruner,
    ) );
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;

__END__
=pod

=head1 NAME

Dist::Dzpl - An alternative configuration format (.pl)  and invoker for Dist::Zilla 

=head1 VERSION

version 0.0020

=head1 SYNOPSIS

Below is an example file that would exist in your distribution root, called C<dist.pl> or C<dzpl>:

    #!/usr/bin/env perl
    use Dzpl
        name => 'Acme-Xyzzy',
        version => '0.0001',
        author => 'Ja P. Hacker <japh@example.com>',
        license => 'Perl5',
        copyright => 'Ja P. Hacker', # Will automaticaly fill in the current year

        # Declare prerequisites for runtime and testing (building)
        # Alternatively, you can specify 'recommend' or 'prefer'
        require => q/
            Moose

            [Test]
            Test::Most
        /;
    ;

    # Declare some plugins to use. The regular expression following
    # the @Basic bundle is a filter excluding Dist::Zilla::Plugin::Readme
    plugin
        '@Basic' => qr/Readme$/,
        'PodWeaver',
        'PkgVersion',
        'ReadmeFromPod',
        '=Dist::Dzpl::Plugin::DynamicManifest',
        '=Dist::Dzpl::Plugin::CopyReadmeFromBuild',
    ;

    run;

Then, from the commandline:

    dzpl build      # Build the distribution via $zilla->build
    dzpl dzil help  # The usual Dist::Dzil::App help message

=head1 DESCRIPTION

Dist::Dzpl is a wrapper around Dist::Zilla, allowing an alternative, flexible configuration mechanism. Instead of describing your distribution using an .ini file, you can use a Perl .pl script

Your configuation file can be named C<dzpl>, C<dz.pl>, or C<dist.pl>, and will be picked in that order

Dist::Dzpl is dz*P*l is to .pl as Dist::Zilla is dz*I*l is to .ini

=head1 SEE ALSO

L<Dist::Zilla>

=head1 AUTHOR

  Robert Krimen <robertkrimen@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Robert Krimen.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

