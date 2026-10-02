package Test::ToolLoop;
# Runs the three MCP tool loops -- Langertha::Role::Tools::chat_with_tools_f and
# Langertha::Chat's simple_chat_with_tools_f / simple_chat_with_tools -- over
# the same canned wire bodies, so a test can hold all three to one behavior.
# The async loops get a Test::MockAsyncHTTP, the sync loop a queue-backed
# LWP::UserAgent; both record the requests sent. Warnings are captured.

use strict;
use warnings;

use Exporter 'import';
use HTTP::Response;
use JSON::MaybeXS;
use Test::MockAsyncHTTP;
use Langertha::Chat;

our @EXPORT_OK = qw( http_for run_loop loop_names strip_location );

{
  package Test::ToolLoop::UA;
  our @ISA = ('LWP::UserAgent');
  sub new {
    my ( $class, @responses ) = @_;
    my $self = $class->SUPER::new;
    $self->{queue}    = [@responses];
    $self->{requests} = [];
    return $self;
  }
  sub request {
    my ( $self, $request ) = @_;
    push @{ $self->{requests} }, $request;
    my $response = shift @{ $self->{queue} };
    die "Test::ToolLoop::UA: no canned response left\n" unless $response;
    return $response;
  }
  sub requests { @{ $_[0]{requests} } }
}

sub loop_names { qw( chat_with_tools_f simple_chat_with_tools_f simple_chat_with_tools ) }

sub http_for {
  my ( $body ) = @_;
  my $raw = ref $body ? encode_json($body) : $body;
  return HTTP::Response->new( 200, 'OK', [ 'Content-Type' => 'application/json' ], $raw );
}

sub strip_location {
  my ( $err ) = @_;
  return $err unless defined $err;
  $err =~ s/ at \S+ line \d+\.?\n?\z//;
  return $err;
}

# run_loop( $loop,
#   engine  => sub { Engine->new( @_ ) },  # @_ carries the transport
#   bodies  => [ $wire_body, ... ],        # one per turn
#   servers => [ $mcp, ... ],
#   plugins => [ ... ],                    # optional, Langertha::Chat loops only
# )
# Returns { ok => $text } or { died => $error }, plus warnings => [...] and
# requests => [ decoded request bodies ].
sub run_loop {
  my ( $loop, %args ) = @_;
  my @http = map { http_for($_) } @{ $args{bodies} };
  my @warnings;
  local $SIG{__WARN__} = sub { push @warnings, $_[0] };
  my @plugins = $args{plugins} ? ( plugins => $args{plugins} ) : ();
  my ( $transport, $result );
  my $ok = eval {
    # The engine's own loop fires no plugin hooks; a plugin test there would
    # pass for the wrong reason.
    die "Test::ToolLoop: plugins apply to the Langertha::Chat loops only\n"
      if @plugins && $loop eq 'chat_with_tools_f';
    if ( $loop eq 'chat_with_tools_f' ) {
      $transport = Test::MockAsyncHTTP->new( responses => \@http );
      $result = $args{engine}->( _async_http => $transport, mcp_servers => $args{servers} )
        ->chat_with_tools_f('hi')->get;
    }
    elsif ( $loop eq 'simple_chat_with_tools_f' ) {
      $transport = Test::MockAsyncHTTP->new( responses => \@http );
      $result = Langertha::Chat->new( engine => $args{engine}->( _async_http => $transport ),
        mcp_servers => $args{servers}, @plugins )->simple_chat_with_tools_f('hi')->get;
    }
    elsif ( $loop eq 'simple_chat_with_tools' ) {
      $transport = Test::ToolLoop::UA->new(@http);
      $result = Langertha::Chat->new( engine => $args{engine}->( user_agent => $transport ),
        mcp_servers => $args{servers}, @plugins )->simple_chat_with_tools('hi');
    }
    else { die "unknown loop $loop" }
    1;
  };
  my %out = $ok ? ( ok => $result ) : ( died => strip_location($@) );
  $out{warnings} = \@warnings;
  $out{requests} = [ map { decode_json( $_->content ) } $transport ? $transport->requests : () ];
  return \%out;
}

1;
