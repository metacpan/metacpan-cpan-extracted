package LLM::API::Bedrock;

use strict;
use warnings;

use LLM::API::Response;
use MIME::Base64 qw(decode_base64 encode_base64);
use Scalar::Util qw(reftype);

our $VERSION = '2.0.0';

########################################################################
sub _runtime {
########################################################################
  my ( $class, $self ) = @_;

  # Neither AWS dependency is needed when the Anthropic provider is used.
  require Amazon::Credentials;
  require Amazon::API::BedrockRuntime;

  my $credentials = Amazon::Credentials->new;
  return Amazon::API::BedrockRuntime->new(
    credentials => $credentials,
    region      => $self->get_region,
  );
}

########################################################################
sub _content {
########################################################################
  my ( $class, $blocks ) = @_;

  my @converted;
  my $has_document = 0;
  my $has_prompt   = 0;

  for my $block ( @{$blocks} ) {
    die "ERROR: invalid Bedrock content block\n"
      if ref $block ne q{HASH};

    if ( ( $block->{type} // q{} ) eq q{text} ) {
      die "ERROR: Bedrock text block must contain text\n"
        if !defined $block->{text};
      push @converted, { text => $block->{text} };
      $has_prompt = 1 if $block->{text} =~ m{\S};
      next;
    }

    die "ERROR: unsupported Bedrock content block\n"
      if ( $block->{type} // q{} ) ne q{document};

    my $source = $block->{source};
    die "ERROR: invalid Bedrock document source\n"
      if ref $source ne q{HASH} || !defined $source->{data};

    if ( ( $source->{media_type} // q{} ) eq q{text/plain} ) {
      my $data = $source->{data};
      $data = decode_base64($data)
        if ( $source->{type} // q{} ) eq q{base64};
      die "ERROR: unsupported document source encoding\n"
        if ( $source->{type} // q{} ) ne q{text} && ( $source->{type} // q{} ) ne q{base64};
      push @converted, { text => $data };
      next;
    }

    die "ERROR: unsupported Bedrock document media type\n"
      if ( $source->{media_type} // q{} ) ne q{application/pdf};

    die "ERROR: unsupported document source encoding\n"
      if ( $source->{type} // q{} ) ne q{text} && ( $source->{type} // q{} ) ne q{base64};

    # LLM::API::document() retains its Anthropic-compatible source structure.
    # The Bedrock JSON request requires base64 in document.source.bytes.
    my $bytes = $source->{type} eq q{base64} ? decode_base64( $source->{data} ) : $source->{data};
    die "ERROR: PDF document is empty\n"
      if !length $bytes;

    my $name = $block->{title} // q{Document};
    $name =~ s{[^a-zA-Z0-9 ()\[\]-]}{ }g;
    $name =~ s{\s+}{ }g;
    $name =~ s{\A\s+|\s+\z}{}g;
    $name = q{Document} if !length $name;
    $name = substr $name, 0, 200;

    push @converted,
      {
      document => {
        format => q{pdf},
        name   => $name,
        source => { bytes => $bytes },
      },
      };
    $has_document = 1;
  }

  die "ERROR: Bedrock PDF documents require an accompanying text prompt\n"
    if $has_document && !$has_prompt;

  return \@converted;
}

########################################################################
sub send_prompt {
########################################################################
  my ( $class, $self, $content ) = @_;

  die "ERROR: usage: send_prompt(array-ref)\n"
    if !ref $content || reftype($content) ne q{ARRAY};

  return $class->send_messages( $self, [ { role => $self->get_role, content => $content } ] );
}

########################################################################
sub send_messages {
########################################################################
  my ( $class, $self, $messages ) = @_;

  my @converted;
  for my $message ( @{$messages} ) {
    if ( $message->{role} ne q{user} ) {
      for my $block ( @{ $message->{content} } ) {
        die "ERROR: Bedrock documents are supported only in user messages\n"
          if ( $block->{type} // q{} ) eq q{document};
      }
    }

    push @converted,
      {
      role    => $message->{role},
      content => $class->_content( $message->{content} ),
      };
  }

  my $result;
  my $ok = eval {
    $result = $class->_runtime($self)->Converse(
      { modelId         => $self->get_model,
        inferenceConfig => { maxTokens => $self->get_max_tokens },
        messages        => \@converted,
      }
    );
    return 1;
  };

  if ( !$ok ) {
    my $error = $@ || q{Unknown Bedrock error};
    return LLM::API::Response->from_error( message => $error );
  }

  return LLM::API::Response->from_error( message => q{Invalid Bedrock response}, provider_response => $result )
    if ref $result ne q{HASH}
    || ref $result->{output} ne q{HASH}
    || ref $result->{output}->{message} ne q{HASH}
    || ref $result->{output}->{message}->{content} ne q{ARRAY};

  my @content;
  for my $block ( @{ $result->{output}->{message}->{content} } ) {
    next if ref $block ne q{HASH};
    push @content, { type => q{text}, text => $block->{text} }
      if defined $block->{text};
  }

  my $usage = $result->{usage} // {};
  my %stops = ( end_turn => q{end_turn}, max_tokens => q{max_tokens} );
  my $stop  = $result->{stopReason} // q{};

  return LLM::API::Response->from_result(
    result => {
      type        => q{message},
      role        => q{assistant},
      model       => $self->get_model,
      stop_reason => $stops{$stop} // $stop,
      content     => \@content,
      usage       => {
        input_tokens  => $usage->{inputTokens}  // 0,
        output_tokens => $usage->{outputTokens} // 0,
      },
    },
    provider_response => $result,
  );
}

########################################################################
sub count_input_tokens {
########################################################################
  my ( $class, $self, $content ) = @_;

  die "ERROR: usage: count_input_tokens(array-ref)\n"
    if !ref $content || reftype($content) ne q{ARRAY};

  my $blocks = $class->_content($content);
  my $result = $class->_runtime($self)->CountTokens(
    { modelId => $self->get_model,
      input   => { converse => { messages => [ { role => $self->get_role, content => $blocks } ] }, },
    }
  );

  die "ERROR: invalid Bedrock CountTokens response\n"
    if ref $result ne q{HASH}
    || !defined $result->{inputTokens}
    || $result->{inputTokens} !~ m{\A[0-9]+\z};

  my ($input_rate) = $self->pricing( $self->get_model );
  my $input_tokens = 0 + $result->{inputTokens};

  return ( $input_tokens, $input_tokens * $input_rate );
}

########################################################################
sub headers {
########################################################################
  die "ERROR: headers is not supported by the Bedrock provider\n";
}

########################################################################
sub _do_admin_api {
########################################################################
  die "ERROR: administrative API operations are not supported by the Bedrock provider\n";
}

1;
