package Kwiki::Purple::Sequence;
use Kwiki::Plugin '-Base';
use Kwiki::Installer '-base';
use Carp;

const class_id             => 'purple_sequence';
const class_title          => 'Purple Sequence';
const css_file             => 'purple.css';
const config_file          => 'purple_sequence.yaml';
const cgi_class            => 'Kwiki::Purple::Sequence::CGI';

field remote_sequence => -init =>
  '$self->config->can("purple_sequence_remote") ?  $self->config->purple_sequence_remote : ""';

our $VERSION = '0.03';

sub register {
    my $registry = shift;
    $registry->add(action => 'purple_post');
    $registry->add(action => 'purple_query');
}

sub purple_post {
    my $url = $self->cgi->url;
    my $nid = $self->cgi->nid;

    warn "URL: $url\n";
    warn "NID: $nid\n";

    if ($nid && $url) {
        $self->_local_update_index($url, $nid);
    } elsif ($url) {
        $nid = $self->_local_get_next_and_update($url);
    } else {
        $nid = $self->_local_get_next;
    }

    $self->hub->headers->content_type('text/plain');
    return $nid;
}

sub purple_query {
    my $nid = $self->cgi->nid;
    my $url = $self->_local_query_index($nid);
    $self->hub->headers->content_type('text/plain');
    return $url;
}

sub query_index {
    my $nid = shift;
    return $self->_remote_query_index($nid) if
      $self->remote_sequence;
    return $self->_local_query_index($nid);
}

# XXX do permissions checking a la PurpleWiki 0.9[56]
# XXX Error Handling!!!??
sub update_index {
    my $url = shift or croak "must supply url";
    my $nid = shift;

    return $self->_remote_update_index($url, $nid) if
      $self->remote_sequence;
    return $self->_local_update_index($url, $nid);
}

sub get_next {
    return $self->_remote_get_next if
      $self->remote_sequence;
    return $self->_local_get_next;
}

sub get_next_and_update {
    my $url = shift;

    return $self->_remote_get_next_and_update($url) if 
      $self->remote_sequence;

    return $self->_local_get_next_and_update($url);
}

#### PRIVATE

sub _local_get_next {
    $self->_lock;
    my $nid = $self->_update_value($self->_increment_value($self->_get_value));
    $self->_unlock;
    return $nid;
}


sub _remote_get_next {
    return $self->_remote_get_next_and_update;
}

sub _remote_update_index {
    $self->_remote_get_next_and_update(@_);
}

sub _remote_get_next_and_update {
    my $url = shift;
    my $nid = shift;

    my $request_url = $self->remote_sequence;

    my $new_nid = $self->hub->purple->web_request(
        method => 'POST',
        request_url => $request_url,
        post_data => [
            action => 'purple_post',
            $url ? (url => $url) : (),
            $nid ? (nid => $nid) : (),
        ],
    );

    return $new_nid;
}

sub _local_update_index {
    my $url = shift or croak "must supply url";
    my $nid = shift;
    my $index = $self->_sequence_index_rdwr;
    $index->{$nid} = $url;
}


sub _local_get_next_and_update {
    my $url = shift;
    my $nid = $self->_local_get_next;
    $self->_local_update_index($url, $nid);
    return $nid;
}

sub _local_query_index {
    my $nid = shift;
    my $index = $self->_sequence_index_rdonly;
    return $index->{$nid};
}

sub _remote_query_index {
    my $nid = shift;
    my $request_url = $self->remote_sequence .
      "?action=purple_query;nid=$nid";
    return $self->hub->purple->web_request(
        method => 'GET',
        request_url => $request_url,
    );
}

sub _sequence_index_rdwr {
    return io($self->_sequence_index_file)->dbm('DB_File::Lock')->rdwr;
}

sub _sequence_index_rdonly {
    return io($self->_sequence_index_file)->dbm('DB_File::Lock')->rdonly;
}

# XXX can assists testing
sub _sequence_index_file {
    my $index = ($self->config->can('purple_sequence_index') &&
      $self->config->purple_sequence_index)
      ? $self->config->purple_sequence_index
      : $self->plugin_directory . '/' . 'sequence.index';
    return $index;
}


# taken from PurpleWiki
sub _lock {
    my $tries = 0;
    while (mkdir($self->_lock_directory, 0555) == 0) {
        die "unable to create sequence locking directory"
          if ($! != 17);
        $tries++;
        die "timeout attempting to lock sequence"
          if ($tries > $self->config->purple_sequence_lock_count);
        sleep 1;
    }
}

sub _unlock {
    rmdir($self->_lock_directory) or
      die "unable to remove sequence locking directory";
}

sub _lock_directory {
    $self->_sequence_file . '.lck';
}

sub _get_value {
    io($self->_sequence_file)->print(0)
      unless io($self->_sequence_file)->exists;
    io($self->_sequence_file)->all;
}

sub _update_value {
    my $value = shift;
    io($self->_sequence_file)->print($value);
    return $value;
}

sub _sequence_file {
    ($self->config->can('purple_sequence_file') &&
      $self->config->purple_sequence_file)
      ? $self->config->purple_sequence_file
      : $self->plugin_directory . '/' . 'sequence';
}


# XXX taken right out of purplewiki, i'm quite sure this can
# be made more smarter. might make sense to just go with ints
sub _increment_value {
    my $value = shift;
    $value ||= 0;

    my @oldValues = split('', $value);
    my @newValues;
    my $carryBit = 1;

    foreach my $char (reverse(@oldValues)) {
        if ($carryBit) {
            my $newChar;
            ($newChar, $carryBit) = $self->_inc_char($char);
            push(@newValues, $newChar);
        } else {
            push(@newValues, $char);
        }
    }
    push(@newValues, '1') if ($carryBit);
    return join('', (reverse(@newValues)));
}

sub _inc_char {
    my $char = shift;

    if ($char eq 'Z') {
        return '0', 1;
    }
    if ($char eq '9') {
        return 'A', 0;
    }
    if ($char =~ /[A-Z0-9]/) {
        return chr(ord($char) + 1), 0;
    }
}

package Kwiki::Purple::Sequence::CGI;
use Kwiki::CGI -base;

cgi 'nid';
cgi 'url';

package Kwiki::Purple::Sequence;

__DATA__

=head1 NAME

Kwiki::Purple::Sequence - Provide the next purple number and store it

=head1 DESCRIPTION

A Kwiki::Purple::Sequence is a source of the next Purple Number used
for creating nids in L<Kwiki::Purple> to ensure that no nid is used
more than once. That's all this version does at this time.

A fully implemented Sequence maintains an index of NID:PageName or
NID:URL pairs to allow for transclusion amongst multiple wikis or
other sources of nid identified information.

Based in very large part on PurpleWiki::Sequence, which has more
functionality.

=head1 AUTHORS

Chris Dent, <cdent@burningchrome.com>

=head1 SEE ALSO

L<Kwiki::Purple>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005, Chris Dent

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
__config/purple_sequence.yaml__
purple_sequence_file:
purple_sequence_index:
purple_sequence_lock_count: 10
purple_sequence_remote:
