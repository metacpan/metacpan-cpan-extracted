package Developer::Dashboard::Pax::Differential;

our $VERSION = '4.45';

use strict;
use warnings;
use IPC::Open3;
use JSON::XS ();
use Symbol qw(gensym);
use Developer::Dashboard::Pax::Capture;

sub new {
    my ($class, %args) = @_;
    return bless {
        pax_bin => $args{pax_bin},
    }, $class;
}

sub compare_capture {
    my ($self, $entrypoint) = @_;
    my $stock = _run($^X, $entrypoint);
    my $capture = eval { Developer::Dashboard::Pax::Capture->new(mode => 'live')->capture($entrypoint) };
    my $pax = {
        command => ['Developer::Dashboard::Pax::Capture', $entrypoint],
        exit => ($@ || !$capture || ($capture->{status} // '') ne 'ok') ? 1 : 0,
        stdout => '',
        stderr => $@ // '',
    };

    return {
        entrypoint => $entrypoint,
        stock => $stock,
        pax => $pax,
        pass => ($stock->{exit} == 0 && $pax->{exit} == 0) ? JSON::XS::true() : JSON::XS::false(),
        comparison => {
            stock_exit => $stock->{exit},
            pax_exit => $pax->{exit},
            stock_stderr_present => $stock->{stderr} ne '' ? JSON::XS::true() : JSON::XS::false(),
            pax_stderr_present => $pax->{stderr} ne '' ? JSON::XS::true() : JSON::XS::false(),
        },
    };
}

sub _run {
    local $?;    # DD-882 (vendored-in from PAX): guard $? so this sub's own subprocess call never leaks a mutated exit status to whatever runs in the caller after it returns.
    my (@cmd) = @_;
    my $err = gensym;
    my $pid = open3(my $in, my $out, $err, @cmd);
    close $in;
    local $/;
    my $stdout = <$out> // '';
    my $stderr = <$err> // '';
    waitpid($pid, 0);
    return {
        command => \@cmd,
        exit => $? >> 8,
        stdout => $stdout,
        stderr => $stderr,
    };
}

1;

__END__

=head1 NAME

Developer::Dashboard::Pax::Differential - compare stock Perl execution with PAX capture behavior

=head1 SYNOPSIS

  my $diff = Developer::Dashboard::Pax::Differential->new;
  my $report = $diff->compare_capture('script.pl');

=head1 DESCRIPTION

C<Developer::Dashboard::Pax::Differential> is an internal validation helper. It keeps differential
capture checks available after SOW-03 removed C<pax capture> from the public CLI
by invoking C<Developer::Dashboard::Pax::Capture> directly.

=head1 METHODS

=head2 new

Constructs a differential runner. The historical C<pax_bin> argument is accepted
for compatibility with older tests but no longer drives capture through the CLI.

=head2 compare_capture

Runs the entrypoint with stock Perl, captures it through C<Developer::Dashboard::Pax::Capture>, and
returns comparable exit/status metadata.

=head1 PURPOSE

This module exists to make stock-Perl versus PAX capture differences explicit
when a behavior mismatch appears, instead of forcing contributors to debug the
two paths manually from scratch.

=head1 WHY IT EXISTS

PAX's core promise is behavioral equivalence: a captured/compiled entrypoint
should behave the same as running it under stock C<perl>. That claim needs
an automatic check, not a manual eyeballing of two separate runs, and the
check needs to survive C<pax capture> having been removed as a public
SOW-03 CLI command (see L<Developer::Dashboard::Pax::CLI>) - this module
keeps the comparison alive internally by calling
L<Developer::Dashboard::Pax::Capture> directly rather than shelling out to
a subcommand that no longer exists.

=head1 WHEN TO USE

Edit this file when the fields a differential comparison reports need to
change (currently just exit-code and stderr-presence parity), or when
C<compare_capture> needs to account for a new way stock-Perl and captured
execution could legitimately diverge.

=head1 HOW TO USE

Construct a C<Differential> runner and call C<compare_capture> with one
entrypoint path. Read the returned C<pass> flag first; the C<comparison>
sub-hash gives the specific stock/pax exit codes and stderr-presence flags
that decided it, useful when C<pass> is false and you need to see exactly
where the two paths diverged.

=head1 WHAT USES IT

PAX's own internal validation/regression paths use this to catch a capture
regression that would otherwise only surface as an opaque behavioral
difference somewhere downstream in a built binary.

=head1 EXAMPLES

Example 1:

  my $diff = Developer::Dashboard::Pax::Differential->new;
  my $report = $diff->compare_capture('t/fixtures/simple.pl');
  # $report->{pass} is true when both the stock and PAX-captured runs exit 0

Example 2:

  if ( !$report->{pass} ) {
      warn "stock exit=$report->{comparison}{stock_exit} pax exit=$report->{comparison}{pax_exit}\n";
  }

=cut
