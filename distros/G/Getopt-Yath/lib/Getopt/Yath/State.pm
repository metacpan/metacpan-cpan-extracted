package Getopt::Yath::State;
use strict;
use warnings;

our $VERSION = '2.000011';

use Getopt::Yath::HashBase qw{
    <settings
    <skipped
    <remains
    <env
    <cleared
    <modules
    ~stop
};

sub TO_JSON {
    my $self = shift;
    return {%$self};
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Getopt::Yath::State - Representation of the result of parsing command-line options.

=head1 DESCRIPTION

This object is returned by L<Getopt::Yath/parse_options> (and
L<Getopt::Yath::Instance/process_args>). It holds the parsed settings, any
skipped or remaining arguments, the stop token (if any), environment variable
changes, cleared options, and the modules whose options were used.

This object is a blessed hash, so hash-key access (e.g.,
C<< $state->{settings} >>) continues to work for backwards compatibility.
However, accessor methods are preferred.

=head1 SYNOPSIS

    my $state = parse_options(\@ARGV, stops => ['--']);

    my $settings = $state->settings;     # Getopt::Yath::Settings object
    my $remains  = $state->remains;      # args after a stop token
    my $skipped  = $state->skipped;      # skipped non-options
    my $stop     = $state->stop;         # what token stopped parsing
    my $env      = $state->env;          # env vars that were/would be set
    my $cleared  = $state->cleared;      # options cleared via --no-opt
    my $modules  = $state->modules;      # modules whose options were used

=head1 METHODS

=over 4

=item $settings = $state->settings

Returns the L<Getopt::Yath::Settings> object containing all parsed option
values organized by group.

=item $arrayref = $state->skipped

Returns an arrayref of arguments that were skipped during parsing (when
C<skip_non_opts> or C<skip_invalid_opts> is enabled).

=item $arrayref = $state->remains

Returns an arrayref of arguments that were not processed, typically those
appearing after a stop token such as C<-->.

=item $string = $state->stop

=item $state->set_stop($token)

Returns the token that caused parsing to stop (e.g., C<-->, C<::>), or
C<undef> if parsing completed normally. C<set_stop> is used internally during
parsing.

=item $hashref = $state->env

Returns a hashref of environment variable changes. Keys are variable names,
values are what was (or would have been, with C<no_set_env>) set. A value of
C<undef> means the variable was cleared.

=item $hashref = $state->cleared

Returns a hashref tracking which options were explicitly cleared via
C<--no-opt>. Structure is C<< { group_name => { field_name => 1 } } >>.

=item $hashref = $state->modules

Returns a hashref of modules whose options were used during parsing. Keys are
module names, values are usage counts.

=back

=head1 SOURCE

The source code repository for Getopt-Yath can be found at
L<http://github.com/Test-More/Getopt-Yath/>.

=head1 MAINTAINERS

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=back

=head1 AUTHORS

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=back

=head1 COPYRIGHT

Copyright Chad Granum E<lt>exodist7@gmail.comE<gt>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See L<http://dev.perl.org/licenses/>

=cut
