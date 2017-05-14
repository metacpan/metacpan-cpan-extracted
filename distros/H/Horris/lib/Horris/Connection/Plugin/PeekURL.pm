package Horris::Connection::Plugin::PeekURL;
# ABSTRACT: Fetches Links And Display Some Data On It


use Moose;
use AnyEvent::HTTP;
use Encode qw(encode_utf8 decode FB_CROAK);
use File::Temp;
use HTML::TreeBuilder;
use Image::Size;
use URI;
use WWW::Shorten 'TinyURL';
extends 'Horris::Connection::Plugin';
with 'MooseX::Role::Pluggable::Plugin';

sub irc_privmsg {
    my ($self, $msg) = @_;

    my $message = $msg->message;
    while ( $message =~ m{((!)?(?:https?:)(?://[^\s/?#]*)[^\s?#]*(?:\?[^\s#]*)?(?:#.*)?)}g ) {
        my $do_peek = defined($2) ? 0 : 1;
        next unless $do_peek;

		my $shorten_url;
        my $uri = URI->new($1);
        next unless $uri->scheme && $uri->scheme =~ /^http/i;
        next unless $uri->authority;

        if (length "$uri" > 50 && $uri->authority !~ /tinyurl|bit\.ly/) {
			$shorten_url = makeashorterlink($uri);
            $uri = URI->new($shorten_url);
#            $self->connection->irc_notice({
#                channel => $msg->channel,
#                message => "short url: $uri"
#            });
        }
		$shorten_url = $shorten_url ? " - $shorten_url" : '';

        my @ct;
        my $ct = 0; # 0 - text, 1 - image, 2, other
        my $file;

        my $guard; $guard = http_get $uri, 
            timeout   => 30,
            recurse   => 10,
            on_header => sub {
                my ($headers) = @_;

                if ($headers->{Status} ne '200') {
                    undef $guard;
                    $self->connection->irc_notice({
                        channel => $msg->channel,
                        message => "Request failed: $headers->{Reason} ($headers->{Status})",
                    });
                    return;
                }
                @ct = split(/\s*,\s*/, $headers->{'content-type'});
                if (grep { /^image\/.+$/i } @ct) {
                    $ct = 1;
                } elsif ( grep { !/^text\/.+$/i } @ct) {
                    # otherwise it's something we don't know about.
                    # don't spend the time and memory to load this guy
                    undef $guard;
                    $ct = 2;
                    $self->connection->irc_notice({
                        channel => $msg->channel, 
                        message => sprintf( "%s [%s]%s", $uri, $ct[0], $shorten_url)
                    });
                    return;
                }
                return 1;
            },
            on_body => sub {
                # off load to the file system.
                $file ||= File::Temp->new(UNLINK => 1);

                print $file $_[0];
                return 1;
            },
            sub {
                undef $guard;
                return unless $file;
                seek($file, 0, 0);
                if ($ct == 1) {
                    my($width, $height) = Image::Size::imgsize($file);
                    $self->connection->irc_notice({
                        channel => $msg->channel, 
                        message => sprintf( "%s [%s, w=%d, h=%d]%s", $uri, $ct[0], $width, $height, $shorten_url )
                    });
                } else {
                    my $p;
                    my $data = do { local $/; <$file> };
                    eval { 
                        $p = HTML::TreeBuilder->new(
                            implicit_tags => 1,
                            ignore_unknoown => 1,
                            ignore_text => 0
                        );
                        $p->strict_comment(1);
        
                        my $charset;
        
                        if ($data =~ /charset=(?:'([^']+?)'|"([^"]+?)"|([a-zA-Z0-9_-]+)\b)/) {
                            my $cs = lc($1 || $2 || $3);
                            if ($cs =~ /^Shift[-_]?JIS$/i) {
                                $charset = 'cp949';
                            } else {
                                $charset = $cs;
                            }
                        }

                        if (! $charset) {
                            foreach my $ct (@ct) {
                                if ($ct =~ s/charset=Shift_JIS/charset=cp949/i) {
                                    $charset = 'cp949';
                                } elsif ($ct =~ /charset=([a-zA-Z0-9_-]+)/) {
                                    $charset = $1;
                                }
                            }
                        }
                        $charset ||= 'utf-8';
        
                        eval {
                            $p->parse_content(
                                decode( $charset, $data, FB_CROAK ) );
                        };
                        if ($@) {
                            # if we got bad content, attempt to decode in order
                            foreach my $try_charset qw(cp949 euc-kr utf-8) {
                                eval {
                                    $p->parse_content(decode($try_charset, $data, FB_CROAK ) );
                                };
                    
								$charset = $try_charset unless $@;
                                last unless $@;
                            }
                        }
        
                        my ($title) = $p->look_down(_tag => qr/^title$/i);
						$title ||= $self->_get_dirty_title($data, $charset);

						my $title_text;
						if(ref(\$title) eq 'SCALAR') {
							$title_text = $title;
						}
						else {
							$title_text = $title ? $title->as_trimmed_text(skip_dels => 1) || '' : 'No title';
						}

                        $self->connection->irc_notice({
                            channel => $msg->channel,
                            message => encode_utf8(
                                sprintf('%s [%s]%s', 
                                    $title_text,
                                    $ct[0] || '?',
									$shorten_url
                                )
                            )
                        });

                    };
                    if ($@) {
                        $self->connection->irc_notice({
                            channel => $msg->channel,
                            message => encode_utf8(
                                sprintf("Error while retrieving URL: %s", $@)
                            )
                        });
                    }
                    if ($p) {
                        eval { $p->delete }; 
                    }
                }
            }
        ;
    }

	$self->pass;
}

sub _get_dirty_title {
	my ($self, $data, $charset) = @_;
	my $html = decode($charset, $data);
	$html =~ m{<title>(.+)</title>};
	return $1;
}

__PACKAGE__->meta->make_immutable;

1;

__END__
=pod

=encoding utf-8

=head1 NAME

Horris::Connection::Plugin::PeekURL - Fetches Links And Display Some Data On It

=head1 VERSION

version v0.1.2

=head1 SYNOPSIS

  <Config>
    <Connection whatever>
      <Plugin PeekURL/> # don't put a space before "/"
    </Connection>
  </Config>

=head1 DESCRIPTION

This plugin makes Morris react to messages in the form of http://....
Morris will fetch the URL, and display some information on it in the
channel.

If the link is a plain HTML, it will try to find out its title by
inspecting the content.

If the link is an image, it will display its dimensions.

=head1 AUTHOR

hshong <hshong@perl.kr>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by hshong.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

