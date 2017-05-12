#!/usr/bin/perl

package Mail::Summary::Tools::Summary::List;
use Moose;

use Mail::Summary::Tools::Summary::Thread;

has name => (
	isa => "Str",
	is  => "rw",
	required => 0,
);

has title => (
	isa  => "Str",
	is   => "rw",
	lazy => 1,
	default => sub { $_[0]->name },
);

has threads => (
	isa => "ArrayRef",
	is  => "rw",
	auto_deref => 1,
	default    => sub { [ ] },
	trigger    => sub { $_[0]->_reindex_message_ids },
);

has extra => (
	isa => "HashRef",
	is  => "rw",
	required => 0,
);

has _message_id_index => (
	isa => "HashRef",
	is  => "rw",
	lazy    => 1,
	default => sub { $_[0]->_reindex_message_ids },
);


sub get_thread_by_id {
	my ( $self, $message_id ) = @_;

	$self->_message_id_index->{$message_id};
}

sub _reindex_message_ids {
	my $self = shift;

	my %index = map { $_->message_id => $_ } $self->threads;

	$self->_message_id_index(\%index);
	
	return \%index;
}

sub add_threads {
	my ( $self, @threads ) = @_;
	@{ $self->_message_id_index }{ map { $_->message_id } @threads } = @threads;
	push @{ $self->threads }, @threads;
}

sub load {
	my ( $class, $hash, %options ) = @_;

	$hash->{threads} = [ map { Mail::Summary::Tools::Summary::Thread->load($_, %options) } @{ $hash->{threads} } ];

	$class->new( %{ $options{list} }, %$hash );
}

sub to_hash {
	my $self = shift;

	return {
		( $self->name  ? ( name  => $self->name ) : () ),,
		( $self->title ? ( title => $self->title ) : () ),
		( $self->extra ? ( extra => $self->extra ) : () ),
		threads => [ map { $_->to_hash } $self->threads ],
	};
}

__PACKAGE__;

__END__

=pod

=head1 NAME

Mail::Summary::Tools::Summary::List - 

=head1 SYNOPSIS

	use Mail::Summary::Tools::Summary::List;

=head1 DESCRIPTION

=cut


