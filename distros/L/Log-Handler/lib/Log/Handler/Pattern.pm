=head1 NAME

Log::Handler::Output - The pattern builder class.

=head1 DESCRIPTION

Just for internal usage!

=head1 FUNCTIONS

=head2 get_pattern

=head1 PREREQUISITES

    Carp
    POSIX
    Sys::Hostname
    Time::HiRes
    Log::Handler::Output

=head1 AUTHOR

Jonny Schulz <jschulz.cpan(at)bloonix.de>.

=head1 COPYRIGHT

Copyright (C) 2007-2009 by Jonny Schulz. All rights reserved.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

package Log::Handler::Pattern;

use strict;
use warnings;
use POSIX;
use Sys::Hostname;
use Time::HiRes;
use Log::Handler::Output;
use constant START_TIME => scalar Time::HiRes::gettimeofday;

our $VERSION = "0.07";
my $progname = $0;
$progname =~ s@.*[/\\]@@;

sub get_pattern {
    return {
        '%L'  => {  name => 'level',
                    code => \&_get_level },
        '%T'  => {  name => 'time',
                    code => \&_get_time },
        '%D'  => {  name => 'date',
                    code => \&_get_date },
        '%P'  => {  name => 'pid',
                    code => \&_get_pid },
        '%H'  => {  name => 'hostname',
                    code => \&Sys::Hostname::hostname },
        '%N'  => {  name => 'newline',
                    code => sub { "\n" } },
        '%S'  => {  name => 'progname',
                    code => sub { $progname } },
        '%U'  => {  name => 'user',
                    code => \&_get_user },
        '%G'  => {  name => 'group',
                    code => \&_get_group },
        '%C'  => {  name => 'caller',
                    code => \&_get_caller },
        '%r'  => {  name => 'runtime',
                    code => \&_get_runtime },
        '%t'  => {  name => 'mtime',
                    code => \&_get_hires },
        '%m'  => {  name => 'message',
                    code => \&_get_message },
        '%p'  => {  name => 'package',
                    code => \&_get_c_pkg },
        '%f'  => {  name => 'filename',
                    code => \&_get_c_file },
        '%l'  => {  name => 'line',
                    code => \&_get_c_line },
        '%s'  => {  name => 'subroutine',
                    code => \&_get_c_sub },
    }
}

# ------------------------------------------
# Arguments:
#   $_[0]  ->  Log::Handler::Output object
#   $_[1]  ->  Log level
# ------------------------------------------

sub _get_level   { $_[1] }
sub _get_time    { POSIX::strftime($_[0]->{timeformat}, localtime) }
sub _get_date    { POSIX::strftime($_[0]->{dateformat}, localtime) }
sub _get_pid     { $$ }
sub _get_caller  { my @c = caller(2+$Log::Handler::CALLER_LEVEL); "$c[1], line $c[2]" }
sub _get_c_pkg   { (caller(2+$Log::Handler::CALLER_LEVEL))[0] }
sub _get_c_file  { (caller(2+$Log::Handler::CALLER_LEVEL))[1] }
sub _get_c_line  { (caller(2+$Log::Handler::CALLER_LEVEL))[2] }
sub _get_c_sub   { (caller(3+$Log::Handler::CALLER_LEVEL))[3]||"" }
sub _get_runtime { return sprintf('%.6f', Time::HiRes::gettimeofday - START_TIME) }
sub _get_user    { getpwuid($<) || $<     }
sub _get_group   { getgrgid($(+0) || $(+0 }

sub _get_hires {
    my $self = shift;
    if (!$self->{timeofday}) {
        $self->{timeofday} = Time::HiRes::gettimeofday;
        return sprintf('%.6f', $self->{timeofday} - START_TIME);
    }
    my $new_time = Time::HiRes::gettimeofday;
    my $cur_time = $new_time - $self->{timeofday};
    $self->{timeofday} = $new_time;
    return sprintf('%.6f', $cur_time);
}

1;
