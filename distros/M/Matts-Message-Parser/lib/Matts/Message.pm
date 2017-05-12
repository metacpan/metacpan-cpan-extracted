
package Matts::Message;
use strict;
use MIME::Base64 qw(encode_base64);

sub new {
    bless { 
        encodings => [],
        bin_headers => {},
        headers => {},
        body_parts => [],
        attachments => [],
        raw => '',
    }, shift;
}

sub raw_headers {
    my $self = shift;
    return $self->{raw};
}

sub header {
    my $self = shift;
    my $k = shift;
    my $key = lc($k);
    if (@_) {
        $self->{raw} .= "$k: @_";
        if (exists $self->{headers}{$key}) {
            push @{$self->{headers}{$key}}, @_;
        }
        else {
            $self->{headers}{$key} = [@_];
        }
        return $self->{headers}{$key}[-1];
    }
    
    if (wantarray) {
        return unless exists $self->{headers}{$key};
        return @{$self->{headers}{$key}};
    }
    else {
        return '' unless exists $self->{headers}{$key};
        return $self->{headers}{$key}[-1];
    }
}

sub binary_header {
    my $self = shift;
    my $key = lc(shift);
    if (@_) {
        if (exists $self->{bin_headers}{$key}) {
            push @{$self->{bin_headers}{$key}}, @_;
        }
        else {
            $self->{bin_headers}{$key} = [@_];
        }
        return $self->{bin_headers}{$key}[-1];
    }
    
    if (wantarray) {
        return unless exists $self->{bin_headers}{$key};
        return @{$self->{bin_headers}{$key}};
    }
    else {
        return '' unless exists $self->{bin_headers}{$key};
        return $self->{bin_headers}{$key}[-1];
    }
}

sub header_del {
    my $self = shift;
    my $header = lc(shift);
    $self->{raw} =~ s/^$header:.*?^(\S)/$1/ism;
    delete $self->{headers}{$header};
}

sub headers {
    my $self = shift;
    return keys %{$self->{headers}};
}

sub binary_headers {
    my $self = shift;
    return keys %{$self->{bin_headers}};
}

sub add_body_part {
    my $self = shift;
    my ($type, $fh) = @_;
    $type ||= 'text/plain';
    my $enc = 'null';
    if ($type =~ s/;(.*$)//) { # strip everything after first semi-colon
        my $cs = $1;
        if ($cs =~ /charset="?([\w-]+)/) {
            $enc = $1;
        }
    }
    $type =~ s/[^a-zA-Z\/]//g; # strip inappropriate chars
    push @{ $self->{encodings} }, $enc;
    push @{ $self->{body_parts} }, [ $type => $fh ];
}

sub add_attachment {
    my $self = shift;
    my ($type, $fh, $name) = @_;
    push @{ $self->{attachments} }, { 
        filename => $name, 
        type => $type, 
        fh => $fh,
    };
}

sub body {
    my $self = shift;
    my $type = shift;
    return unless @{ $self->{body_parts} };
    if ($type) {
        # warn("body has ", scalar(@{ $self->{body_parts} }), " [$type]\n");
        foreach my $body ( @{ $self->{body_parts} } ) {
            # warn("type: $body->[0]\n");
            if (lc($type) eq lc($body->[0])) {
                return wantarray ? @$body : $body->[1];
            }
        }
    }
    
    return wantarray ? @{ $self->{body_parts}[0] } : $self->{body_parts}[0][1];
}

sub bodies {
    my $self = shift;
    my @ret;
    foreach my $body ( @{ $self->{body_parts} } ) {
        push @ret, lc($body->[0]), $body->[1];
    }
    return @ret;
}

sub body_enc {
    my $self = shift;
    my ($id) = @_;
    return $self->{encodings}[$id];
}

sub attachment {
    my $self = shift;
    return $self->{attachments}[shift];
}

sub attachments {
    my $self = shift;
    return @{ $self->{attachments} };
}

sub num_attachments {
    my $self = shift;
    return scalar @{ $self->{attachments} };
}

sub to_string {
    my $self = shift;
    
    my $output = '';
    my $sub = sub { $output .= join('', @_) };
    $self->_walk_tree($sub);
    return $output;
}

sub size {
    my $self = shift;
    @_ and $self->{size} = shift;
    $self->{size};
}

sub mtime {
    my $self = shift;
    @_ and $self->{mtime} = shift;
    $self->{mtime};
}

sub dump {
    my $self = shift;
    my ($fh) = @_;
    $fh ||= \*STDOUT;
    
    my $sub = sub { print $fh @_ };
    $self->_walk_tree($sub);
}

sub _walk_tree {
    my $msg = shift;
    my ($sub) = @_;
    
    # Munge the whole thing into a big old multipart/mixed thingy.
    $msg->header_del('content-type');
    my $boundary = "----=_NextPart_000_" . $$ . time;
    $msg->header('Content-Type', "multipart/mixed; boundary=\"$boundary\"\n");

    $sub->($msg->raw_headers);

    # Output Received headers first.
    #foreach my $value ($msg->header('Received')) {
        #    $sub->("Received: $value\n");
        #}

    # Output remaining headers in random order
    #foreach my $header ($msg->headers) {
        #    next if lc($header) eq 'received';
        #foreach my $value ($msg->header($header)) {
            #    $header =~ s/(^|-)(\w)/$1 . uc($2)/eg;
            #$sub->("$header: $value\n");
            #}
            #}
    $sub->("\n");

    $sub->("This is a dump of a parsed message. Ignore this bit.\n\n");

    $sub->("--$boundary\n");

    my $body_boundary = "----=_NextPart_111_" . $$ . time;
    $sub->("Content-Type: multipart/alternate; boundary=\"$body_boundary\"\n");
    $sub->("\n");
    my @body_parts = $msg->bodies;

    while (@body_parts) {
        my ($type, $fh) = splice(@body_parts, 0, 2);
        $sub->("--$body_boundary\n");
        $sub->("Content-Type: $type\n");
        if ($type !~ /^text\//) {
            $sub->("Content-Transfer-Encoding: base64\n");
            $sub->("\n");
            local $/;
            $sub->(encode_base64(<$fh>));
            $sub->("\n");
        }
        else {
            $sub->("Content-Transfer-Encoding: 8bit\n");
            $sub->("\n");
            local $/;
            $sub->(<$fh>);
            $sub->("\n");
        }
    }
    $sub->("--$body_boundary--\n\n");
    
    foreach my $att ($msg->attachments) {
        $sub->("--$boundary\n");
        $sub->("Content-Type: $att->{type}\n");
        $sub->("Content-Disposition: attachment; filename=$att->{filename}\n");
        $sub->("Content-Transfer-Encoding: base64\n");
        $sub->("\n");

        my $fh = $att->{fh};
        local $/;
        $sub->(encode_base64(<$fh>));
        $sub->("\n");
    }

    $sub->("--$boundary--\n");
}

1;
__END__
