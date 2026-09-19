package MCP::Picnic;
# ABSTRACT: MCP Server for Picnic Supermarket API

use Moo;
use MCP::Server;
use WWW::Picnic;
use JSON::MaybeXS;
use Carp qw( croak );
use namespace::clean;

our $VERSION = '0.001';

has user => (
  is      => 'ro',
  lazy    => 1,
  default => sub { $ENV{PICNIC_USER} // croak "PICNIC_USER environment variable required" },
);

has pass => (
  is      => 'ro',
  lazy    => 1,
  default => sub { $ENV{PICNIC_PASS} // croak "PICNIC_PASS environment variable required" },
);

has country => (
  is      => 'ro',
  lazy    => 1,
  default => sub { $ENV{PICNIC_COUNTRY} // 'de' },
);

has picnic => (
  is      => 'ro',
  lazy    => 1,
  builder => '_build_picnic',
);

has json => (
  is      => 'ro',
  lazy    => 1,
  default => sub { JSON::MaybeXS->new(utf8 => 1, canonical => 1, convert_blessed => 1) },
);

has server => (
  is      => 'ro',
  lazy    => 1,
  builder => '_build_server',
);

has _auth_state => (
  is      => 'rw',
  default => sub { 'none' },  # none, pending_2fa, authenticated
);

sub _build_picnic {
  my ($self) = @_;
  return WWW::Picnic->new(
    user    => $self->user,
    pass    => $self->pass,
    country => $self->country,
  );
}

sub _to_json {
  my ($self, $data) = @_;
  return $self->json->encode($data);
}

sub _ensure_auth {
  my ($self) = @_;

  return 1 if $self->_auth_state eq 'authenticated';

  if ($self->_auth_state eq 'pending_2fa') {
    return { error => 1, message => "2FA verification pending. Please provide the SMS code you received using the verify_2fa tool." };
  }

  # Try to login
  my $login = eval { $self->picnic->login };
  if ($@) {
    return { error => 1, message => "Login failed: $@" };
  }

  if ($login->requires_2fa) {
    $self->_auth_state('pending_2fa');
    eval { $self->picnic->generate_2fa_code };
    if ($@) {
      return { error => 1, message => "Could not request 2FA code: $@" };
    }
    return {
      error   => 1,
      message => "2FA required. An SMS with a verification code has been sent to your phone. Please provide the code so it can be verified with the verify_2fa tool."
    };
  }

  $self->_auth_state('authenticated');
  return 1;
}

sub _article_to_hash {
  my ($self, $article) = @_;
  return {
    id            => $article->id,
    name          => $article->name,
    price         => $article->price,
    display_price => $article->display_price,
    unit_quantity => $article->unit_quantity,
    image_id      => $article->image_id,
  };
}

sub _article_detail_to_hash {
  my ($self, $article) = @_;
  return {
    id            => $article->id,
    name          => $article->name,
    price         => $article->price,
    price_info    => $article->price_info,
    description   => $article->description,
    unit_quantity => $article->unit_quantity,
    image_ids     => $article->image_ids,
    labels        => $article->labels,
  };
}

sub _cart_item_to_hash {
  my ($self, $item) = @_;
  return {
    id    => $item->{id},
    name  => $item->{name},
    count => $item->{count},
    price => $item->{price},
  };
}

sub _cart_to_hash {
  my ($self, $cart) = @_;
  return {
    total_count   => $cart->total_count,
    total_price   => $cart->total_price,
    items         => [ map { $self->_cart_item_to_hash($_) } @{ $cart->items } ],
    delivery_slot => $cart->selected_slot,
  };
}

sub _slot_to_hash {
  my ($self, $slot) = @_;
  return {
    slot_id      => $slot->slot_id,
    window_start => $slot->window_start,
    window_end   => $slot->window_end,
    is_available => $slot->is_available,
    minimum_order_value => $slot->minimum_order_value,
  };
}

sub _user_to_hash {
  my ($self, $user) = @_;
  return {
    user_id   => $user->user_id,
    firstname => $user->firstname,
    lastname  => $user->lastname,
    address   => $user->address,
    phone     => $user->phone,
  };
}

sub _suggestion_to_hash {
  my ($self, $suggestion) = @_;
  return {
    suggestion => $suggestion->{suggestion},
    type       => $suggestion->{type},
  };
}

sub _category_to_hash {
  my ($self, $category) = @_;
  return {
    id    => $category->{id},
    name  => $category->{name},
    type  => $category->{type},
    level => $category->{level},
  };
}

sub _build_server {
  my ($self) = @_;

  my $server = MCP::Server->new(
    name    => 'Picnic',
    version => $VERSION,
  );

  # Tool: verify_2fa
  $server->tool(
    name        => 'verify_2fa',
    description => 'Verify the 2FA code sent via SMS. Use this after the user has provided the code.',
    input_schema => {
      type       => 'object',
      properties => {
        code => {
          type        => 'string',
          description => 'The 6-digit code from the SMS',
        },
      },
      required => ['code'],
    },
    code => sub {
      my ($tool, $args) = @_;

      unless ($self->_auth_state eq 'pending_2fa') {
        return $tool->text_result("No 2FA verification pending. Login happens automatically when needed.");
      }

      my $result = eval { $self->picnic->verify_2fa_code($args->{code}) };
      if ($@) {
        return $tool->text_result("2FA verification failed: $@", 1);
      }

      $self->_auth_state('authenticated');
      return $tool->text_result("Successfully verified! You can now use all Picnic features.");
    },
  );

  # Tool: search_products
  $server->tool(
    name        => 'search_products',
    description => 'Search for products in the Picnic supermarket. Returns products with name, price and ID.',
    input_schema => {
      type       => 'object',
      properties => {
        query => {
          type        => 'string',
          description => 'Search term (e.g. "milk", "Haribo", "organic eggs")',
        },
      },
      required => ['query'],
    },
    code => sub {
      my ($tool, $args) = @_;

      my $auth = $self->_ensure_auth;
      return $tool->text_result($auth->{message}, 1) if ref $auth && $auth->{error};

      my $results = eval { $self->picnic->search($args->{query}) };
      return $tool->text_result("Search failed: $@", 1) if $@;

      my @items = map { $self->_article_to_hash($_) } $results->all_items;
      return $tool->text_result("No products found for '$args->{query}'") unless @items;

      return $tool->text_result($self->_to_json(\@items));
    },
  );

  # Tool: get_product_details
  $server->tool(
    name        => 'get_product_details',
    description => 'Get detailed information about a product by its ID.',
    input_schema => {
      type       => 'object',
      properties => {
        product_id => {
          type        => 'string',
          description => 'The product ID (from search)',
        },
      },
      required => ['product_id'],
    },
    code => sub {
      my ($tool, $args) = @_;

      my $auth = $self->_ensure_auth;
      return $tool->text_result($auth->{message}, 1) if ref $auth && $auth->{error};

      my $article = eval { $self->picnic->get_article($args->{product_id}) };
      return $tool->text_result("Product not found: $@", 1) if $@;

      return $tool->text_result($self->_to_json($self->_article_detail_to_hash($article)));
    },
  );

  # Tool: get_suggestions
  $server->tool(
    name        => 'get_suggestions',
    description => 'Get search suggestions for a partial search term.',
    input_schema => {
      type       => 'object',
      properties => {
        term => {
          type        => 'string',
          description => 'Partial search term (e.g. "mil" for milk suggestions)',
        },
      },
      required => ['term'],
    },
    code => sub {
      my ($tool, $args) = @_;

      my $auth = $self->_ensure_auth;
      return $tool->text_result($auth->{message}, 1) if ref $auth && $auth->{error};

      my $suggestions = eval { $self->picnic->get_suggestions($args->{term}) };
      return $tool->text_result("Suggestions failed: $@", 1) if $@;

      my @suggestions = map { $self->_suggestion_to_hash($_) } $suggestions->all_suggestions;
      return $tool->text_result($self->_to_json(\@suggestions));
    },
  );

  # Tool: get_cart
  $server->tool(
    name        => 'get_cart',
    description => 'Show the current cart with all items, total price and selected delivery slot.',
    input_schema => {
      type       => 'object',
      properties => {},
    },
    code => sub {
      my ($tool, $args) = @_;

      my $auth = $self->_ensure_auth;
      return $tool->text_result($auth->{message}, 1) if ref $auth && $auth->{error};

      my $cart = eval { $self->picnic->get_cart };
      return $tool->text_result("Could not load cart: $@", 1) if $@;

      return $tool->text_result($self->_to_json($self->_cart_to_hash($cart)));
    },
  );

  # Tool: add_to_cart
  $server->tool(
    name        => 'add_to_cart',
    description => 'Add a product to the cart.',
    input_schema => {
      type       => 'object',
      properties => {
        product_id => {
          type        => 'string',
          description => 'The product ID',
        },
        count => {
          type        => 'integer',
          description => 'Quantity (default: 1)',
          default     => 1,
        },
      },
      required => ['product_id'],
    },
    code => sub {
      my ($tool, $args) = @_;

      my $auth = $self->_ensure_auth;
      return $tool->text_result($auth->{message}, 1) if ref $auth && $auth->{error};

      my $count = $args->{count} // 1;
      my $cart = eval { $self->picnic->add_to_cart($args->{product_id}, $count) };
      return $tool->text_result("Could not add to cart: $@", 1) if $@;

      return $tool->text_result($self->_to_json({
        message => "Product added ($count x)",
        cart    => $self->_cart_to_hash($cart),
      }));
    },
  );

  # Tool: remove_from_cart
  $server->tool(
    name        => 'remove_from_cart',
    description => 'Remove a product from the cart.',
    input_schema => {
      type       => 'object',
      properties => {
        product_id => {
          type        => 'string',
          description => 'The product ID',
        },
        count => {
          type        => 'integer',
          description => 'Quantity to remove (default: 1)',
          default     => 1,
        },
      },
      required => ['product_id'],
    },
    code => sub {
      my ($tool, $args) = @_;

      my $auth = $self->_ensure_auth;
      return $tool->text_result($auth->{message}, 1) if ref $auth && $auth->{error};

      my $count = $args->{count} // 1;
      my $cart = eval { $self->picnic->remove_from_cart($args->{product_id}, $count) };
      return $tool->text_result("Could not remove from cart: $@", 1) if $@;

      return $tool->text_result($self->_to_json({
        message => "Product removed ($count x)",
        cart    => $self->_cart_to_hash($cart),
      }));
    },
  );

  # Tool: clear_cart
  $server->tool(
    name        => 'clear_cart',
    description => 'Empty the entire cart.',
    input_schema => {
      type       => 'object',
      properties => {},
    },
    code => sub {
      my ($tool, $args) = @_;

      my $auth = $self->_ensure_auth;
      return $tool->text_result($auth->{message}, 1) if ref $auth && $auth->{error};

      my $cart = eval { $self->picnic->clear_cart };
      return $tool->text_result("Could not clear cart: $@", 1) if $@;

      return $tool->text_result("Cart cleared!");
    },
  );

  # Tool: get_delivery_slots
  $server->tool(
    name        => 'get_delivery_slots',
    description => 'Show available delivery time windows.',
    input_schema => {
      type       => 'object',
      properties => {},
    },
    code => sub {
      my ($tool, $args) = @_;

      my $auth = $self->_ensure_auth;
      return $tool->text_result($auth->{message}, 1) if ref $auth && $auth->{error};

      my $slots = eval { $self->picnic->get_delivery_slots };
      return $tool->text_result("Could not load delivery slots: $@", 1) if $@;

      my @available = map { $self->_slot_to_hash($_) } $slots->available_slots;
      return $tool->text_result("No available delivery slots") unless @available;

      return $tool->text_result($self->_to_json(\@available));
    },
  );

  # Tool: set_delivery_slot
  $server->tool(
    name        => 'set_delivery_slot',
    description => 'Select a delivery slot for the order.',
    input_schema => {
      type       => 'object',
      properties => {
        slot_id => {
          type        => 'string',
          description => 'The slot ID (from get_delivery_slots)',
        },
      },
      required => ['slot_id'],
    },
    code => sub {
      my ($tool, $args) = @_;

      my $auth = $self->_ensure_auth;
      return $tool->text_result($auth->{message}, 1) if ref $auth && $auth->{error};

      my $cart = eval { $self->picnic->set_delivery_slot($args->{slot_id}) };
      return $tool->text_result("Could not set delivery slot: $@", 1) if $@;

      return $tool->text_result($self->_to_json({
        message => "Delivery slot selected!",
        cart    => $self->_cart_to_hash($cart),
      }));
    },
  );

  # Tool: get_user
  $server->tool(
    name        => 'get_user',
    description => 'Show information about the logged-in user (name, address, etc.).',
    input_schema => {
      type       => 'object',
      properties => {},
    },
    code => sub {
      my ($tool, $args) = @_;

      my $auth = $self->_ensure_auth;
      return $tool->text_result($auth->{message}, 1) if ref $auth && $auth->{error};

      my $user = eval { $self->picnic->get_user };
      return $tool->text_result("Could not load user info: $@", 1) if $@;

      return $tool->text_result($self->_to_json($self->_user_to_hash($user)));
    },
  );

  # Tool: get_categories
  $server->tool(
    name        => 'get_categories',
    description => 'Show the shop\'s product categories.',
    input_schema => {
      type       => 'object',
      properties => {
        depth => {
          type        => 'integer',
          description => 'Category depth (0 = top-level categories only)',
          default     => 0,
        },
      },
    },
    code => sub {
      my ($tool, $args) = @_;

      my $auth = $self->_ensure_auth;
      return $tool->text_result($auth->{message}, 1) if ref $auth && $auth->{error};

      my $depth = $args->{depth} // 0;
      my $categories = eval { $self->picnic->get_categories($depth) };
      return $tool->text_result("Could not load categories: $@", 1) if $@;

      my @categories = map { $self->_category_to_hash($_) } $categories->all_categories;
      return $tool->text_result($self->_to_json(\@categories));
    },
  );

  return $server;
}

sub run_stdio {
  my ($self) = @_;
  $self = $self->new unless ref $self;
  $self->server->to_stdio;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MCP::Picnic - MCP Server for Picnic Supermarket API

=head1 VERSION

version 0.001

=head1 SYNOPSIS

  # As a stdio MCP server (for Claude Desktop, etc.)
  use MCP::Picnic;
  MCP::Picnic->run_stdio;

  # Or with the bundled script:
  # mcp-picnic

  # Set the environment variables:
  export PICNIC_USER="you@email.de"
  export PICNIC_PASS="your-password"
  export PICNIC_COUNTRY="de"  # or "nl"

=head1 DESCRIPTION

MCP::Picnic provides an MCP (Model Context Protocol) server that gives AI
assistants such as Claude access to the Picnic supermarket API.

The server supports:

=over 4

=item * Product search

=item * Cart management (add, remove, clear)

=item * Viewing and selecting delivery time windows

=item * Viewing the user profile

=item * 2FA authentication (interactive, driven through the AI assistant)

=back

=head1 2FA AUTHENTICATION

Picnic often requires two-factor authentication via SMS. The MCP server
handles this interactively:

=over 4

=item 1. On the first request, a login is attempted automatically.

=item 2. If 2FA is required, an SMS is sent to your phone number.

=item 3. The AI assistant asks you for the code.

=item 4. You provide the code and the assistant verifies it.

=item 5. All further requests work normally.

=back

=head1 CLAUDE DESKTOP INTEGRATION

Add the following to your Claude Desktop MCP configuration:

  {
    "mcpServers": {
      "picnic": {
        "command": "mcp-picnic",
        "env": {
          "PICNIC_USER": "you@email.de",
          "PICNIC_PASS": "your-password",
          "PICNIC_COUNTRY": "de"
        }
      }
    }
  }

=head1 AVAILABLE TOOLS

=head2 verify_2fa

Verifies the 2FA SMS code.

B<Parameter:> C<code> (string, required)

=head2 search_products

Searches for products.

B<Parameter:> C<query> (string, required)

=head2 get_product_details

Gets details for a product.

B<Parameter:> C<product_id> (string, required)

=head2 get_suggestions

Gets search suggestions.

B<Parameter:> C<term> (string, required)

=head2 get_cart

Shows the current cart.

=head2 add_to_cart

Adds a product to the cart.

B<Parameter:> C<product_id> (string, required), C<count> (integer, default: 1)

=head2 remove_from_cart

Removes a product from the cart.

B<Parameter:> C<product_id> (string, required), C<count> (integer, default: 1)

=head2 clear_cart

Clears the cart.

=head2 get_delivery_slots

Shows available delivery time windows.

=head2 set_delivery_slot

Selects a delivery slot.

B<Parameter:> C<slot_id> (string, required)

=head2 get_user

Shows user information.

=head2 get_categories

Shows product categories.

B<Parameter:> C<depth> (integer, default: 0)

=head1 SEE ALSO

L<MCP::Server>, L<WWW::Picnic>

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/p5-mcp-picnic/issues>.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <torsten@raudss.us>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
