package Test::Message;

use DateTime;
use Test::Deep;
use Test::Exception;
use Test::Roo::Role;

test 'simple message tests' => sub {

    my $self = shift;

    # fixtures
    $self->message_types;

    my $schema = $self->ic6s_schema;

    my ( $data, $result, $rset );

    my $rset_message = $schema->resultset('Message');

    my $author   = $self->users->find( { username => 'customer1' } );
    my $approver = $self->users->find( { username => 'admin1' } );

    $data = {};

    cmp_ok( $rset_message->count, '==', 0, "We have zero messages" );

    throws_ok( sub { $result = $rset_message->create($data) },
        qr/.*/, "fail message create empty data" );

    $data->{title} = "Message title";

    throws_ok( sub { $result = $rset_message->create($data) },
        qr/.*/, "fail message missing required field" );

    $data->{content} = "Message content";
    $data->{type} = "blog_post";

    lives_ok( sub { $result = $rset_message->create($data) },
        "Message OK with title, content and type" );

    cmp_ok( $rset_message->count, '==', 1, "We have one message" );
    lives_ok( sub { $result->delete }, "delete message" );
    cmp_ok( $rset_message->count, '==', 0, "We have zero messages" );

    throws_ok {
        $rset_message->create(
            {
                content          => "the content",
                title            => "the title",
                message_types_id => 8768768
            }
          )
    }
    qr/message_types_id value does not exist in MessageType/,
      "insert with non-existant message_types_id fails";

    lives_ok( sub { $result = $schema->resultset('MessageType')->find({
                    name => 'blog_post' })}, "find blog_post MessageType" );

    ok( $result->active, "blog_post type is active" );

    lives_ok( sub { $result->update({ active => 0 }) }, "change to inactive" );

    ok( !$result->active, "blog_post type is not active" );

    throws_ok( sub { $result = $rset_message->create($data) },
        qr/"blog_post" is not active/,
        "fail to create blog_post" );

    cmp_ok( $rset_message->count, '==', 0, "We have zero messages" );

    lives_ok( sub { $result->update({ active => 1 }) }, "change to active" );


  SKIP: {
        skip "SQLite does not check varchar length", 1
          if $schema->storage->sqlt_type eq "SQLite";

        $data->{uri} = "x" x 300;

        throws_ok( sub { $result = $rset_message->create($data) },
            qr/.*/, "fail with uri > 255 chars" );
        cmp_ok( $rset_message->count, '==', 0, "We have zero messages" );
    }

    $data->{uri} = "some-nice-uri-for-this-message";

    lives_ok( sub { $result = $rset_message->create($data) }, "Add uri" );

    cmp_ok( $rset_message->count, '==', 1, "We have one message" );
    lives_ok( sub { $result->delete }, "delete message" );
    cmp_ok( $rset_message->count, '==', 0, "We have zero messages" );

    $data->{author_users_id} = 333333;

    throws_ok( sub { $result = $rset_message->create($data) },
        qr/.*/, "FK error with bad user" );

    delete $data->{author_users_id};

    $data->{approved_by_users_id} = 333333;

    throws_ok( sub { $result = $rset_message->create($data) },
        qr/.*/, "FK error with bad approved_by" );

    delete $data->{approved_by_users_id};

    $data->{author_users_id}      = $author->id;
    $data->{approved_by_users_id} = $approver->id;

    lives_ok( sub { $result = $rset_message->create($data) },
        "add good author and approved_by" );

    cmp_ok( $rset_message->count, '==', 1, "We have one message" );

    cmp_ok( $result->author->id, '==', $author->id, "has correct author" );
    cmp_ok( $result->author->email, 'eq', $author->email, "has correct author" );
    cmp_ok( $result->message_type->name, 'eq', 'blog_post', "is a blog_post" );

    cmp_ok( $result->approved_by->id,
        '==', $approver->id, "has correct approver" );

    my $blog_posts = $result->author->blog_posts;
    cmp_ok $blog_posts->count, '==', 1, "author->blog_posts->count == 1";

    my $dt = DateTime->now;
    cmp_ok( $result->created,       '<=', $dt, "created is <= now" );
    cmp_ok( $result->last_modified, '<=', $dt, "last_modified is <= now" );

    $dt->subtract( minutes => 2 );
    cmp_ok( $result->created,       '>=', $dt, "created in last 2 mins" );
    cmp_ok( $result->last_modified, '>=', $dt, "last_modified in last 2 mins" );

    cmp_deeply(
        $result,
        methods(
            title   => "Message title",
            uri     => "some-nice-uri-for-this-message",
            content => "Message content",
        ),
        "title, uri & content OK"
    );

    lives_ok( sub { $result->delete }, "delete message" );

    $data = {
        content => "the content",
        type    => "blog_post",
        message_types_id =>
          $self->message_types->find( { name => "order_comment" } )->id,
    };
    throws_ok { $result = $rset_message->create($data) }
    qr/mismatched type settings/, "fail mismatched type settings";

    $data = {
        content => "the content",
        type    => "XX_no_such_type",
    };
    throws_ok { $result = $rset_message->create($data) }
    qr/MessageType.+does not exist/, "fail bad type";

    $data = {
        content => "the content",
        type    => "blog_post",
        message_types_id =>
          $self->message_types->find( { name => "order_comment" } )->id,
    };
    throws_ok { $result = $rset_message->create($data) }
    qr/mismatched type settings/, "fail mismatched type settings";

    $data = {
        content => "the content",
        type    => "blog_post",
        message_types_id =>
          $self->message_types->find( { name => "blog_post" } )->id,
    };
    lives_ok { $result = $rset_message->create($data) }
    "Create message with match type and message_types_id";

    lives_ok { $result->delete } "delete message";

    $data = {
        content => "the content",
        type    => "XX_no_such_type",
    };
    throws_ok { $result = $rset_message->create($data) }
    qr/MessageType.+does not exist/, "fail bad type";

    cmp_ok( $rset_message->count, '==', 0, "We have zero messages" );
};

