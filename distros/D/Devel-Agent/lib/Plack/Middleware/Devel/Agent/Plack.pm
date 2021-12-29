package Plack::Middleware::Devel::Agent::Plack;

=head1 NAME

Plack::Middleware::Devel::Agent::Plack - Plack Middleware Agent Debugger

=head1 SYNOPSIS

  PERL5OPT='-d:Agent' plackup --port 8777 -e 'enable "Plack::Middleware::Devel::Agent::Plack";package MyFirstApp;sub {[200,[qw(Content-Type text/plain)],["hello world\n"]]}'

=head1 DESCRIPTION

This debugger is handly for tracing all calls made within a psgi app, while excluding the guts of PSGI/Plack.  Why?  Well most of the time we want to know what is happening in our application, not in the PSGI layer as Plack/PSGI is pretty good at what it does.

=cut

use Modern::Perl;

require Plack::Middleware;
use parent qw( Plack::Middleware );
require Plack::Util;
require Devel::Agent;
use Data::Dumper;
use Devel::Agent::Util qw(flush_row);

=head1 Configuration and env variables

At its core this is a configuration class for the debugger provided by Deve::Agent. As a result it can be programatically configigured at runtime.

=cut

our @EXCLUDE_DEFAULTS=(

  # grab the defaults from the debugger
  @DB::EXCLUDE_DEFAULTS,
  qw(
  Plack::Util::Prototype
  Pack::Util
  Plack::Util::Accessor
  Plack::Component
  Try::Tiny
  HTTP::Message::PSGI
  )
);#,'Plack::Middleware','Plack::Util');
our $VERSION=$Devel::Agent::VERSION;
our %AGENT_OPTIONS=(
  excludes=>{
    map { ($_,1) }  @EXCLUDE_DEFAULTS
  },
  filter_on_args=>\&default_filter,
  on_frame_end=>\&flush_row,
);

our %SELF_EXCLUDES=(
  qw(
    Plack::Util::response_cb 1
    Plack::Util::__ANON__ 1
    Plack::Util::header_remove 1
    Plack::Util::inline_object 1

  ),
  map {
    (__PACKAGE__.'::'.$_,1) } 
    qw(
    _chunk_handler
    _start
    )
);

sub default_filter {
  my ($self,$frame,$args,$caller)=@_;
  if(exists $SELF_EXCLUDES{$frame->{class_method}}) {
    return 0;
  }

  return 1;
}

=head2 ENV Options

=over 4

=item * PSGI_TRACE_EVERY

This is expected to be a number, when set a trace will be implemented every PSGI_TRACE_EVERY number of requests.  If not set the default is 1.

=back

=cut

=head2 Class variables

This section documents the class variables that can be used to programatically confiigure tracing.  They are all accessable as static fully qualified variables via the class path Plack::Middleware::Devel::Agent::Plack

=cut

=over 4

=item * @EXCLUDE_DEFAULTS

This contains the extended default exclusions for plack/psgi

=item * %AGENT_OPTIONS

This contains the options that will be passed to the constructor of the debuger.

Some important notes:

  excludes=>{...}
    # the excludes are defined from an extended list of classes for PSIG/Plack
    # Defaults are defined in @EXCLUDE_DEFAULTS

  filter_on_args=>\&default_filter,
    # this filters out some additional classes defined in: %SELF_EXCLUDES

  on_frame_end=>\&flush_row,
    # this method outputs to STDERR by default
    # it is imported from Devel::Agent::Util
    
=item * $TRACE_EVERY

This represents how often a psgi trace will happen, default is 1.

=cut

our $TRACE_EVERY=$ENV{PSGI_TRACE_EVERY} || 1;
our $ID=0;

=item * $AGENT

This is the debugger instance, it is redefined every time a new trace starts, so make use of it as needed.

See: L<Devel::Agent> for more details

=cut

our $AGENT;

=item * $BEFORE_REQUEST=sub {}

This is a callback that will be run before any requests objects are run, this can be handy if you want to do soemthing special before the debugger starts.

=cut

our $BEFORE_REQUEST=sub {};

=item * $BEFORE_TRACE=sub { my ($AGENT,$ID,$env)=@_ }

This callback is run before the call to $AGENT->start_trace is called, but after $BEFORE_REQUEST->()

=cut

our $BEFORE_TRACE=sub {};

=item * $AFTER_TRACE->($AGENT,$ID,$env,$res)

This is called when the the request has completed and tracing of your application is done.

=back

=cut

our $AFTER_TRACE=sub {};
our $LAST_REQUEST;

sub call {
  my ($self,$env)=@_;
  
  $BEFORE_REQUEST->();
  ++$ID;
  if($ID % $TRACE_EVERY==0) {
    $AGENT=DB->new(%AGENT_OPTIONS);
    $BEFORE_TRACE->($AGENT,$ID,$env);
    $AGENT->start_trace;
  }
  my $res= $self->app->($env);
  $LAST_REQUEST=[$env,$res];

  return Plack::Util::response_cb($res, \&_start);
}

sub _start {
  \&_chunk_handler;
}

sub _chunk_handler {
  
  unless(defined $_[0]) {
    return $_[0] unless defined $AGENT;
    $AGENT->stop_trace;
    $AFTER_TRACE->($AGENT,$ID,$LAST_REQUEST->@*);
    undef $LAST_REQUEST;
  }

  return $_[0];
}

1;

__END__

=head1 AUTHOR

Michael Shipper L<mailto:AKALINUX@CPAN.ORG>

=cut
