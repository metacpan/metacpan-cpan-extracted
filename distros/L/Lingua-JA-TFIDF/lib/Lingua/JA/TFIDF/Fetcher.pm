package Lingua::JA::TFIDF::Fetcher;
use strict;
use warnings;
use base qw(Lingua::JA::TFIDF::Base);
use Carp;
use LWP::UserAgent;
use XML::TreePP;

sub new {
    my $class = shift;
    my %args  = @_;
    my $self  = $class->SUPER::new( \%args );
    $self->_prepare;
    return $self;
}

sub fetch {
    my $self = shift;
    my $word = shift;
    $word =~ s/([^\w ])/'%'.unpack('H2', $1)/eg;
    $word =~ tr/ /+/;
    my $url = $self->{url} . $word;
    my $req = HTTP::Request->new( GET => $url );
    my $res = $self->{user_agent}->request($req);
    if ( $res->is_success ) {
        my $xml = $self->{xml_treepp}->parse( $res->content );
        return $xml->{ResultSet}->{'-totalResultsAvailable'};
    }
    else {
        carp( $res->message );
    }
}

sub _prepare {
    my $self                 = shift;
    my %LWP_UserAgent_config = ();
    if ( ref $self->config->{LWP_UserAgent} eq 'HASH' ) {
        %LWP_UserAgent_config = %{ $self->config->{LWP_UserAgent} };
    }
    $self->{user_agent} = LWP::UserAgent->new(%LWP_UserAgent_config);
    my %XML_TreePP_config = ();
    if ( ref $self->config->{XML_TreePP} eq 'HASH' ) {
        %XML_TreePP_config = %{ $self->config->{XML_TreePP} };
    }
    $self->{xml_treepp} = XML::TreePP->new(%XML_TreePP_config);
    my $yahoo_api_appid = $self->config->{yahoo_api_appid} || 'yahooDemo';
    $self->{url} =
        'http://search.yahooapis.jp/WebSearchService/V1/webSearch?appid='
      . $yahoo_api_appid
      . '&results=1&adult_ok=1&query=';
}

1;
__END__

=head1 NAME

Lingua::JA::TFIDF::Fetcher - Fetcher class that will be working when it faces to Unknown words.

=head1 SYNOPSIS

=head1 DESCRIPTION

Lingua::JA::TFIDF::Fetcher is fetcher class that will work when it faces to Unknown words.

=head1 METHODS

=head2 new(%config)

  my $calc = Lingua::JA::TFIDF::Fetcher->new(
    fetch_df        => 1,                      # default is undef
    fetch_df_save   => 'my_df_file',           # default is undef
    LWP_UserAgent   => \%lwp_useragent_config, # default is undef
    XML_TreePP      => \%xml_treepp_config,    # default is undef
    yahoo_api_appid => $myid,                  # default is undef
  );

=head2 fetch($word); 

=head1 AUTHOR

Takeshi Miki E<lt>miki@cpan.orgE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO


=cut
