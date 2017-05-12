package Log::Log4perl::Appender::Lim::CLI;

use warnings;
use strict;

use base qw(Log::Log4perl::Appender);

=encoding utf8

=head1 NAME

Log::Log4perl::Appender::Lim::CLI - A Log4perl appender for Lim CLI

=head1 VERSION

Version 0.15

=cut

our $VERSION = '0.15';

=head1 DESCRIPTION

This module is used for getting L<Log::Log4perl> output to the L<Lim::CLI>
module.

=cut

sub new {
    my $this = shift;
    my $class = ref($this) || $this;
    my %args = ( @_ );
    my $self = {
        name => 'unknown name',
        %args
    };
    
    bless $self, $class;
}

sub log {
    my($self, %params) = @_;

    if (defined $self->{cli}) {
        $params{message} =~ s/[\r\n]+$//o;
        $self->{cli}->println($params{message});
    }
}

=head1 AUTHOR

Jerry Lundström, C<< <lundstrom.jerry at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to L<https://github.com/jelu/log-log4perl-appender-lim-cli/issues>.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Log::Log4perl::Appender::Lim::CLI

You can also look for information at:

=over 4

=item * Lim issue tracker (report bugs here)

L<https://github.com/jelu/log-log4perl-appender-lim-cli/issues>

=back

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

Copyright 2012 Jerry Lundström.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of Log::Log4perl::Appender::Lim::CLI
