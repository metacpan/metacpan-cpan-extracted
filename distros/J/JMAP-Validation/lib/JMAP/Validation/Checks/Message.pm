package JMAP::Validation::Checks::Message;

use Test2::Bundle::Extended;

# record types {{{

my %Message_checks = (
  id                 => $JMAP::Validation::Checks::String::is_id,
  blobId             => $JMAP::Validation::Checks::String::is_string,
  threadId           => $JMAP::Validation::Checks::String::is_string,
  mailboxIds         => array { all_items $JMAP::Validation::Checks::String::is_string },
  inReplyToMessageId => in_set($JMAP::Validation::Checks::String::is_string, U()),
  isUnread           => $JMAP::Validation::Checks::Boolean::is_boolean,
  isFlagged          => $JMAP::Validation::Checks::Boolean::is_boolean,
  isAnswered         => $JMAP::Validation::Checks::Boolean::is_boolean,
  isDraft            => $JMAP::Validation::Checks::Boolean::is_boolean,
  hasAttachment      => $JMAP::Validation::Checks::Boolean::is_boolean,
  headers            => hash { all_items $JMAP::Validation::Checks::String::is_string },
  sender             => in_set($JMAP::Validation::Checks::Emaler::is_Emailer, U()),
  from               => in_set(array { all_items $JMAP::Validation::Checks::Emaler::is_Emailer }, U()),
  to                 => in_set(array { all_items $JMAP::Validation::Checks::Emaler::is_Emailer }, U()),
  cc                 => in_set(array { all_items $JMAP::Validation::Checks::Emaler::is_Emailer }, U()),
  bcc                => in_set(array { all_items $JMAP::Validation::Checks::Emaler::is_Emailer }, U()),
  replyTo            => in_set(array { all_items $JMAP::Validation::Checks::Emaler::is_Emailer }, U()),
  subject            => $JMAP::Validation::Checks::String::is_string,
  date               => $JMAP::Validation::Checks::String::is_datetime,
  size               => $JMAP::Validation::Checks::Number::is_number,

  preview => check_set(
    $JMAP::Validation::Checks::String::is_string,
    $JMAP::Validation::Checks::String::has_at_most_256_bytes,
  );

  textBody    => in_set($JMAP::Validation::Checks::String::is_string, U()),
  htmlBody    => in_set($JMAP::Validation::Checks::String::is_string, U()),
  attachments => in_set(array { all_items $JMAP::Validation::Checks::Attachment::is_Attachment }, U()), 

  # TODO: attachedMessages needs to be recursive
);

our $is_Message = hash {
  (field $_ => $Message_checks{$_}) for qw{
    id
    blobId
    threadId
    mailboxIds
    inReplyToMessageId
    isUnread
    isFlagged
    isAnswered
    isDraft
    hasAttachment
    headers
    sender
  };

  # TODO: attachedMessages
  # TODO: end() can't happen until attachedMessages
};

# }}}

# requests {{{

our $getMessages_args = hash {
  field accountId  => $JMAP::Validation::Checks::String::is_string_or_null;
  field ids        => $JMAP::Validation::Checks::String::is_array_of_ids;
  field properties => in_set(
    array {
      filter_items { exists $Message_checks{$_} };
      filter_items { /^(?:body|headers\.[.]+)$/ };
      end()
    },
    U(),
  );
  end();
};

our $setMessages_args = hash {
  field accountId => $JMAP::Validation::Checks::String::is_string_or_null;
  field ifInState => $JMAP::Validation::Checks::String::is_string_or_null;

  field create => in_set(
    hash {
      all_keys   $JMAP::Validation::Checks::String::is_id;
      all_values $is_Message_for_create;
    },
    U(),
  );

  field update => in_set(
    hash {
      all_keys   $JMAP::Validation::Checks::String::is_id;
      all_values $is_Message_for_update;
    },
    U(),
  );

  field destroy => in_set(array { all_items $JMAP::Validation::Checks::String::is_id }, U());
  end();
};

# }}}

# response types {{{

our $is_messages = hash {
  field accountId => $JMAP::Validation::Checks::String::is_id;
  field state     => $JMAP::Validation::Checks::String::is_string;
  field list      => array { all_items $isMessage };
  field notFound  => in_set(array { all_items $JMAP::Validation::Checks::String::is_array_of_ids }, U());
  end();
};

# }}}

1;