test 'order comments tests' => sub {
    my $self = shift;

    # fixtures - make sure we have a clean set of addresses & users
    $self->clear_addresses;
    $self->clear_users;
    $self->users;
    $self->addresses;
    $self->message_types;

    my $schema = $self->ic6s_schema;

    my $rset_message = $schema->resultset('Message');
    my $rset_order_comment = $schema->resultset('OrderComment');

    my ( $user, $billing_address, $shipping_address, $order, $data, $result,
        $rset );

    # first we need an adddress and order that we can attach comments to

    my $dt = DateTime->now;

    lives_ok( sub { $user = $self->users->find( { username => 'customer1' } ) },
        "select author from User" );

    cmp_ok( $user->id, '>=', 1, "Check we have a user" );

    lives_ok(
        sub {
            $billing_address =
              $user->search_related( 'addresses', { type => 'billing' } )
              ->first;
        },
        "Find billing address"
    );

    cmp_ok( $billing_address->id, '>=', 1, "Check we have a billing_address" );

    lives_ok(
        sub {
            $shipping_address =
              $user->search_related( 'addresses', { type => 'shipping' } )
              ->first;
        },
        "Find shipping address"
    );

    cmp_ok( $shipping_address->id, '>=', 1, "Check we have a shipping_address" );

    my $shipping_address_id = $shipping_address->id;
    my $billing_address_id  = $billing_address->id;

    $data = {
        order_number          => '1234',
        order_date            => $dt,
        users_id              => $user->users_id,
        email                 => $user->email,
        shipping_addresses_id => $shipping_address_id,
        billing_addresses_id  => $billing_address_id,
    };

    lives_ok( sub { $order = $schema->resultset('Order')->create($data) },
        "Create order" );

    cmp_ok( $schema->resultset('Order')->count, "==", 1, "We have 1 order" );

    throws_ok { $order->set_comments }
    qr/set_comments needs a list of objects or hashrefs/,
      "Fail set_comments with no args";

    lives_ok {
        $result = $schema->resultset('Message')->create(
            {
                type    => "order_comment",
                title   => "some other title",
                content => "some comment as well"
            }
          )
    }
    "Create a Message with type order_comment";

    lives_ok( sub { $order->set_comments($result) },
        "Add comment to order using set_comments(object)" );

    cmp_ok( $schema->resultset('Order')->count, "==", 1, "We have 1 order" );
    cmp_ok( $rset_message->count, '==', 1, "1 Message row" );

    $data = {
        title           => "Initial order comment",
        content         => "Please deliver to my neighbour if I am not at home",
        author_users_id => $user->id,
    };

    lives_ok( sub { $order->set_comments($data) },
        "Add comment to order using set_comments" );

    $data = [
        {
            title   => "Initial order comment",
            content => "Please deliver to my neighbour if I am not at home",
            author_users_id => $user->id,
        },
        {
            title   => "Anoter order comment",
            content => "otherwise the dog will eat it",
            author_users_id => $user->id,
        },
    ];

    lives_ok( sub { $order->set_comments($data) },
        "Add comment to order using set_comments(array_reference)" );

    cmp_ok( $schema->resultset('Order')->count, "==", 1, "We have 1 order" );
    cmp_ok( $rset_message->count, '==', 2, "2 Message rows" );
    cmp_ok( $rset_order_comment->count, '==', 2, "2 OrderComment rows" );

    lives_ok( sub { $order->set_comments($data) },
        "repeat set_comments" );

    cmp_ok( $schema->resultset('Order')->count, "==", 1, "We have 1 order" );
    cmp_ok( $rset_message->count, '==', 2, "2 Message rows" );
    cmp_ok( $rset_order_comment->count, '==', 2, "2 OrderComment rows" );

    lives_ok(
        sub {
            $result = $order->add_to_comments(
                { title => "order response", content => "OK will do!" } );
        },
        "Add another message"
    );

    isa_ok( $result, "Interchange6::Schema::Result::Message" );

    $rset = $order->order_comments;

    lives_ok( sub { $rset = $order->search_related("order_comments") },
        "Search for comments on order" );

    cmp_ok( $rset->count, "==", 3, "Found 3 order comments" );

    lives_ok( sub { $result = $schema->resultset('MessageType')->find({
                    name => 'order_comment' })}, "find order_comment MessageType" );

    ok( $result->active, "order_comment type is active" );

    lives_ok( sub { $result->update({ active => 0 }) }, "change to inactive" );

    ok( !$result->active, "order_comment type is not active" );

    lives_ok( sub { $rset = $order->search_related("order_comments") },
        "Search for comments on order" );

    cmp_ok( $rset->count, "==", 3, "Found 3 order comments" );

    throws_ok(
        sub {
            $result = $order->add_to_comments(
                { title => "order response", content => "frizzzzz" } );
        },
        qr/"order_comment" is not active/,
        "fail to create order_comment" );

    lives_ok( sub { $result->update({ active => 1 }) }, "change to active" );

    throws_ok { $order->add_to_comments }
    qr/add_to_comments needs an object or hashref/,
      "add_to_comments fails with no args";

    lives_ok {
        $order->add_to_comments(
            title   => "order response",
            content => "frizzzzz"
          )
    }
    "add_to_comments args are array";

    lives_ok {
        $result = $schema->resultset('Message')->create(
            {
                type    => "order_comment",
                title   => "some other title",
                content => "some comment as well"
            }
          )
    }
    "Create a Message with type order_comment";

    lives_ok { $order->add_to_comments($result) }
    "Add message object to order using add_to_comments";

    lives_ok {
        $result = $schema->resultset('Message')->create(
            {
                type    => "blog_post",
                title   => "some other title",
                content => "some comment as well"
            }
          )
    }
    "Create a Message with type blog_post";

    throws_ok { $order->add_to_comments($result) } qr/cannot add message type/,
    "Fail to add message object to order using add_to_comments";

    lives_ok { $result->delete } "delete blog_post";

    lives_ok( sub { $order->delete }, "Delete order" );

    cmp_ok( $schema->resultset("Order")->count, "==", 0, "Zero orders" );

    cmp_ok( $schema->resultset("OrderComment")->count,
        "==", 0, "Zero order comments" );

    cmp_ok( $schema->resultset("Message")->count, "==", 0, "Zero messages" );

    # now make use of convenience accessors in ::Base::Message

    $data = {
        order_number          => '1234',
        order_date            => $dt,
        users_id              => $user->id,
        email                 => $user->email,
        shipping_addresses_id => $shipping_address->id,
        billing_addresses_id  => $billing_address->id,
        order_comments        => [
            {
                message => {
                    title => "Initial order comment",
                    content =>
                      "Please deliver to my neighbour if I am not at home",
                    author_users_id => $user->id,
                    type            => 'order_comment',
                }
            }
        ],
    };

    lives_ok( sub { $order = $schema->resultset('Order')->create($data) },
        "Create order" );

    cmp_ok( $schema->resultset('Order')->count, "==", 1, "We have 1 order" );

    lives_ok( sub { $rset = $order->comments }, "get comments via m2m" );

    cmp_ok( $rset->count, "==", 1, "We have 1 comment" );

    $result = $rset->first;

    isa_ok( $result, 'Interchange6::Schema::Result::Message' );

    cmp_ok( $result->title, 'eq', "Initial order comment", "check title" );

    lives_ok( sub { $result->title("New title") }, "Change title" );

    cmp_ok( $result->title, 'eq', "New title", "check title" );

    lives_ok( sub { $result->update }, "call update on Message" );

    lives_ok( sub { $rset = $order->comments }, "Reload comments from DB" );

    lives_ok( sub { $result = $rset->first }, "Get first result" );

    cmp_ok( $result->title, 'eq', "New title", "check title" );

    lives_ok(
        sub {
            $result->update(
                { title => "changed again", content => "new content as well" }
            );
        },
        "update title and content via ->update(href) on Message"
    );

    lives_ok( sub { $rset = $order->comments }, "Reload comments from DB" );

    lives_ok( sub { $result = $rset->first }, "Get first result" );

    cmp_ok( $result->title,   'eq', "changed again",       "check title" );
    cmp_ok( $result->content, 'eq', "new content as well", "check content" );

    lives_ok( sub { $order->delete }, "Delete order" );

    cmp_ok( $schema->resultset("Order")->count, "==", 0, "Zero orders" );

    cmp_ok( $schema->resultset("OrderComment")->count,
        "==", 0, "Zero order comments" );

    cmp_ok( $schema->resultset("Message")->count, "==", 0, "Zero messages" );

};

