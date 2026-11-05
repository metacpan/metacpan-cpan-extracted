#!/usr/bin/env perl
use strict;
use warnings;

use HTTP::Tiny;
use LLM::API;
use LLM::API::Bedrock;
use MIME::Base64 qw(encode_base64);
use JSON::PP qw(decode_json encode_json);
use Test::More;

{
  package Local::DocumentBedrock;
  our $REQUEST;
  our $TOKEN_REQUEST;
  sub Converse {
    my ( $self, $request ) = @_;
    $REQUEST = $request;
    return {
      output => { message => { content => [ { text => q{Reviewed.} } ] } },
      stopReason => q{end_turn},
      usage => { inputTokens => 17, outputTokens => 3 },
    };
  }
  sub CountTokens {
    my ( $self, $request ) = @_;
    $TOKEN_REQUEST = $request;
    return { inputTokens => 17 };
  }
}

{
  no warnings q{redefine};
  local *LLM::API::Bedrock::_runtime = sub { return bless {}, q{Local::DocumentBedrock} };
  my $llm = LLM::API->new( provider => q{bedrock}, model => q{amazon.nova-micro-v1:0} );

  subtest q{text documents preserve existing caller interface} => sub {
    my $document = $llm->document( media_type => q{text}, data => q{package Example; 1;}, title => q{Example} );
    is( $document->{type}, q{document}, q{document helper unchanged} );
    my $response = $llm->send_prompt( [ $document, $llm->text(q{Review this Perl module}) ] );
    ok( $response->is_success, q{response succeeds} );
    is( $response->content->text, q{Reviewed.}, q{normalized response} );
    is_deeply(
      $Local::DocumentBedrock::REQUEST->{messages}->[0]->{content},
      [ { text => q{package Example; 1;} }, { text => q{Review this Perl module} } ],
      q{text document is transmitted as text},
    );
  };

  subtest q{PDF documents become Bedrock document blocks} => sub {
    my $bytes = "%PDF-1.4\nfixture\n";
    my $document = $llm->document( media_type => q{pdf}, data => \$bytes, title => q{Report.pdf} );
    my $response = $llm->send_prompt( [ $document, $llm->text(q{Summarize the report}) ] );
    ok( $response->is_success, q{PDF request succeeds} );
    is_deeply(
      $Local::DocumentBedrock::REQUEST->{messages}->[0]->{content},
      [
        { document => { format => q{pdf}, name => q{Report pdf}, source => { bytes =>  $bytes } } },
        { text => q{Summarize the report} },
      ],
      q{PDF source is base64 and name is safe},
    );
    my ( $count ) = $llm->count_input_tokens( [ $document, $llm->text(q{Summarize the report}) ] );
    is( $count, 17, q{CountTokens supports PDF content} );
    is_deeply(
      $Local::DocumentBedrock::TOKEN_REQUEST->{input}->{converse}->{messages}->[0]->{content},
      $Local::DocumentBedrock::REQUEST->{messages}->[0]->{content},
      q{Converse and CountTokens use identical content},
    );
  };

  subtest q{multi-turn user PDF input} => sub {
    my $doc = $llm->document( media_type => q{pdf}, data => \("%PDF-1.4\n"), title => q{Spec} );
    my $response = $llm->send_messages([
      { role => q{user}, content => [ $doc, $llm->text(q{What is here?}) ] },
      { role => q{assistant}, content => [ $llm->text(q{A report.}) ] },
      { role => q{user}, content => [ $llm->text(q{Summarize it.}) ] },
    ]);
    ok( $response->is_success, q{conversation with PDF works} );
    is( $Local::DocumentBedrock::REQUEST->{messages}->[0]->{content}->[0]->{document}->{format}, q{pdf}, q{PDF preserved} );
    is( $Local::DocumentBedrock::REQUEST->{messages}->[1]->{role}, q{assistant}, q{roles preserved} );
  };

  subtest q{invalid and unsafe document combinations are rejected} => sub {
    my $pdf = $llm->document( media_type => q{pdf}, data => \("%PDF-1.4\n"), title => q{Report} );
    for my $blocks ( [ $pdf ], [ $pdf, $llm->text(q{ }) ] ) {
      my $ok = eval { $llm->send_prompt($blocks); 1 };
      ok( !$ok, q{PDF without question rejected} );
      like( $@, qr/accompanying text prompt/, q{diagnostic} );
    }
    my $ok = eval { $llm->send_messages([ { role => q{assistant}, content => [ $pdf ] } ]); 1 };
    ok( !$ok, q{assistant PDF rejected} );
    my $invalid = { type => q{document}, source => { type => q{text}, media_type => q{image/png}, data => q{bytes} } };
    $ok = eval { $llm->send_prompt([ $invalid, $llm->text(q{Review}) ]); 1 };
    ok( !$ok, q{unsupported media type rejected} );
  };
}

{
  package Local::DocumentAnthropic;
  our $REQUEST;
  sub post {
    my ( $self, $url, $request ) = @_;
    $REQUEST = $request;
    return {
      success => 1,
      code => 200,
      content => JSON::PP::encode_json({
        type => q{message}, role => q{assistant}, stop_reason => q{end_turn},
        content => [ { type => q{text}, text => q{Reviewed.} } ],
        usage => { input_tokens => 17, output_tokens => 3 },
      }),
    };
  }
}

{
  no warnings q{redefine};
  local *HTTP::Tiny::new = sub { return bless {}, q{Local::DocumentAnthropic} };
  my $llm = LLM::API->new( api_key => q{fixture} );

  subtest q{Anthropic document request format unchanged} => sub {
    my $pdf = "%PDF-1.4\nfixture\n";
    my $document = $llm->document( media_type => q{pdf}, data => \$pdf, title => q{Report.pdf} );
    my $response = $llm->send_prompt( [ $document, $llm->text(q{Review the PDF}) ] );
    ok( $response->is_success, q{Anthropic response succeeds} );
    my $sent = decode_json( $Local::DocumentAnthropic::REQUEST->{content} );
    is_deeply(
      $sent->{messages}->[0]->{content},
      [ $document, $llm->text(q{Review the PDF}) ],
      q{Anthropic document and prompt blocks are preserved verbatim},
    );
  };
}

done_testing;
1;
