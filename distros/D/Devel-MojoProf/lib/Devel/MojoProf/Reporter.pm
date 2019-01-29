package Devel::MojoProf::Reporter;
use Mojo::Base -base;

use Mojo::File 'path';

has handler => undef;
has out_csv => $ENV{DEVEL_MOJOPROF_OUT_CSV};

# Note that $prof is just here to be back compat
sub report {
  my ($self, $report, $prof) = @_;

  if ($self->{out_fh} ||= $self->_build_out_fh) {
    my $message = $report->{message};
    $message =~ s!"!""!g;
    return printf {$self->{out_fh}} qq(%s,%.5f,%s,%s,%s,%s,"%s"\n), $report->{t0}[0],
      @$report{qw(elapsed class method file line)}, $message;
  }

  return $self->{handler}->($prof, $report) if $self->{handler};
  return printf STDERR "%.5fms [%s::%s] %s\n", @$report{qw(elapsed class method message)} unless $report->{line};
  return printf STDERR "%.5fms [%s::%s] %s at %s line %s\n", @$report{qw(elapsed class method message file line)};
}

sub _build_out_fh {
  my $self = shift;
  my $path = $self->out_csv or return;

  $path = "devel-mojoprof-reporter-$^T.csv" if $path eq '1';
  die "[Devel::MojoProf] Cannot overwrite existing $path report.\n" if -e $path;

  $path = path $path;
  my $fh = $path->open('>');
  $fh->autoflush(1);
  printf {$fh} "%s\n", join ',', qw(t0 elapsed class method file line message);
  $self->out_csv($path->to_abs);
  return $fh;
}

1;

=encoding utf8

=head1 NAME

Devel::MojoProf::Reporter - Default mojo profile reporter

=head1 DESCRIPTION

L<Devel::MojoProf::Reporter> is an object that is capable of reporting how long
certain operations take.

See L<Devel::MojoProf> for how to use this.

=head1 ATTRIBUTES

=head2 handler

  my $cb       = $reporter->handler;
  my $reporter = $reporter->handler(sub { ... });

Only useful to be back compat with L<Devel::MojoProf> 0.01:

  $prof->reporter(sub { ... });

Will be removed in the future.

=head2 out_csv

  $str      = $reporter->out_csv;
  $reporter = $reporter->out_csv("/path/to/file.csv");

Setting this attribute will cause L</report> to print the results to a CSV
file, instead of printing to STDERR. This will allow you to post-process
the information in a structured way in your favorite spreadsheet editor.

You can also set the environment variable C<DEVEL_MOJOPROF_OUT_CSV> to a given
file or give it a special value "1", which will generate a file in the current
directory for you, with the filename "devel-mojoprof-reporter-1548746277.csv",
where "1548746277" will be the unix timestamp of when you started the run.

=head1 METHODS

=head2 report

  $reporter->report(\%report);

Will be called every time a meassurement has been done by L<Devel::MojoProf>.

The C<%report> variable contains the following example information:

  {
    file    => "path/to/app.pl",
    line    => 23,
    class   => "Mojo::Pg::Database",
    method  => "query_p",
    t0      => [Time::HiRes::gettimeofday],
    elapsed => Time::HiRes::tv_interval($report->{t0}),
    message => "SELECT 1 as whatever",
  }

The C<%report> above will print the following line to STDERR:

  0.00038ms [Mojo::Pg::Database::query_p] SELECT 1 as whatever at path/to/app.pl line 23

The log format is currently EXPERIMENTAL and could be changed.

Note that the C<file> and C<line> keys can be disabled by setting the
C<DEVEL_MOJOPROF_CALLER> environment variable to "0". This can be useful to
speed up the run of the program.

=head1 SEE ALSO

L<Devel::MojoProf>.

=cut
