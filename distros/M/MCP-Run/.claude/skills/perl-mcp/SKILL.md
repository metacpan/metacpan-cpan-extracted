---
name: perl-mcp
description: MCP (Model Context Protocol) server development in Perl — tool definition, server setup, integration with Langertha
---

<oneliner>
Build MCP servers in Perl using MCP::Server with $server->tool() for tool registration. Handler signature: sub ($self, $args) where $self is MCP::Tool. Return via $self->text_result().
</oneliner>

<server-setup>
## MCP Server Setup

```perl
use MCP::Server;

my $server = MCP::Server->new(
    name    => 'my-server',
    version => '1.0',
);
```
</server-setup>

<tool-definition>
## Tool Definition

```perl
$server->tool(
    name        => 'tool_name',
    description => 'Clear description of what this tool does and when to use it.',
    input_schema => {
        type       => 'object',
        properties => {
            required_param => {
                type        => 'string',
                description => 'What this parameter is for',
            },
            optional_param => {
                type        => 'number',
                description => 'Optional numeric value',
            },
        },
        required => ['required_param'],
    },
    code => sub {
        my ($self, $args) = @_;
        # $self = MCP::Tool instance (NOT your server class)
        # $args = parsed JSON arguments hash

        my $result = process($args->{required_param});

        return $self->text_result($result);        # Success
        return $self->text_result($error_msg, 1);  # Error (is_error=1)
    },
);
```

### Critical API Notes

- **Handler signature:** `sub ($self, $args)` — `$self` is `MCP::Tool`, NOT `MCP::Server`
- **Return method:** `$self->text_result("text")` — instance method, NOT class method
- **Error flag:** `$self->text_result("error message", 1)` — second arg `1` = is_error
- **Registration:** `$server->tool(...)` — NOT `$server->add_tool()` or `handler`
- **Input schema:** Standard JSON Schema format
</tool-definition>

<common-patterns>
## Common Tool Patterns

### CRUD Tool Set

```perl
# List
$server->tool(
    name => 'list_items',
    description => 'List all items, optionally filtered',
    input_schema => {
        type => 'object',
        properties => {
            filter => { type => 'string', description => 'Optional filter' },
        },
    },
    code => sub {
        my ($self, $args) = @_;
        my @items = get_items($args->{filter});
        return $self->text_result($json->encode(\@items));
    },
);

# Create
$server->tool(
    name => 'create_item',
    description => 'Create a new item',
    input_schema => {
        type => 'object',
        properties => {
            name => { type => 'string', description => 'Item name' },
            data => { type => 'object', description => 'Item data' },
        },
        required => ['name'],
    },
    code => sub {
        my ($self, $args) = @_;
        my $item = eval { create_item($args->{name}, $args->{data}) };
        return $self->text_result("Failed: $@", 1) if $@;
        return $self->text_result($json->encode($item));
    },
);
```

### K8s Integration (HI Pattern)

```perl
$server->tool(
    name => 'list_pods',
    description => 'List pods in a namespace',
    input_schema => {
        type => 'object',
        properties => {
            namespace => { type => 'string', description => 'K8s namespace' },
        },
        required => ['namespace'],
    },
    code => sub {
        my ($self, $args) = @_;
        my $pods = eval {
            $k8s->api->list('Pod', namespace => $args->{namespace});
        };
        return $self->text_result("K8s error: $@", 1) if $@;

        my @summary = map {
            { name => $_->metadata->name, status => $_->status->phase }
        } @{ $pods->items };

        return $self->text_result($json->encode(\@summary));
    },
);
```

### DB Integration

```perl
$server->tool(
    name => 'query_data',
    description => 'Query records from a table',
    input_schema => {
        type => 'object',
        properties => {
            table  => { type => 'string', description => 'Table name' },
            filter => { type => 'object', description => 'WHERE conditions' },
        },
        required => ['table'],
    },
    code => sub {
        my ($self, $args) = @_;
        my $rs = eval { $db->resultset($args->{table}) };
        return $self->text_result("Unknown table: $args->{table}", 1) unless $rs;

        my @rows = $rs->search($args->{filter} // {})->all;
        my @data = map { { $_->get_columns } } @rows;
        return $self->text_result($json->encode(\@data));
    },
);
```
</common-patterns>

<async-integration>
## Async Integration with Langertha

```perl
use IO::Async::Loop;
use Net::Async::MCP;
use MCP::Server;
use Langertha::Engine::Anthropic;
use Langertha::Raider;
use Future::AsyncAwait;

# 1. Create server with tools
my $server = MCP::Server->new(name => 'demo', version => '1.0');
$server->tool(name => 'add', ...);

# 2. Wrap in async MCP client
my $loop = IO::Async::Loop->new;
my $mcp = Net::Async::MCP->new(server => $server);
$loop->add($mcp);

async sub main {
    await $mcp->initialize;

    # 3. Create engine with MCP
    my $engine = Langertha::Engine::Anthropic->new(
        api_key     => $ENV{ANTHROPIC_API_KEY},
        model       => 'claude-sonnet-4-6',
        mcp_servers => [$mcp],
    );

    # 4a. One-shot tool calling
    my $response = await $engine->chat_with_tools_f('Add 42 and 17');

    # 4b. Or Raider for multi-turn
    my $raider = Langertha::Raider->new(
        engine         => $engine,
        mission        => 'You are a calculator.',
        max_iterations => 10,
    );
    my $result = await $raider->raid_f('Add 42 and 17');
}

main()->get;
```
</async-integration>

<tool-description-tips>
## Writing Good Tool Descriptions

```perl
# BAD: Vague
$server->tool(name => 'do_stuff', description => 'Does stuff', ...);

# GOOD: Clear, specific, with usage guidance
$server->tool(
    name        => 'search_documents',
    description => 'Search documents by title or content. Returns matching documents '
                 . 'with their IDs and summaries. Use this when the user asks about '
                 . 'finding or looking up information.',
    input_schema => {
        type => 'object',
        properties => {
            query => {
                type        => 'string',
                description => 'Search query (2-10 words recommended for best results)',
            },
            limit => {
                type        => 'number',
                description => 'Max results to return (default: 10)',
            },
        },
        required => ['query'],
    },
    ...
);
```
</tool-description-tips>
