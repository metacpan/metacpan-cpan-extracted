## no critic (NamingConventions::Capitalization)
## no critic (ControlStructures::ProhibitPostfixControls)
## no critic (InputOutput::RequireCheckedSyscalls)
package Dist::Zilla::App::Command::policies;

use strict;
use warnings;
use 5.010;
use feature qw( say );

# ABSTRACT: Create project policy files

our $VERSION = '0.001';

use Carp    qw( carp croak );
use English qw( -no_match_vars );    # Avoids regex performance
                                     # penalty in perl 5.18 and
                                     # earlier
use Module::Load;

use Dist::Zilla::App -command;
use List::Util qw( first );
use Path::Tiny qw( path );

use Software::Policies ();

sub abstract { return 'Create software policy files' }    ## no critic (NamingConventions::ProhibitAmbiguousNames)

sub usage_desc { return 'dzil policies [--class] [--version] [--format] [--dir] [--filename] [<policy>]' }

sub validate_args {
    my ( $self, $opt, $arg ) = @_;

    my ( $policy, @extra ) = @{$arg};

    croak( ( __PACKAGE__ =~ m/::(.+)$/msx )[0] . ' accepts two arguments, ignoring ' . join q{,}, @extra )
      if @extra;

    return;
}

sub opt_spec {
    return (
        [ 'filepath=s'      => 'optional: filepath of the policy file' ],
        [ 'class=s'         => 'class of policy' ],
        [ 'class-version=i' => 'version of policy' ],
        [ 'format=s'        => 'format, e.g. markdown' ],
        [ 'dir=s'           => 'dir for policy file' ],
        [ 'filename=s'      => 'filename of policy file' ],
        [ 'attributes=s'    => 'additional attributes to the policy, key-value pairs, e.g. n=name,a=able' ],
        [ 'list'            => 'list available policies, classes and versions' ],
        [ 'version|V'       => 'print version' ],
        [ 'completions'     => 'show completions, for shell completion' ],
    );
}

sub execute {
    my ( $self, $opt, $arg ) = @_;

    my $zilla = $self->zilla;
    $zilla->log_debug( [ 'args: %s', ( join q{,}, @{$arg} ) ] );

    if ( $opt->{'version'} ) {
        say __PACKAGE__ . q{ } . $VERSION;
        return;
    }

    if ( $opt->{'list'} ) {
        my $policies = Software::Policies->new->list();
        foreach my $policy ( keys %{$policies} ) {
            print $policy . q{/};
            foreach my $class ( keys %{ $policies->{$policy}->{'classes'} } ) {
                print $class . q{/};
                foreach my $version ( keys %{ $policies->{$policy}->{'classes'}->{$class}->{'versions'} } ) {
                    print q{v} . $version . "\n";
                }
            }

        }
        return;
    }

    if ( @{$arg} ) {
        my ($policy) = @{$arg};
        my %args = $self->_get_policy_config( $policy, $opt );

        $self->_do_policy( $policy, $args{class}, $args{version}, $args{format},
            $args{'dir'}, $args{'filename'}, $args{attributes} );
        return;
    }

    # If you do not specify a policy name,
    # then create files for all available policies.
    $self->_do_policies( $opt, $opt->{'attributes'} );

    return;
}

