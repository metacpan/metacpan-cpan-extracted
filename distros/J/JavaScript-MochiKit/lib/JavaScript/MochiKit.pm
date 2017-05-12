package JavaScript::MochiKit;

use strict;
use vars qw[ $VERSION $LOADJAVASCRIPT $DEBUG ];
use base qw[ JavaScript::MochiKit::Accessor ];

$VERSION        = '0.04';
$LOADJAVASCRIPT = 1;
$DEBUG          = 0;

use JavaScript::MochiKit::Module;
my %JavaScriptModules = ();

=head1 NAME

JavaScript::MochiKit - JavaScript::MochiKit makes Perl suck less

=head1 SYNOPSIS

    #!/usr/bin/perl

    use strict;
    use warnings;
    use JavaScript::MochiKit;

    JavaScript::MochiKit::require('Base', 'Async');

    print JavaScript::MochiKit::javascript_definitions;


=head1 DESCRIPTION

=head1 FUNCTIONS

=head2 JavaScript::MochiKit::require( @classes )

Loades the given MochiKit classes and also their
javascript-code (unless C<$JavaScript-Mochikit::LOADJAVASCRIPT> is 0).

Returns 1 on success, dies on error.

=cut

sub require {
    my (@classes) = @_;

    my $this = __PACKAGE__;
    die("$this\::require() takes at least one argument") if @classes < 1;

    my $load_javascript = $LOADJAVASCRIPT;
    if ( ref $classes[0] eq 'ARRAY' ) {
        $load_javascript = $classes[1] if @classes > 1;
        @classes = @{ $classes[0] };
    }

    foreach my $class (@classes) {
        die("$this\::require() can only be run as a class method")
          if ref $class;

        my $module;
        unless ( $module = $JavaScriptModules{ uc $class } ) {
            $module = JavaScript::MochiKit::Module->new();
            $module->name($class);
            $JavaScriptModules{ uc $class } = $module;
            print STDERR "Module '$class' just created.\n" if $DEBUG;
        }

        my $core_namespace = "$this\::$class";
        my $pack_namespace = "$this\::JS::$class";

        unless ( $module->required ) {

            eval "CORE::require $core_namespace";
            die $@ if $@;

            print STDERR "Package '$core_namespace' just loaded.\n" if $DEBUG;

            my $dependencies =
              &_get_variable( $core_namespace, 'Dependencies', 'ARRAY' );
            if ( defined $dependencies ) {
                foreach my $dep ( @{$dependencies} ) {
                    &require( [$dep], $load_javascript )
                      unless &is_required($dep);
                }
            }
            else {
                print STDERR "No Dependencies found in '$core_namespace'.\n"
                  if $DEBUG;
            }

            $module->required(1);
        }

        if ( $load_javascript != 0 and not $module->javascript_loaded ) {

            eval "CORE::require $pack_namespace";
            die $@ if $@;

            print STDERR "Package '$pack_namespace' just loaded.\n" if $DEBUG;

            my $data;
            {
                no strict 'refs';
                $data = *{"${pack_namespace}::DATA"};
            }
            {
                local $/;
                $module->javascript_definition(<$data>);

                print STDERR "Javascript just loaded from '$pack_namespace'.\n"
                  if $DEBUG;

                close $data;
            }
        }
    }

    return 1;
}

sub _get_variable {
    my ( $namespace, $variable, $type ) = @_;

    {
        no strict 'refs';
        if ( my $glob = ${"$namespace\::"}{$variable} ) {
            if ( my $ref = *{$glob}{$type} ) {
                return $ref;
            }
        }
    }

    return undef;
}

=head2 JavaScript::MochiKit::require_all( )

Loades all MochiKit classes and also their
javascript-code (unless C<$JavaScript-Mochikit::LOADJAVASCRIPT> is 0).

Returns 1 on success, dies on error.

=cut

sub require_all {

    my @classes = qw[
      Core Base Iter Logging
      DateTime Format Async DOM
      LoggingPane Color Visual
    ];

    &require(@classes);
}

=head2 JavaScript::MochiKit::is_required( $class )

Returns 1 if class has already been loaded, 0 otherwise.

=cut

sub is_required {
    my ($class) = @_;

    return defined $JavaScriptModules{ uc $class };
}

=head2 JavaScript::MochiKit::javascript_definitions( @classes )

Returns the Javascript code as one big string for all wanted
classes. Calls JavaScript::MochiKit::require(  ) for all classes that are not loaded yet.

Returns the Javascript code for all loaded classes if @classes is empty. Returns an empty
string if no class is loaded.

May die if a unloaded class does not exist.

=cut

sub javascript_definitions {
    my (@classes) = @_;
    @classes = sort keys %JavaScriptModules if @classes < 1;

    my $retval = '';
    foreach my $class (@classes) {
        &require( [$class], 1 );    # make sure javascript gets loaded
        $retval .= $JavaScriptModules{ uc $class }->javascript_definition;
        $retval .= "\n";
    }

    return $retval;
}

=head1 METHODS

=head1 GLOBAL VARIABLES

=head2 $JavaScript::Mochikit::DEBUG

Enables debug-information-output to STDERR.

Default 0

=cut

=head2 $JavaScript::Mochikit::LOADJAVASCRIPT

If value is 0, C<JavaScript::MochiKit::require> will not load the javascript-code into memory.

Useful if javascript-code is available as external files. (NOTE: C<JavaScript::Mochikit::javascript_definitions>
will always load the javascript-code into memory.)

Default 1

=cut

=head2 $JavaScript::Mochikit::VERSION

Returns the current JavaScript-Mochikit version number.

=cut

=head1 SEE ALSO

L<HTML::Prototype>, L<Catalyst>

L<http://www.perl-community.de>, L<http://www.catalystframework.org>, L<http://www.mochikit.org>

=head1 AUTHOR

Sascha Kiefer, C<esskar@cpan.org>

=head1 LICENSE

This library is free software, you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

1;
