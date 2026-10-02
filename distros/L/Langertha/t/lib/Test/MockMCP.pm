package Test::MockMCP;
# Lightweight duck-typed MCP client for tests. Implements exactly the surface
# that Langertha::Role::Tools (chat_with_tools_f) and Langertha::Chat call on
# mcp_servers entries -- initialize, list_tools, call_tool -- without pulling in
# Net::Async::MCP or MCP::Server. It replaces Langertha::MCP::Client, which was
# extracted to the langertha-raider distribution.
#
# Tool specs mirror MCP::Server->tool: { name, description, input_schema, code }.
# The code sub is called as $code->($tool, $args) where $tool is this mock, so
# existing `sub { my ($self, $args) = @_; $self->text_result(...) }` bodies work
# unchanged. list_tools emits camelCase inputSchema like a real MCP server, so
# Langertha::Tool->from_hash auto-detects the MCP shape.

use strict;
use warnings;

use Future;

sub new {
  my ( $class, %args ) = @_;
  my @order;
  my %tools;
  for my $tool ( @{ $args{tools} // [] } ) {
    push @order, $tool->{name};
    $tools{ $tool->{name} } = $tool;
  }
  return bless { tools => \%tools, order => \@order }, $class;
}

sub initialize { return Future->done(1) }

sub list_tools {
  my ( $self ) = @_;
  return Future->done( [
    map {
      my $tool = $self->{tools}{$_};
      { name        => $tool->{name},
        description => $tool->{description},
        inputSchema => $tool->{input_schema} }
    } @{ $self->{order} }
  ] );
}

sub call_tool {
  my ( $self, $name, $args ) = @_;
  my $tool = $self->{tools}{$name}
    or return Future->fail("Tool '$name' not found");
  return Future->done( $tool->{code}->( $self, $args // {} ) );
}

sub text_result {
  my ( $self, $text, $is_error ) = @_;
  my %result = ( content => [ { type => 'text', text => "$text" } ] );
  $result{isError} = 1 if $is_error;
  return \%result;
}

1;