sub _do_policy {    ## no critic (Subroutines::ProhibitManyArgs)
    my ( $self, $policy, $class, $version, $format, $dir, $filename, $attributes ) = @_;
    my $zilla = $self->zilla;

    my %args = (
        policy     => $policy,
        attributes => $attributes // {},
    );
    $args{class}   = $class   if ($class);
    $args{version} = $version if ($version);
    $args{format}  = $format  if ($format);

    $zilla->log_debug( [ 'Looking for matching policy: %s:%s:%s:%s', $policy, $class, $version, $format, ] );
    $zilla->log_debug( [ 'dir: %s, filename: %s', $dir, $filename, ] );
    $zilla->log_debug( [ 'attributes: %s',        $args{attributes}, ] );
    my @p = Software::Policies->new->create(%args);

    # Create the file(s).
    foreach (@p) {
        $zilla->log_debug( [ 'Writing to dir: %s, filename: %s', $dir // q{.}, $filename // $_->{'filename'}, ] );
        my $d = $dir // q{.};
        path($d)->mkdir();
        path($d)->child( $filename // $_->{'filename'} )->spew_utf8( $_->{'text'} );
    }
    return;
}

# We check if we have any policy plugins defined,
# i.e. if we have any [Software::Policies / $policy] configs.
# If we have, we only create policy files for them,
# if not, we create policy files for all available policies,
# decided by Software::Policies.
sub _do_policies {
    my ( $self, $opt ) = @_;
    my $zilla = $self->zilla;

    # Plugins with a specific policy, e.g. [Software::Policies / Contributing]
    # key=policy name, value=plugin
    my @policies =
      map  { $_->plugin_name }
      grep { $_->isa('Dist::Zilla::Plugin::Software::Policies') && $_->plugin_name ne 'Software::Policies' }
      @{ $zilla->{'plugins'} };
    $zilla->log_debug( [ 'Discovered configs for policies %s', \@policies ] );

    if (@policies) {
        foreach my $policy (@policies) {
            $zilla->log_debug( [ 'Create file for policy %s', $policy ] );

            my %args = $self->_get_policy_config( $policy, $opt );
            $self->_do_policy( $policy, $args{class}, $args{version}, $args{format},
                $args{'dir'}, $args{'filename'}, $args{attributes} );
        }
    }
    else {
        $zilla->log_debug( ['No specific Software::Policies defined. Create all available policies'] );
        foreach my $policy ( keys %{ Software::Policies->new->list() } ) {
            $zilla->log_debug( [ 'Create policy %s', $policy ] );

            my %args = $self->_get_policy_config( $policy, $opt );
            $self->_do_policy( $policy, $args{class}, $args{version}, $args{format},
                $args{'dir'}, $args{'filename'}, $args{attributes} );
        }
    }
    return;
}

sub _get_policy_config {
    my ( $self, $policy, $opt ) = @_;
    my $zilla = $self->zilla;

    $zilla->log_debug( [ '_get_policy_config(%s, %s)', $policy, $opt ] );

    # 1. "Default" values, taken from dist.ini
    my %args;
    my %attributes = (
        name     => $zilla->{'name'},
        abstract => $zilla->{'abstract'},
        authors  => $zilla->{'authors'},
        license  => $zilla->license,

        # main_module       => $zilla->{'main_module'},
        # version           => $zilla->version,
    );
    $zilla->log_debug( ['After 1.'] );
    $zilla->log_debug( [ 'args: %s',       \%args, ] );
    $zilla->log_debug( [ 'attributes: %s', \%attributes, ] );

    # 2. Config items applied to all policies.
    # Only "[Software::Policies]"
    my $plain_plugin = first { $_->isa('Dist::Zilla::Plugin::Software::Policies') && $_->plugin_name eq 'Software::Policies' }
      @{ $zilla->{'plugins'} };
    if ($plain_plugin) {
        $zilla->log_debug( ['Discovered general setting for Software::Policies'] );
        for my $key (qw( class version format dir filename )) {
            $args{$key} = $plain_plugin->{$key} if $plain_plugin->{$key};
        }
        my %policy_attributes = %{ $plain_plugin->{'policy_attribute'} };
        @attributes{ keys %policy_attributes } = @policy_attributes{ keys %policy_attributes };
    }
    $zilla->log_debug( ['After 2.'] );
    $zilla->log_debug( [ 'args: %s',       \%args, ] );
    $zilla->log_debug( [ 'attributes: %s', \%attributes, ] );

    # 3. Only one policy's config
    # Only "[Software::Policies / $policy]", plugin_name is changed in module Plugin::S::p!
    my $this_plugin =
      first { $_->isa('Dist::Zilla::Plugin::Software::Policies') && $_->plugin_name =~ m/^ $policy $/msx } @{ $zilla->{'plugins'} };
    if ($this_plugin) {
        $zilla->log_debug( [ 'Discovered config for Software::Policies / %s: %s', $policy, $this_plugin->plugin_name ] );
        for my $key (qw( class version format dir filename )) {
            $args{$key} = $this_plugin->{$key} if $this_plugin->{$key};
        }
        my %policy_attributes = %{ $this_plugin->{'policy_attribute'} };
        @attributes{ keys %policy_attributes } = @policy_attributes{ keys %policy_attributes };
    }

    # 4. Config from the command line.
    for my $key (qw( class version format dir filename )) {
        $args{$key} = $opt->{$key} if $opt->{$key};
    }
    my %attrs = map { split qr/\s*=\s*/msx, $_, 2 } ( map { split qr/,/msx } $opt->{'attributes'} // q{} );
    @attributes{ keys %attrs } = @attrs{ keys %attrs };

    # Set attributes into %args.
    $args{attributes} = \%attributes;
    $zilla->log_debug( [ 'args: %s',       \%args, ] );
    $zilla->log_debug( [ 'attributes: %s', \%attributes, ] );

    return %args;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::App::Command::policies - Create project policy files

=head1 VERSION

version 0.001

=head1 AUTHOR

Mikko Koivunalho <mikkoi@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2025 by Mikko Koivunalho.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
