package Log::Any::Plugin::ANSIColor;
use 5.008001;
use strict;
use warnings;

our $VERSION = "0.01";

use Log::Any::Plugin::Util  qw( get_old_method set_new_method );
use Term::ANSIColor         qw( colored colorvalid );

our %default = (
    emergency  => 'bold magenta',
    alert      => 'magenta',
    critical   => 'bold red',
    error      => 'red',
    warning    => 'yellow',
    debug      => 'cyan',
    trace      => 'blue',
);

sub install {
    my ($class, $adapter_class, %color_map) = @_;

    if ((delete $color_map{default}) || (keys %color_map == 0)) {
        # Copy the default colors, leaving any the user has specified.
        for my $method (keys %default) {
            $color_map{$method} ||= $default{$method};
        }
    }

    for my $method_name (Log::Any->logging_methods) {
        if (my $color = delete $color_map{$method_name}) {
            # Specifying none as the color name disables colorisation for that
            # method.
            next if $color eq 'none';

            if (!colorvalid($color)) {
                warn "Invalid color name \"$color\" for $method_name";
                next;
            }

            my $old_method = get_old_method($adapter_class, $method_name);
            set_new_method($adapter_class, $method_name, sub {
                my $self = shift;
                $self->$old_method(colored([$color], @_));
            });
        }
    }

    if (my @remainder = sort keys %color_map) {
        warn 'Unknown logging methods: ', join(', ', @remainder);
    }
}

1;
__END__

=encoding utf-8

=head1 NAME

Log::Any::Plugin::ANSIColor - Auto-colorize Log::Any logs with Term::ANSIColor

=head1 SYNOPSIS

    use Log::Any::Adapter 'Stderr';     # Choose any adapter that makes sense

    use Log::Any::Plugin;
    Log::Any::Plugin->add('ANSIColor'); # Use the default colorscheme

    # In this or any other module
    use Log::Any qw( $log );

    $log->alert('Call the police!');    # Prints as red on white

=head1 DESCRIPTION

Log::Any::Plugin::ANSIColor automatically applies ANSI colors to log messages depending on the log level.

For example, with the default colorscheme, C<error> logs are red, C<warning> logs are yellow.

If a given log level has no coloring, the original log method is left intact, and incurs no overhead.

=head1 USAGE

Adding the plugin with no extra arguments gives the default colorscheme.

    Log::Any::Plugin->add('ANSIColor');

Note that C<info> and C<notice> messages have no special coloring in the default colorscheme.


Specify some colors to completely replace the default colorscheme. Only the specified colors are applied.

    Log::Any::Plugin->add('ANSIColor',
            error   => 'white on_red',
            warning => 'black on_yellow',
    );

Use C<< default => 1 >> to include the default colorscheme with customisations. Default colors can be switched off by specifying C<'none'> as the color.

    Log::Any::Plugin->add('ANSIColor',
            default => 1,               # use default colors
            error   => 'white on_red',  # override error color
            warning => 'none',          # turn off warning color
    );

Valid colors are any strings acceptable to C<colored> in L<Term::ANSIColor>.
eg. C<'blue'> C<'bright_red on_white>

=head1 LICENSE

Copyright (C) Stephen Thirlwall.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Stephen Thirlwall E<lt>sdt@cpan.orgE<gt>

=cut

