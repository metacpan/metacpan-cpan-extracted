package Devel::Tinderbox::Reporter;

use strict;
use vars qw($VERSION @ISA);
$VERSION = '0.10';

require Class::Accessor::Fast;
@ISA = qw(Class::Accessor::Fast);

my $CLASS = __PACKAGE__;


=head1 NAME

Devel::Tinderbox::Reporter - Client to send reports to Tinderbox

=head1 SYNOPSIS

    use Devel::Tinderbox::Reporter;

    my $report = Devel::Tinderbox::Reporter->new;

    $report->from('your@mail.address.com');
    $report->to('tinderbox@their.address.com');
    $report->project('the_project');
    $report->boxname('your.machine.name');
    $report->style('unix');
    $report->start;

    ...go and test your project...

    $report->log($build_log);
    $report->end($status);

=head1 DESCRIPTION

Tinderbox collects and summaries build and test reports from many
developers on many machines.  This is a simple client for testers to
make reports to Tinderbox servers.


=head2 Starting off

First thing, you need a Devel::Tinderbox::Reporter object.

=over 4

=item B<new>

  my $report = Devel::Tinderbox::Reporter->new;

Creates a new reporter representing this testing session.

=cut

# Inherited from Class::Accessor

=back


=head2 Tell us a little about yourself

You then have to tell it about yourself and what you're testing.  Fill
in each of these blanks.  You can either call these methods
individually or pass each to new().

=item B<from>

  $report->from($my_email);

Email address you wish to report as.

=item B<to>

  $report->to($their_email);

Email address you're sending reports to.

=item B<project>

  $report->project($project_name);

Name of the Tinderbox project you're reporting about.

=item B<boxname>

  $report->boxname($box_name);

Name of the machine this is being built on.  This is a unique id for
your build.  Maybe something like your machine's name, your name and
OS.  "Schwern blackrider Debian-Linux/PowerPC-testing"

=item B<style>

  $report->style($build_style);

This corresponds to the style of building you're doing, cluing
Tinderbox how to parse your build and test output.  For example,
"unix" might indicate normal make and cc output.  "mac" might indicate
that Macintosh build tools were used.

=cut

$CLASS->mk_accessors(qw(from to project boxname style));

=back

=head2 Let Tinderbox know you're starting a build.

=over 4

=item B<start>

  $report->start;

Sends off an email to the Tinderbox server (ie. to()) letting them
know you've started a build and test cycle.

=cut

sub start {
    my($self) = shift;

    $self->{builddate} = time;
    $self->{status} = 'building';

    $self->_send_tindermail('START');
}

my %Var_Map = (
               project      => 'tree',
               builddate    => 'builddate',
               status       => 'status',
               boxname      => 'build',
               style        => 'errorparser',
              );

use Mail::Mailer;
sub _send_tindermail {
    my($self, $type, $extra) = @_;

    my $mailer = Mail::Mailer->new('smtp', Server => 'localhost');
    $mailer->open({To        => $self->{to},
                   From      => $self->{from},
                   Subject   => 'Tinderbox',
                 });
    my @out = ();
    while(my($k,$v) = each %Var_Map) {
        if( defined $self->{$k} ) {
            push @out, "tinderbox: $v: $self->{$k}\n";
        }
    }
    push @out, "tinderbox: $type\n";

    print $mailer @out;
    print $mailer $extra if defined $extra;
    $mailer->close;
}
    

=back

=head2 Report on the build.

Run your build and tests and such.  Capture the output, then tell
Tinderbox about it with these methods.

=over 4

=item B<end>

  $report->end($status, $log);

Sends off an email to the Tinderbox server.  Did it work?  $status can
be one of:

    success         built and tested 100% succesfully
    testfailed      built ok, but testing failed.
    busted          failed during build

The $log is the complete output of your build and test run.

=cut

sub end {
    my($self, $status, $log) = @_;

    $self->{status} = $status;
    $self->_send_tindermail('END', $log);
}

=back

=head1 EXAMPLE

  use Devel::Tinderbox::Reporter;

  my $report = Devel::Tinderbox::Reporter->new({
                          from => 'schwern@pobox.com',
                          to   => 'tinderbox@onion.perl.org',
                          project => 'perl6',
                          boxname => 'Schwern blackrider Debian/PowerPC',
                          style   => 'unix/perl'
                         });

  $report->start;

  my($build_exit, $make_out) = run_make;
  my($test_exit,  $test_out) = run_tests if $build_exit == 0;

  my $status = $build_exit != 0 ? 'busted'     :
               $test_exit  != 0 ? 'testfailed' :
                                  'success';
  $report->end($status, "$make_out\n$test_out");


=head1 AUTHOR

Original concept by Zach Lipton, code by Michael G Schwern.

=head1 SEE ALSO

http://tinderbox.mozilla.org/

=cut

1;
