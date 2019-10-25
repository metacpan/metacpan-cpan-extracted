package Log::Any::Plugin::Levels;
# ABSTRACT: Logging-level filtering plugin for log adapters
$Log::Any::Plugin::Levels::VERSION = '0.008';
use strict;
use warnings;
use Carp qw(croak);
use Log::Any;

use Log::Any::Adapter::Util qw( numeric_level );
use Log::Any::Plugin::Util qw(
    all_logging_methods get_old_method set_new_method
);

my $default_level = 'warning';

# Inside-out storage for level field.
my %selected_level_name;

sub install {
    my ($class, $adapter_class, %args) = @_;

    my $accessor = $args{accessor} || 'level';
    croak $adapter_class . '::' . $accessor
        . q( already exists - use 'accessor' to specify another method name)
        if get_old_method($adapter_class, $accessor);

    if ($args{level}) {
        $default_level = $args{level};
        _get_level_value($default_level); # check
    }

    # Create the $log->level accessor
    set_new_method($adapter_class, $accessor, sub {
        my $self = shift;
        if (@_) {
            my $level_name = shift;
            _get_level_value($level_name); # check
            $selected_level_name{$self} = $level_name;
        }
        return $selected_level_name{$self};
    });

    # Augment the $log->debug methods
    for my $method_name ( all_logging_methods() ) {
        my $level = numeric_level($method_name);

        my $old_method = get_old_method($adapter_class, $method_name);
        set_new_method($adapter_class, $method_name, sub {
            my $self = shift;
            return if $level > _get_threshold_level($self);
            $self->$old_method(@_);
        });
    }

    # Augment the $log->is_debug methods
    for my $level_name ( all_logging_methods() ) {
        my $method_name = 'is_' . $level_name;
        my $level_value = numeric_level($level_name);

        my $old_method = get_old_method($adapter_class, $method_name);
        set_new_method($adapter_class, $method_name, sub {
            my $self = shift;
            return if $level_value > _get_threshold_level($self);
            return $self->$old_method(@_);
        });
    }
}

sub _get_level_value {
    my ($level_name) = @_;
    $level_name = $default_level if ($level_name eq 'default');
    my $level_value = numeric_level($level_name);
    croak('Unknown log level ' . $level_name)
        unless defined $level_value;
    return $level_value;
}

sub _get_threshold_level {
    my ($self) = @_;
    return _get_level_value($selected_level_name{$self} || $default_level);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Log::Any::Plugin::Levels - Logging-level filtering plugin for log adapters

=head1 VERSION

version 0.008

=head1 SYNOPSIS

    # Set up some kind of logger.
    use Log::Any::Adapter;
    Log::Any::Adapter->set('SomeAdapter');

    # Apply the Levels plugin to your logger
    use Log::Any::Plugin;
    Log::Any::Plugin->add('Levels', level => 'debug');


    # In your modules
    use Log::Any qw($log);

    $log->trace('trace'); # this log is ignored
    $log->error('error'); # this log gets through

    $log->level('trace');
    $log->trace('trace'); # this gets through now

=head1 DESCRIPTION

Log::Any leaves the decision of which log levels to ignore and which to
actually log down to the individual adapters. Many adapters simply log
everything.

Log::Any::Plugin::Levels allows you to add level filtering functionality into
any adapter. Logs lower than $log->level are ignored.

The $log->is_debug family of functions are modified to reflect this level.

=head1 NAME

Log::Any::Plugin::FilterArgs - custom log-level filtering for log adapters

=head1 CONFIGURATION

Configuration values are passed as key-value pairs when adding the plugin:
    Log::Any::Plugin->add('Levels',
                            level    => 'debug',
                            accessor => 'my_level');

=head2 level => $default_level

The global log level, which defaults to 'warning'. See the level method below
for a discussion on how this is applied.

=head2 accessor => $accessor_name

This is the name of the $log->level accessor function.

The default value is 'level'. This can be changed to avoid any name clashes
that may occur. An exception will be thrown in the case of a name clash.

=head1 METHODS

There are no methods in this package which should be directly called by the
user. Use Log::Any::Plugin->add() instead.

=head2 install

Private method called by Log::Any::Plugin->add()

=head1 ADAPTER METHODS

The following methods are injected into the adapter class.

=head2 level( [ $log_level ] )

Accessor for the current log level in the calling $log object.

All $log objects start with the default level specified when adding the
plugin.  Individual $log objects can set a custom level with this accessor.

To reset to the default log level, specify 'default'.

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