test 'product reviews tests' => sub {
    my $self = shift;

    my ( $message, $product, $variant, $author, $approver, $rset, $result );

    my $rset_message = $self->ic6s_schema->resultset('Message');

    lives_ok(
        sub {
            $product = $self->products->find( { sku => 'os28066' } );
        },
        "grab canonical product from fixtures"
    );

    isa_ok( $product, 'Interchange6::Schema::Result::Product', "product" );

    cmp_ok( $product->variants->count, '>=', 1, "product has variants" );

    lives_ok( sub { $variant = $product->variants->first }, "grab variant" );

    isa_ok( $variant, 'Interchange6::Schema::Result::Product', "variant" );

    lives_ok(
        sub { $author = $self->users->find( { username => 'customer1' } ) },
        "select author from User" );

    lives_ok(
        sub { $approver = $self->users->find( { username => 'admin1' } ) },
        "select approver from User" );

    lives_ok(
        sub {
            $rset_message->create(
                {
                    title           => "not a review",
                    content         => "not a review",
                    author_users_id => $author->id,
                    type            => "blog_post",
                }
            );
        },
        "Add non-review message"
    );

    lives_ok(
        sub {
            $result = $product->set_reviews(
                {
                    title           => "massive bananas",
                    content         => "Love them",
                    author_users_id => $author->id
                },
            );
        },
        "Add review to parent product with set_reviews"
    );

    cmp_ok( $product->product_reviews->count,
        '==', 1, "parent has 1 product_reviews" );
    cmp_ok( $variant->product_reviews->count, '==', 1,
        "variant has 1 product_reviews" );
    cmp_ok( $product->reviews->count,  '==', 1, "parent has 1 reviews" );
    cmp_ok( $variant->reviews->count,  '==', 1, "variant has 1 reviews" );
    cmp_ok( $product->messages->count, '==', 1, "parent has 1 messages" );
    cmp_ok( $variant->messages->count, '==', 0, "variant has 0 messages" );

    cmp_ok( $self->ic6s_schema->resultset('Message')->count,
        '==', 2, "2 Message rows" );

    cmp_ok( $self->ic6s_schema->resultset('ProductMessage')->count,
        '==', 1, "1 ProductMessage row" );

    lives_ok(
        sub {
            $result = $product->set_reviews(
                [
                    {
                        title           => "massive bananas",
                        content         => "Love them",
                        author_users_id => $author->id
                    },
                    {
                        title   => "cool as ice",
                        content => "cool blue",
                    },
                ]
            );
        },
        "repeat set_reviews with 2 reviews"
    );

    cmp_ok( $product->reviews->count,  '==', 2, "parent has 2 reviews" );
    cmp_ok( $variant->reviews->count,  '==', 2, "variant has 2 reviews" );
    cmp_ok( $product->messages->count, '==', 2, "parent has 2 messages" );
    cmp_ok( $variant->messages->count, '==', 0, "variant has 0 messages" );

    cmp_ok( $self->ic6s_schema->resultset('Message')->count,
        '==', 3, "3 Message rows" );

    cmp_ok( $self->ic6s_schema->resultset('ProductMessage')->count,
        '==', 2, "2 ProductReview rows" );

    throws_ok { $variant->set_reviews() }
    qr/set_reviews needs a list of objects or hashrefs/,
      "set_reviews with no args throws exception";

    throws_ok { $variant->add_to_reviews() }
    qr/add_to_reviews needs an object or hashref/,
      "add_to_reviews with no args throws exception";

    throws_ok { $variant->add_to_reviews('q') }
    qr/Bad argument supplied to add_to_reviews/,
      "add_to_reviews with bad arg throws exception";

    lives_ok(
        sub {
            $result = $variant->add_to_reviews(
                { title => "cool bananas", content => "yellow" } );
        },
        "Add review to variant product"
    );

    cmp_ok( $product->reviews->count,  '==', 3, "parent has 3 reviews" );
    cmp_ok( $variant->reviews->count,  '==', 3, "variant has 3 reviews" );
    cmp_ok( $product->messages->count, '==', 3, "parent has 3 messages" );
    cmp_ok( $variant->messages->count, '==', 0, "variant has 0 messages" );

    cmp_ok( $self->ic6s_schema->resultset('Message')->count,
        '==', 4, "4 Message rows" );

    lives_ok( sub { $rset = $author->reviews }, "grab reviews for author" );

    cmp_ok( $rset->count, '==', 1, "1 review" );

    lives_ok( sub { $result = $rset->next }, "grab review obj" );

    cmp_ok( $result->title, 'eq', 'massive bananas', "review title OK");

    lives_ok(
        sub { $product->variants->delete_all },
        "delete all variants of parent"
    );

    cmp_ok( $product->reviews->count, '==', 3, "parent has 3 reviews" );

    lives_ok {
        $message = $self->ic6s_schema->resultset('Message')->create(
            {
                title   => "some message",
                content => "the content",
                type    => "order_comment"
            }
          )
    }
    "create an order comment";

    throws_ok { $product->add_to_reviews($message) }
    qr/cannot add message type.+to reviews/,
      "cannot add order_comment using add_to_reviews";

    lives_ok {
        $message = $rset_message->create(
            {
                title   => "some message",
                content => "the content",
                type    => "product_review"
            }
          )
    }
    "create a review";

    lives_ok { $product->add_to_reviews($message) }
      "add review object using add_to_reviews";

    cmp_ok( $product->reviews->count, '==', 4, "parent has 4 reviews" );

    lives_ok( sub { $product->delete }, "delete parent" );

    cmp_ok( $self->ic6s_schema->resultset('Message')->count,
        '==', 2, "2 Message rows" );

    # cleanup
    $self->clear_products;
    $rset_message->delete_all;
};

1;
