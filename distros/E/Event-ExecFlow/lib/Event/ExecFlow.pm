package Event::ExecFlow;

$VERSION = "0.64";

sub import {
    my $class = shift;
    my ($domain) = @_;

    $domain ||= "event.execflow";

    $Event::ExecFlow::locale_textdomain = $domain;

    require Event::ExecFlow::Frontend;
    require Event::ExecFlow::Callbacks;
    require Event::ExecFlow::Job::Command;
    require Event::ExecFlow::Job::Group;
    require Event::ExecFlow::Job::Code;

    1;
}


$Event::ExecFlow::DEBUG = 0;

1;

__END__

=head1 NAME

Event::ExecFlow - High level API for event-based execution flow control

=head1 NOTE

This is release has nearly no documentation yet.
If you're interested in the details please contact the author.

=head1 ABSTRACT

Event::ExecFlow provides a ligh level API for defining complex flow controls with asynchronous execution of external programs.

=head1 SYNOPSIS

  use Event::ExecFlow;

  my $job = Event::ExecFlow::Job::Group->new (
    jobs => [
      Event::ExecFlow::Job::Command->new (
        name            => "transcode",
        title           => "Transcoding DVD title to OGG",
        command         => "transcode -i /dev/dvd ...",
        fetch_output    => 1,
        progress_max    => 4711, # number of frames
        progress_parser => sub {
          my ($job, $buffer) = @_;
          $job->set_progress_cnt($1) if $buffer =~ /\[\d+-(\d+)\]/;
          #-- or simply write this:
          #--   progress_parser => qr/\[\d+-(\d+)\]/,
        },
      ),
      Event::ExecFlow::Job::Code->new (
        name          => "checks",
        title         => "Do some checks",
        depends_on    => [ "transcode" ],
        code          => sub {
          my ($job) = @_;
          my $transcode = $job->get_group->get_job_by_name("transcode");
          if ( $transcode->get_output !~ /.../ ) {
            $job->set_error_message("XY check failed");
          }
          #-- this could be done easier as a post_callback added to
          #-- the "transcode" job above, but it's nevertheless a good
          #-- example for the 'Code' job type and shows how jobs can
          #-- interfere with each other.
        },
      ),
      Event::ExecFlow::Job::Command->new (
        title         => "Muxing OGG file",
        depends_on    => [ "checks" ],
        command       => "ogmmerge ...",
        no_progress   => 1,
      ),
    ],
  );

  #-- this inherits from Event::ExecFlow::Frontend
  my $frontend = Video::DVDRip::GUI::ExecFlow->new(...);
  $frontend->start_job($job);
  
=head1 DESCRIPTION

Event::ExecFlow offers a high level API to declare jobs, which mainly execute external commands, parse their output to get progress or other status information, triggers actions when the command has been finished etc. Such jobs can be chained together in a recursive fashion to fulfill rather complex tasks which consist of many jobs.

Additionally it defines an extensible API for communication with the frontend application, which may be a written using Gtk2, Tk or Qt or is a simple text console program.

In case of Gtk2 a custom widget for displaying an Event::ExecFlow job plan, including progress updates, is shipped with the Gtk2::Ex::FormFactory package.

=head1 REQUIREMENTS

Event::ExecFlow requires the follwing Perl modules:

  AnyEvent           >= 0.04
  Locale::TextDomain
  Test::More

=head1 INSTALLATION

You get the latest installation tarballs and online documentation
at this location:

  http://www.exit1.org/Event-ExecFlow/

If your system meets the requirements mentioned above, installation
is just:

  perl Makefile.PL
  make test
  make install

=head1 AUTHORS

  Jörn Reder <joern at zyn dot de>

=head1 COPYRIGHT AND LICENSE

Copyright 2005-2006 by Jörn Reder.

This library is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

=cut
