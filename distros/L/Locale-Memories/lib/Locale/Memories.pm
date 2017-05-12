package Locale::Memories;

use strict;
use utf8;
use Data::Dumper;
use String::Similarity;
use Search::Xapian qw(:ops :db :enq_order);

our $VERSION = '0.04';

my $locale_prefix = '__LOCALE__';

sub new {
    my $class = shift;
    my $arg_ref = shift;
    bless {
	   index => undef,
	   locales => {},
	   index_path => $arg_ref->{index_path},
	  }, $class;
}

sub load_index {
    my ($self, $index_path) = @_;
    return if $self->{index};
    my $index = Search::Xapian::Database->new($index_path);
    die "Index is not loaded" if !$index;
    $self->{index} = $index;
}

sub _build_index {
    my ($self, $locale) = @_;
    return if $self->{index};
    my $database_class = 'Search::Xapian::WritableDatabase';
    $self->{index}
	= ($self->{index_path} ?
	   $database_class->new($self->{index_path}, DB_CREATE_OR_OVERWRITE)
	   : $database_class->new());
}

sub _dequote {
    my $str = shift;
    $str =~ s{\A"(.*?)"\z}{$1}so;
    $str =~ s{\\[trn]}{\n}gso;
    return $str;
}

sub _tokenize {
    my ($self, $str) = @_;
    my @terms = split /(?:\s|\n|\r)+/, $str;
    for (@terms) {
	next if /%\w/;
	next if /\[_\d+]/;
	s{\A\W+}{};
	s{\W+\z}{};
    }
    @terms = map { lc } grep { $_ } @terms;
    return @terms;
}

sub _token_count_diff {
    my ($self, $x, $y) = @_;
    return abs($self->_tokenize($x) - $self->_tokenize($y));
}

sub index_msg {
    my ($self, $locale, $msg_id, $msg_str) = @_;
    return if $msg_id eq '""';
    return if $msg_str eq '""';

    $msg_id = _dequote($msg_id);

    if (!$self->{index}) {
	$self->_build_index($locale);
    }

    my $pos = 1;
    my $doc = Search::Xapian::Document->new();
    $doc->add_posting($locale_prefix.$locale, $pos++, 50);
    for my $term ($self->_tokenize($msg_id)) {
	$doc->add_posting($term, $pos++, 1);
    }
    local $Data::Dumper::Terse = 1;
    local $Data::Dumper::Indent = 0;
    $doc->set_data(Dumper [ $msg_id, $msg_str ]);
    $self->{index}->add_document($doc);
}

sub translate_msg {
    my ($self, $locale, $msg_id) = @_;
    return if !$self->{index};

    $msg_id = _dequote($msg_id);
    return if !$msg_id;

    my @tokens = $self->_tokenize($msg_id);
    return if !@tokens;

    my @translated_msgs;
    for my $op (OP_PHRASE, OP_AND) {
	my $query = Search::Xapian::Query->new($op, @tokens);
	my $locale_query = Search::Xapian::Query->new(OP_OR,
						      $locale_prefix.$locale);
	my $localized_query
	    = Search::Xapian::Query->new(OP_AND, $locale_query, $query);
	my $enq = $self->{index}->enquire($localized_query);
	my $matches = $enq->get_mset(0, 100);
	next if !$matches->size();

	my $match = $matches->begin();
	for (1 .. $matches->size()) {
	    my $doc = $match->get_document();
	    my $msg_ref = eval $doc->get_data();
	    if ($@) {
		warn $@ if $@;
	    }
	    else {
		push @translated_msgs, $msg_ref;
	    }
	    $match++;
	}
	last if @translated_msgs;
    }
    @translated_msgs
	= (map { $_->[2] }
	   sort { $b->[0] <=> $a->[0] }
	   sort { $a->[1] <=> $b->[1] }
	   map { [ similarity(lc $msg_id, lc _dequote($_->[0])),
		   $self->_token_count_diff($msg_id, _dequote($_->[0])),
		   $_ ] }
	   @translated_msgs);
    return wantarray ? @translated_msgs : $translated_msgs[0];
}

1;
__END__

=pod

=head1 NAME

Locale::Memories - L10N Message Retrieval

=head1 SYNOPSIS

  my $lm = Locale::Memories->new();
  $lm->load_index('path_to_index');
  $lm->index_msg($locale, $msg_id, $msg_str);
  $lm->translate_msg($locale, $msg_id);

=head1 DESCRIPTION

This module is specialized module for indexing and retrieving .po messages.

=head1 COPYRIGHT

Copyright (c) 2007 Yung-chung Lin. All rights reserved. This program is
free software; you can redistribute it and/or modify it under the same
terms as Perl itself.

=cut
