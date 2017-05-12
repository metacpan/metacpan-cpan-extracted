package Dependencies::Searcher::AckRequester;

use 5.010;
use Data::Printer;
use feature qw(say);
use Module::CoreList qw();
use autodie;
use Moose;
use IPC::Cmd qw[can_run run];
use IPC::Run;
use Log::Minimal env_debug => 'LM_DEBUG';
use File::Stamped;
use File::HomeDir;
use File::Spec::Functions qw(catdir catfile);


# Warning !!! This modules will be used throught a system call
#   - App::Ack;

has 'full_path' => (
  is  => 'rw',
  isa => 'Str',
);

$IPC::Cmd::USE_IPC_RUN = 1;

local $ENV{LM_DEBUG} = 1; # 1 for debug logs, 0 for info

my $work_path = File::HomeDir->my_data;
my $log_fh = File::Stamped->new(
    pattern => catdir($work_path,  "dependencies-searcher.log.%Y-%m-%d.out"),
);

# Overrides Log::Minimal PRINT
$Log::Minimal::PRINT = sub {
    my ( $time, $type, $message, $trace) = @_;
    print {$log_fh} "$time [$type] $message\n";
};

sub get_path {
    my $self = shift;

    my $tmp_full_path = can_run('ack');

    if ($tmp_full_path) {
	$self->full_path($tmp_full_path);
	debugf("Ack full path : " . $self->full_path);
	return $self->full_path;
    } else {
	critf('Something goes wrong with Ack path or IPC::Run is not available !');
    }
}

sub build_cmd {

    my ($self, @params) = @_;

    my @cmd = ($self->full_path, @params);
    my $cmd_href = \@cmd;

    return $cmd_href;
}

# Maybe this is not very clean, but it works (except on MS Windows maybe)
sub ack {
    my ($self, $cmd) = @_;
    my (
	$success,
	$error_message,
	$full_buffer,
	$stdout_buffer,
	$stderr_buffer
    ) = run (
	command => $cmd,
	verbose => 0
    );

    my @modules;

    debugf("All modules in distribution : " . join "", @$full_buffer);

    if ($success) {
	push @modules, split(/\n/m, $$full_buffer[0]);
    } else {
	say "No module have been found or IPC::Cmd failed with error $error_message";
    }

    return @modules;
}

1;

__END__

=pod

=head1 NAME

Dependencies::Searcher::AckRequester - Helps Dependencies::Searcher to use Ack

=cut

=head1 SYNOPSIS

    my $requester = Dependencies::Searcher::AckRequester->new();

    # Places to search...
    my @path = ("./lib", "./Makefile.PL", "./script");

    # Params for Ack
    my @params = ('--perl', '-hi', $pattern, @path);

    # Absolute path to the Ack binary
    my $ack_path = $requester->get_path();

    # Build the command for IPC::Cmd
    my $cmd_use = $requester->build_cmd(@params);

    # Execute the command and retrieve the output
    my @moduls = $requester->ack($cmd_use);

=head1 DESCRIPTION

This module use L<ack> through a system command to search recursively for
patterns. It use L<IPC::Cmd> as a layer between the module and L<ack>, that
execute and retrieve the command output.

It also builds the command itself (path and arguments). Arguments are
stored into an array, because it is too much dangerous to build a
command with strings (space problems are one reason among others).

It's not made to be used independantly from Dependencies::Searcher
(mean it's not supposed to be used directly into your programs, but
you can try if you want...)

=head1 SUBROUTINES/METHODS

=head2 get_path()

Returns the L<ack> full path if installed. Set the C<full_path>
L<Moose> attribute that will be used by ICP::Cmd. It verify also that
L<Ack> is reachable or warns about it.

=cut

=head2 build_cmd(@params)

C<build_cmd()> takes as parameter all the arguments Ack will
need. L<Dependencies::Searcher> defines it like this :

=over 4

=item * C<--perl>   : tells to search in Perl like files (C<*.pm>, C<*.pl>, etc.) 

=item * C<-hi>      : suppress the prefixing filename on output + ignore
case

=item * C<$pattern> : must be passed from your implementation

=item * C<@path>    : files and directories where L<ack> will go 

All these params are merged in an only array reference that is returned for
later use with L<IPC::Cmd>.

=back

=cut

=head2 ack($params_array_ref)

Execute the L<IPC::Cmd> command that calls C<ack> and returns an array of
potentially interesting lines, containing dependencies names but some
crap inside too.

=cut

=head1 CAVEATS

Win32 and Cygwin platforms aren't well supported but last tests have not 
been that bad.

=head1 BUGS

Please report any bugs or feature requests to
C<bug-dependencies-searcher  at rt.cpan.org>, or through the web
interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Dependencies-Searcher>.
I will be notified, and then you'll automatically be notified of
progress on your bug as I make changes.

=head1 TODOs

=head1 AUTHOR

smonff, C<< <smonff at gmail.com> >>

=head1 ACKNOWLEDGEMENTS

=over

=item Ack

Ack gives me the wish to try to write this module. It was pure Perl so
I've choose it because it was possible to install it through CPAN
during the distribution installation process. Even if Ack was not
meant for being used programatically, this hacked use of Ack do the
job.

See L<http://beyondgrep.com/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2013 smonff.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.


=cut


