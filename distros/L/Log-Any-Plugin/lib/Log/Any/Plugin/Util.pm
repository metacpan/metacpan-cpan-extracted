package Log::Any::Plugin::Util;
# ABSTRACT: Utilities for Log::Any::Plugin classes
$Log::Any::Plugin::Util::VERSION = '0.008';
use strict;
use warnings;
use Carp qw(croak);
use Log::Any qw();

use base qw(Exporter);

our @EXPORT_OK = qw(
    get_old_method
    set_new_method
    get_class_name
    all_logging_methods
);

sub get_old_method {
    my ($class, $method_name) = @_;
    return $class->can($method_name);
}

sub set_new_method {
    my ($class, $method_name, $new_method) = @_;

    no warnings 'redefine';
    no strict 'refs'; ## no critic (ProhibitNoStrict)
    *{ $class . '::' . $method_name } = $new_method;
}

sub get_class_name {
    my ($name) = @_;

    return substr($name, 0, 1) eq '+' ? substr($name, 1)
                                      : 'Log::Any::Plugin::' . $name;
}

sub all_logging_methods {
    my ($class) = @_;

    return ( Log::Any->logging_methods, Log::Any->log_level_aliases );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Log::Any::Plugin::Util - Utilities for Log::Any::Plugin classes

=head1 VERSION

version 0.008

=head1 DESCRIPTION

These functions are only of use to authors of Log::Any::Plugin classes.

Users should see Log::Any::Plugin instead.

=head1 CLASS METHODS

=head2 get_old_method ( $class, $method_name )

Returns a coderef of the existing method in the class, or undef if none exists.
Exactly the same semantics as $class->can($method_name).

=head2 set_new_method ( $class, $method_name, &new_method )

Replaces the given method with the new version.

=over

=item * $class

Name of class containing the method.

=item * $method_name

Name of method to be modified.

=item * &new_method

Coderef of the new method.

=back

=head2 get_class_name ( $name )

Creates a fully-qualified class name from the abbreviated class name rules
in Log::Any::Plugin.

=over

=item * $name

Either a namespace suffix, or a fully-qualified class name prefixed with '+'.

=back

=head2 all_logging_methods

Return an array of all the Log:Any logging methods and aliases

=head1 SEE ALSO

L<Log::Any::Plugin>

=head1 ACKNOWLEDGEMENTS

Thanks to Strategic Data for sponsoring the development of this module.

=head1 AUTHOR

Stephen Thirlwall <sdt@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019, 2017, 2016, 2015, 2014, 2013, 2011 by Stephen Thirlwall.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
