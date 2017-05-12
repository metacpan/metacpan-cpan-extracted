package Log::Dispatch::Gtk2::Notify::Types;
our $VERSION = '0.02';

use MooseX::Types::Moose qw/Str/;
use Log::Dispatch;

use namespace::clean -except => 'meta';

use MooseX::Types -declare => [qw/
    LogLevel
    Widget
    StatusIcon
    Pixbuf
/];

subtype LogLevel,
    as Str,
    where { Log::Dispatch->level_is_valid($_) },
    message { 'invalid log level' };

class_type Widget,     { class => 'Gtk2::Widget'      };
class_type StatusIcon, { class => 'Gtk2::StatusIcon'  };
class_type Pixbuf,     { class => 'Gtk2::Gdk::Pixbuf' };

1;

__END__
=pod

=head1 NAME

Log::Dispatch::Gtk2::Notify::Types

=head1 VERSION

version 0.02

=head1 AUTHOR

Florian Ragwitz <rafl@debian.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Florian Ragwitz.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

