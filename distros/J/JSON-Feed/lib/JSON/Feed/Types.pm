package JSON::Feed::Types {
    use Type::Library -base;
    use Type::Utils -all;
    use Types::Standard qw<Str Int Bool Dict Optional ArrayRef HashRef>;
    use Types::Common::Numeric qw< PositiveOrZeroInt >;

    my $AuthorWithoutExt = declare JSONFeedAuthorWithoutExt => as Dict[
        name   => Optional[Str],
        url    => Optional[Str],
        avatar => Optional[Str],
    ], where {
        exists($_->{name}) || exists($_->{url}) || exists($_->{avatar})
    };

    my $Author = declare JSONFeedAuthor => as HashRef, where {
        my $val = $_;
        my %o = map { $_ => $val->{$_} } grep { ! /^_/ } keys %$val;
        $AuthorWithoutExt->check(\%o);
    };

    my $AttachmentWithoutExt = declare JSONFeedAttachmentWithoutExt => as Dict[
        url                 => Str,
        mime_type           => Str,
        title               => Optional[Str],
        size_in_bytes       => Optional[PositiveOrZeroInt],
        duration_in_seconds => Optional[PositiveOrZeroInt],
    ];

    my $Attachment = declare JSONFeedAttachment => as HashRef, where {
        my $val = $_;
        my %o = map { $_ => $val->{$_} } grep { ! /^_/ } keys %$val;
        $AttachmentWithoutExt->check(\%o);
    };

    my $ItemWithoutExt = declare JSONFeedItemWithoutExt => as Dict[
        id             => Str,
        url            => Optional[Str],
        external_url   => Optional[Str],
        title          => Optional[Str],
        content_html   => Optional[Str],
        content_text   => Optional[Str],
        summary        => Optional[Str],
        image          => Optional[Str],
        banner_image   => Optional[Str],
        date_published => Optional[Str],
        date_modified  => Optional[Str],
        author         => Optional[ $Author ],
        tags           => Optional[ArrayRef[Str]],
        attachments    => Optional[ArrayRef[ $Attachment ]],
    ];

    my $Item = declare JSONFeedItem => as HashRef, where {
        my $val = $_;
        my %o = map { $_ => $val->{$_} } grep { ! /^_/ } keys %$val;
        $ItemWithoutExt->check(\%o);
    };

    my $JSONFeedWithoutExt = declare JSONFeedWithoutExt => as Dict[
        version       => Str,
        title         => Str,
        description   => Optional[Str],
        user_comment  => Optional[Str],
        next_url      => Optional[Str],
        icon          => Optional[Str],
        favicon       => Optional[Str],
        author        => Optional[ $Author ],
        home_page_url => Optional[Str],
        feed_url      => Optional[Str],
        expired       => Optional[Bool],
        hub           => Optional[ArrayRef],
        items         => ArrayRef[ $Item ],
    ];

    declare JSONFeed => as HashRef, where {
        my $val = $_;
        my %o = map { $_ => $val->{$_} } grep { ! /^_/ } keys %$val;
        $JSONFeedWithoutExt->check(\%o);
    };

    __PACKAGE__->meta->make_immutable;
};

1;

=head1 NAME

JSON::Feed::Types - The Types for JSON::Feed package.

=head1 SYNOPSIS

    use JSON::Feed::Types;

    JSONFeedAuthor->assert_validate( $obj1 );
    JSONFeedAttachment->assert_validate( $obj2 );

=head1 DESCRIPTION

In this Type library, the following 4 types are defined and exported.

=over 4

=item JSONFeed

=item JSONFeedItem

=item JSONFeedAuthor

=item JSONFeedAttachment

=back

These Types are object defined with L<Type::Tiny|https://metacpan.org/pod/Type::Tiny> and therefore
have methods listed here: L<https://metacpan.org/pod/Type::Tiny#Methods>.

Each type corresponds to an object defined in L<jsonfeed spec v1|https://jsonfeed.org/version/1>.
